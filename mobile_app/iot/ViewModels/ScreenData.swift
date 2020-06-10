//
//  ScreenData.swift
//  iot
//
//  Created by Mark Randall on 6/9/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Foundation

enum ScreenData: Identifiable {
    
    /// Firebase Auth UI screen
    /// Currently a ViewModel is not required for this screen
    case auth
    
    case editAttribute(StatusViewModelData.StatusAttributeData, [String])
    
    var id: String { "\(self)" }
}
