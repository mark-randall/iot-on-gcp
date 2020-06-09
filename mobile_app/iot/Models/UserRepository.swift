//
//  UserRepository.swift
//  iot
//
//  Created by Mark Randall on 6/9/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Combine
import FirebaseAuth

enum AuthState {
    case unknown
    case authenticated
    case unauthenticated
}

protocol UserRepository {
    
    func fetchAuthState() -> AnyPublisher<AuthState, Never>
}

final class FirebaseUserRepository: UserRepository {

    @Published private var authState: AuthState = .unknown
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.authState = (user != nil) ? .authenticated : .unauthenticated
        }
    }
    
    func fetchAuthState() -> AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
}
