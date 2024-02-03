//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import UIKit

class Document: UIDocument {
    var data: Data?
    
    override func contents(forType typeName: String) throws -> Any {
        guard let data = data else { return Data() }
        return try NSKeyedArchiver.archivedData(
            withRootObject: data,
            requiringSecureCoding: true
        )
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else { return }
        self.data = data
    }
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }
}
