//
//  ThingConfig.swift
//  iot
//
//  Created by Mark Randall on 6/10/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import FirebaseFirestoreSwift

// Represents the current config of a thing
struct ThingConfig: Codable {
    
    @DocumentID var id: String?
    let mode: String
}
