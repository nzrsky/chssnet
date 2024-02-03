//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import UIKit

struct Annotation {
    let kind: AnnotationKind
    let rect: CGRect
}

enum AnnotationKind {
    case chessboard
    case goboard
    case unknown
}

extension AnnotationKind {

    init(classId: Int) {
        switch classId {
        case 0: self = .chessboard
        case 1: self = .goboard
        default: self = .unknown
        }
    }

    var borderColor: UIColor {
        switch self {
        case .chessboard:
            return .systemRed
        case .goboard:
            return .systemMint
        case .unknown:
            return .yellow
        }
    }
}
