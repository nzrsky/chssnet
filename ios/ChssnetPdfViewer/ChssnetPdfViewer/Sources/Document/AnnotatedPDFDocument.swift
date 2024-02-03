//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import PDFKit
import Vision
import CoreMedia

class AnnotatedPDFDocument: PDFDocument {

    private let queue = DispatchQueue(label: "detection", qos: .background, attributes: [.concurrent])
    private var pagesInQueue: Set<PDFPage> = []

    private var annotationsCache: [PDFPage: [Annotation]] = [:]
    private let maximumObservations = 10

    private(set) var detectionTimings: [Int: CFTimeInterval] = [:]
    private let classificationModel: VNCoreMLModel

    override init?(url: URL) {
        do {
            classificationModel = try VNCoreMLModel(for: try Chssnetv1Int8(configuration: .init()).model)
        } catch {
            fatalError("Error loading model: \(error)")
        }

        super.init(url: url)
    }

    func cachedAnnotations(for page: PDFPage) -> [Annotation]? {
        return annotationsCache[page]
    }

    func detectAnnotationsOnQueue(for page: PDFPage, completion: @escaping ([Annotation]) -> Void) {
        if pagesInQueue.contains(page) { return }

        pagesInQueue.insert(page)
        queue.async { [weak self] in
            guard let self else { return }

            let pageIndex = index(for: page)
            
            let startTime = CACurrentMediaTime()
            self.detectAnnotations(for: page) { [weak self] annotations in
                self?.completeDetection(
                    annotations: annotations,
                    page: page,
                    pageIndex: pageIndex,
                    startTime: startTime,
                    completion: completion
                )
            }
        }
    }

    private func completeDetection(
        annotations: [Annotation],
        page: PDFPage,
        pageIndex: Int,
        startTime: CFTimeInterval,
        completion: @escaping ([Annotation]) -> Void
    ) {
        let detectionTime = CACurrentMediaTime() - startTime

        DispatchQueue.main.async {
            self.detectionTimings[pageIndex] = detectionTime * 1_000
            self.annotationsCache[page] = annotations
            completion(annotations)
            self.pagesInQueue.remove(page)
        }
    }

    struct Prediction {
        let `class`: Int
        let confidencePercentage: String
    }

    func classifyImage(_ croppedImage: CGImage, completion: @escaping (AnnotationKind, Float) -> Void) {
        let request = VNCoreMLRequest(model: classificationModel) { request, error in
            if let firstResult = request.results?.first as? VNCoreMLFeatureValueObservation,
               let tensor = firstResult.featureValue.multiArrayValue {

                var maxIndex = 0
                var maxValue: Float = tensor[0].floatValue

                for i in 1 ..< tensor.count {
                    let value = tensor[i].floatValue
                    
                    if value > maxValue {
                        maxValue = value
                        maxIndex = i
                    }
                }

                completion(.init(classId: maxIndex), maxValue)
            } else {
                if let error { print(error) }
                print("Could not find results or cast to VNCoreMLFeatureValueObservation correctly.")

                completion(.unknown, 0)
            }
        }

        request.imageCropAndScaleOption = .scaleFit

        do {
            let handler = VNImageRequestHandler(cgImage: croppedImage, options: [:])
            try handler.perform([request])
        } catch {
            print("Failed to perform classification.\n\(error.localizedDescription)")
            completion(.unknown, 0)
        }
    }

    private func detectAnnotations(for page: PDFPage, completion: @escaping ([Annotation]) -> Void) {
        let pageSize = page.bounds(for: .mediaBox).size
        let thumbFitSize: CGSize = .init(width: 224 * 2, height: 224 * 9 / 6 * 2)

        guard let thumbImage = page.thumbnail(of: thumbFitSize, for: .artBox).cgImage else {
            completion([])
            return
        }

        let detectRequest = VNDetectRectanglesRequest()
        detectRequest.maximumObservations = maximumObservations
        detectRequest.minimumSize = 0.2
        detectRequest.minimumAspectRatio = 0.5
        detectRequest.maximumAspectRatio = 1
        detectRequest.minimumConfidence = 0.6

        let detectHandler = VNImageRequestHandler(cgImage: thumbImage, options: [:])
        do {
            try detectHandler.perform([detectRequest])
            guard let rects = detectRequest.results, !rects.isEmpty else {
                completion([])
                return
            }

            let dispatchGroup = DispatchGroup()
            var annotations: [Annotation] = []

            let largerThumbFitSize = thumbFitSize.applying(.init(scaleX: 2, y: 2))
            let largerThumb = page.thumbnail(of: largerThumbFitSize, for: .artBox)
            guard let largerImage = largerThumb.cgImage else {
                completion([])
                return
            }

            for rect in rects {
                let cropRect = rect.convertToPageRect(pageSize: largerThumb.size)
                guard let croppedImage = largerImage.cropping(to: cropRect) else {
                    continue
                }

                dispatchGroup.enter()
                classifyImage(croppedImage) { annotation, conf in
                    print("\(annotation) p=\(conf)")

                    let pageRect = rect.convertToPageRect(pageSize: pageSize)
                    annotations.append(.init(kind: annotation, rect: pageRect))
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .global(qos: .background)) {
                completion(annotations)
            }
        } catch {
            print(error)
            completion([])
        }
    }
}

extension VNRectangleObservation {
    func convertToPageRect(pageSize: CGSize) -> CGRect {
        let x = boundingBox.origin.x * pageSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * pageSize.height
        let width = boundingBox.size.width * pageSize.width
        let height = boundingBox.size.height * pageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

extension PDFDocument {
    func title() -> String? {
        documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
    }

    func titleOrPath(from fileURL: URL) -> String {
        title() ?? fileURL.deletingPathExtension().lastPathComponent
    }
}


// 107: ch ?
// 101: go x
