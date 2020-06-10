//
//  QuerySnapshot+Debug.swift
//
//  Created by Mark Randall on 12/24/19.
//  Copyright © 2019 Mark Randall. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension QuerySnapshot {
    
    override open var debugDescription: String {
        let added = documentChanges.filter { $0.type == DocumentChangeType.added }.count
        let removed = documentChanges.filter { $0.type == DocumentChangeType.removed }.count
        let modified = documentChanges.filter { $0.type == DocumentChangeType.modified }.count
        return "total \(documents.count). Updates: \(added) added, \(removed) removed, \(modified) modified"
    }
}
