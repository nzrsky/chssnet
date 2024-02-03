//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import UIKit
import Reusable

class DocumentsListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private lazy var documentPicker: DocumentPicker = {
        DocumentPicker(presentationController: self, delegate: self)
    }()

    private var documents: [Document] = []
    private var documentsURLs: Set<URL> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupContent()
        loadBundledDocuments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateColletionLayout()
    }

    @IBAction func pickPressed(_ sender: Any) {
        documentPicker.present(from: view)
    }
}

private extension DocumentsListViewController {
    func setupContent() {
        view.backgroundColor = .systemGroupedBackground
        navigationController?.view.backgroundColor = .systemGroupedBackground
    }

    func updateColletionLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let itemsPerRow: CGFloat = 5
        let spacing = layout.minimumInteritemSpacing

        let containerWidth = view.bounds.width - layout.sectionInset.left - layout.sectionInset.right
        let itemWidth = (containerWidth - spacing * (itemsPerRow - 1)) / itemsPerRow

        layout.itemSize = DocumentCell.size(forWidth: itemWidth)
    }

    func loadBundledDocuments() {
        DispatchQueue.global(qos: .background).async {
            let bundledDocuments = Bundle.main.documentsPaths(ofType: .pdf).map {
                Document(fileURL: URL(fileURLWithPath: $0))
            }

            DispatchQueue.main.async {
                self.didPickDocuments(bundledDocuments)
            }
        }
    }

    func openViewer(for document: Document) {
        let viewer = DocumentViewerViewController(fileURL: document.fileURL)
        navigationController?.pushViewController(viewer, animated: true)
    }
}

extension DocumentsListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        documents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let doc = documents[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(for: indexPath) as DocumentCell
        cell.configure(with: doc)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let doc = documents[indexPath.row]

        openViewer(for: doc)
    }
}

extension DocumentsListViewController: DocumentDelegate {
    func didPickDocuments(_ docs: [Document]) {
        let docs = docs.filter { !documentsURLs.contains($0.fileURL) }
        guard !docs.isEmpty else { return }

        documents.append(contentsOf: docs)
        documentsURLs.formUnion(Set(docs.map(\.fileURL)))

        collectionView.reloadData()
    }
}
