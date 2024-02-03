//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class PageNumberView: UIView {
    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.systemGroupedBackground.withAlphaComponent(0.5)
        layer.cornerRadius = 8

        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(10)
            make.width.greaterThanOrEqualTo(14)
            make.centerY.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private var pageNumber = 0

    func set(_ number: Int, of pagesCount: Int) {
        if pageNumber != number {
            label.text = "\(number) / \(pagesCount)"
            pageNumber = number
        }
    }
}
