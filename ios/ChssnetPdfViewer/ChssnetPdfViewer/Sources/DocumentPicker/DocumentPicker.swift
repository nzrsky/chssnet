//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

open class DocumentPicker: NSObject {

    private var pickerController: UIDocumentPickerViewController?
    private let coordinator = NSFileCoordinator()

    private weak var presentationController: UIViewController?
    private weak var delegate: DocumentDelegate?

    private var sourceType: DocumentSourceType = .files
    private var folderURL: URL?

    private var documents: [Document] = []

    init(presentationController: UIViewController, delegate: DocumentDelegate) {
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
    }

    private func presentDocumentPicker(sourceType: DocumentSourceType) {
        self.sourceType = sourceType

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: sourceType == .folder ? [.folder] : [.pdf]
        )

        picker.allowsMultipleSelection = sourceType == .files
        picker.delegate = self
        pickerController = picker

        presentationController?.present(picker, animated: true)
    }

    public func present(from sourceView: UIView) {
        let alert = UIAlertController(title: "Open document from", message: nil, preferredStyle: .actionSheet)

        let actions = [
            UIAlertAction(title: "Files", style: .default) { [weak self] _ in
                self?.presentDocumentPicker(sourceType: .files)
            },

            UIAlertAction(title: "Folder", style: .default) { [weak self] _ in
                self?.presentDocumentPicker(sourceType: .folder)
            },

            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ]
        
        for action in actions.compactMap({ $0 }) {
            alert.addAction(action)
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            let popover = alert.popoverPresentationController
            
            popover?.sourceView = sourceView
            popover?.sourceRect = sourceView.bounds
            popover?.permittedArrowDirections = [.down, .up]
        }
        
        presentationController?.present(alert, animated: true)
    }
}

extension DocumentPicker: UIDocumentPickerDelegate {

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        collectDocuments(at: url)
        delegate?.didPickDocuments(documents)
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.didPickDocuments([])
    }

    private func collectDocuments(at url: URL) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        coordinator.coordinate(readingItemAt: url, error: NSErrorPointer.none) { folderURL in
            switch sourceType {
            case .files:
                let document = Document(fileURL: url)
                documents.append(document)

            case .folder:
                guard let filesEnumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.nameKey, .isDirectoryKey]
                ) else { return }

                for case let fileURL as URL in filesEnumerator where !fileURL.isDirectory {
                    let document = Document(fileURL: fileURL)
                    documents.append(document)
                }
            }
        }
    }
}

extension DocumentPicker: UINavigationControllerDelegate {}
