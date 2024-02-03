//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation

public enum DocumentType: String {
    case pdf
}

extension Bundle {
    public func documentsPaths(ofType type: DocumentType) -> [String] {
        Bundle.main.paths(forResourcesOfType: type.rawValue, inDirectory: nil)
    }
}
