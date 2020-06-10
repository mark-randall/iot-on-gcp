//
//  AlertData.swift
//  iot
//
//  Created by Mark Randall on 6/10/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Foundation

struct AlertData: Identifiable {
    
    let id = UUID()
    var title: String?
    let message: String
    let dismissButtonLabel = "OK"
    
    init(error: Error) {
        title = "Error"
        message = (error as NSError).localizedDescription
    }
    
    init(success: String) {
        message = success
    }
}
