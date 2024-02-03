//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import UIKit

class AnnotationOverlayView: UIControl {
    private let borderWidthNormal: CGFloat
    private let borderWidthSelected: CGFloat
    private let borderColor: UIColor

    init(frame: CGRect, borderColor: UIColor, borderWidthNormal: CGFloat = 1, borderWidthTapped: CGFloat = 5) {
        self.borderWidthNormal = borderWidthNormal
        self.borderWidthSelected = borderWidthTapped
        self.borderColor = borderColor
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let color = borderColor.withAlphaComponent(0.8)
        backgroundColor = .clear

        layer.borderColor = color.cgColor
        layer.borderWidth = borderWidthNormal
        layer.cornerRadius = 4

        isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.isSelected.toggle()
        }
    }

    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? borderWidthSelected : borderWidthNormal
        }
    }
}

final class ChessboardOverlayView: AnnotationOverlayView {
}

class CompoundAnnotationOverlayView: UIView {

    private var overlays: [AnnotationOverlayView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            overlays.forEach { addSubview($0) }
        }
    }

    var annotations: [Annotation] = [] {
        didSet {
            overlays = annotations.map { .init(frame: $0.rect.integral, borderColor: $0.kind.borderColor) }
            isHidden = annotations.isEmpty
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        //backgroundColor = Colors().randomColors.first?.withAlphaComponent(0.1)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let overlay = overlays.first(where: { $0.frame.contains(point) })
        return overlay ?? super.hitTest(point, with: event)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.isUserInteractionEnabled = true
    }
}
