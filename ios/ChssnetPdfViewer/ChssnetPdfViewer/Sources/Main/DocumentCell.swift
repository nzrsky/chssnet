//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import UIKit
import Reusable

class DocumentCell: UICollectionViewCell, Reusable {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        self.layer.cornerRadius = 4
        titleLabel.adjustsFontSizeToFitWidth = true
    }
    
    func configure(with document: Document) {
        titleLabel.text = document.fileURL.deletingPathExtension().lastPathComponent

        setGradientBackgroundColor(
            colorOne: Colors().randomColors.first!,
            colorTwo: Colors().randomColors.last!
        )
    }
}

extension DocumentCell {
    static func size(forWidth width: CGFloat) -> CGSize {
        .init(width: width, height: width * 9.0 / 6.0).integral
    }
}
