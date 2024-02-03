//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation

public enum DocumentSourceType {
    case files
    case folder
}

protocol DocumentDelegate: AnyObject {
    func didPickDocuments(_ documents: [Document])
}
