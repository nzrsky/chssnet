//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import UIKit
import PDFKit

class AnnotatedPDFView: PDFView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var originalScrollViewDelegate: UIScrollViewDelegate?

    var scrollViewDelegate: UIScrollViewDelegate?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        DispatchQueue.main.async {
            if self.originalScrollViewDelegate == nil {
                let scroll = self.detectScrollView()
                self.originalScrollViewDelegate = scroll?.delegate
                scroll?.delegate = self
            }
        }
    }
}

extension AnnotatedPDFView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewDidScroll?(scrollView)
        scrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewDidZoom?(scrollView)
        scrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        originalScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        scrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        originalScrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        scrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
        scrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
        scrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
        scrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        originalScrollViewDelegate?.viewForZooming?(in: scrollView)
        // scrollViewDelegate?.viewForZooming?(in: scrollView)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        originalScrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
        scrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        originalScrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
        scrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        originalScrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
        // return scrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
        scrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        originalScrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
        scrollViewDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}

extension PDFView {
    func detectScrollView() -> UIScrollView? {
        for view in subviews {
            if let scroll = view as? UIScrollView {
                return scroll
            } else {
                for subview in view.subviews {
                    if let scroll = subview as? UIScrollView {
                        return scroll
                    }
                }
            }
        }

        print("Unable to find a scrollView subview on a PDFView.")
        return nil
    }
}
