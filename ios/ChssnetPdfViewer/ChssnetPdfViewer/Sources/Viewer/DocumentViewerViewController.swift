//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import UIKit
import PDFKit
import SnapKit
import Vision

class DocumentViewerViewController: UIViewController {

    private lazy var coordinator: AnnotatedPDFDocumentCoordinator? = {
        AnnotatedPDFDocument(url: fileURL).flatMap {
            .init(document: $0)
        }
    }()

    private lazy var pdfView: AnnotatedPDFView = {
        let pdfView = AnnotatedPDFView(frame: view.bounds)
        pdfView.backgroundColor = .lightGray
        pdfView.delegate = self
        pdfView.autoScales = true
        pdfView.minScaleFactor = 0.4
        pdfView.enableDataDetectors = true
        
        if #available(iOS 16.0, *) {
            pdfView.isFindInteractionEnabled = true
        }
        view.addSubview(pdfView)
        pdfView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        return pdfView
    }()

    private let pageNumberView = PageNumberView()

    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)

        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContent()
        createDocumentView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

private extension DocumentViewerViewController {
    func setupContent() {
        view.backgroundColor = .lightGray

        pdfView.scrollViewDelegate = self

        pageNumberView.alpha = 0
        view.addSubview(pageNumberView)
        pageNumberView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(16)
            make.height.equalTo(24)
        }

        navigationItem.rightBarButtonItem = .init(
            image: .init(systemName: "chart.xyaxis.line"),
            style: .plain,
            target: self,
            action: #selector(openCharts)
        )
    }

    @objc func openCharts() {
        let data = coordinator?.document.detectionTimings ?? [:]
        let vc = ChartsViewController(data: data)
        navigationController?.pushViewController(vc, animated: true)
    }

    func createDocumentView() {
        navigationItem.title = coordinator?.document.titleOrPath(from: fileURL)

        if #available(iOS 16.0, *) {
            pdfView.pageOverlayViewProvider = coordinator
        }

        pdfView.document = coordinator?.document

        DispatchQueue.main.async {
           self.pdfView.layoutIfNeeded()
           self.pdfView.autoScales = true
       }
    }
}

extension DocumentViewerViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        showPageNumber()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        hidePageNumberAnimated()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        hidePageNumberAnimated()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let currentPage = pdfView.currentPage, let pageIndex = pdfView.document?.index(for: currentPage) {
            pageNumberView.set(pageIndex + 1, of: pdfView.document?.pageCount ?? 1)
        }
    }

    private func showPageNumber() {
        pageNumberView.alpha = 1
    }

    @objc private func hidePageNumberAnimated() {
        UIView.animate(withDuration: 0.4, delay: 1, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.pageNumberView.alpha = 0
        }
    }
}

extension DocumentViewerViewController: PDFViewDelegate {
}

private class AnnotatedPDFDocumentCoordinator: NSObject, PDFPageOverlayViewProvider, PDFDocumentDelegate {

    let document: AnnotatedPDFDocument
    private var overlays: [PDFPage: UIView?] = [:]

    init(document: AnnotatedPDFDocument) {
        self.document = document
        super.init()
        document.delegate = self
    }

    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        if let existingOverlay = overlays[page] {
            // print("-> existing overlay")
            return existingOverlay
        }

        let annotations = document.cachedAnnotations(for: page)
        if annotations?.isEmpty == true { return nil }

        let overlay = CompoundAnnotationOverlayView(frame: page.bounds(for: .mediaBox))
        overlay.annotations = annotations ?? []
        overlays[page] = overlay

        if annotations != nil {
            // print("-> create from cache")
        } else {
            // print("-> create async")

            document.detectAnnotationsOnQueue(for: page) { annotations in
                guard !annotations.isEmpty else { return }
                    // print("-> update async")
                overlay.annotations = annotations
            }
        }

        return overlay
    }

    func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) {
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        overlays.removeValue(forKey: page)
    }
}
