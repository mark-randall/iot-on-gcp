//
//  ThingSchedule.swift
//  iot
//
//  Created by Mark Randall on 6/12/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Firebase
import FirebaseFirestoreSwift

// Represents the a schedule run command
struct ThingSchedule: Codable {
    
    @DocumentID var id: String?
    let time: Date
}
