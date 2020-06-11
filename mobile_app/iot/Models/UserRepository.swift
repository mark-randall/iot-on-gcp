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
    
    func logout() -> Future<Result<Bool, Error>, Never>
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
    
    func logout() -> Future<Result<Bool, Error>, Never> {
        
        Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(.success(true)))
            } catch {
                promise(.success(.failure(error)))
            }
        }
    }
}
