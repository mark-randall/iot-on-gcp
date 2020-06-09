//
//  Thing.swift
//  iot
//
//  Created by Mark Randall on 6/8/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Foundation
import FirebaseFirestoreSwift

struct Thing: Codable {
    
    struct State: Codable {
        
        let docking: Bool
        let charging: Bool
        let running: Bool
        let battery: Double
        let mode: String
        let firmwareVersion: String
        
        enum CodingKeys: String, CodingKey {
            case docking
            case charging
            case running
            case battery
            case mode
            case firmwareVersion = "firmware_version"
        }
    }
    
    @DocumentID var id: String?
    let state: State
}

