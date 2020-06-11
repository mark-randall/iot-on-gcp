//
//  AuthView.swift
//  iot
//
//  Created by Mark Randall on 6/9/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI
import FirebaseUI

struct AuthView: UIViewControllerRepresentable {
    
    private var authUI: FUIAuth?
    
    init() {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.providers = [
            FUIEmailAuth()
        ]
        self.authUI = authUI
    }
    
    // MARK: - UIViewControllerRepresentable
   
    func makeUIViewController(context: Context) -> UINavigationController {
        guard let authViewController = authUI?.authViewController() else { preconditionFailure() }
        return authViewController
    }
   
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
}
