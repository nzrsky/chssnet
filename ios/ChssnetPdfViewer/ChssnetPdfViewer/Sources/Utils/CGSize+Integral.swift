//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation

extension CGSize {
    public var integral: CGSize {
        .init(width: round(width), height: round(height))
    }
}
