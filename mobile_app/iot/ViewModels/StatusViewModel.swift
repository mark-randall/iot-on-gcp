//
//  StatusViewModel.swift
//  iot
//
//  Created by Mark Randall on 6/8/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - ViewModel State Data Types

struct StatusAttributeData: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

struct StatusRunningStatusData {
    let label: String
    var isEnabled: Bool = false
}

struct StatusViewModelData {
    let title = "IoT"
    var runningStatus: StatusRunningStatusData
    var attributes: [StatusAttributeData] = []
}

// MARK: - ViewModel ViewEvents

enum StatusViewEvent {
    case onAppear
    case runningStatusButtonTapped
}

enum Navigation: String, Identifiable {
    case auth
    var id: String { self.rawValue }
}

// MARK: - ViewModel

protocol StatusViewModelProtocol: ObservableObject {
    
    var state: StatusViewModelData? { get }
    
    func apply(_ eventEvent: StatusViewEvent)
}

final class StatusViewModel: StatusViewModelProtocol {

    // MARK: - Dependencies
    
    private let thingRepository: ThingRepository
    private let userRepository: UserRepository
    
    // MARK: - State
    
    @Published private(set) var state: StatusViewModelData? = nil
    @Published var sheetNavigation: Navigation? = nil
    
    // MARK: - Private state
    
    @Published private var viewAppeared = false
    private var subscriptions: [AnyCancellable] = []
    
    // MARK: - Init
    
    init(
        thingRepository: ThingRepository = FirebaseThingRepository(),
        userRepository: UserRepository = FirebaseUserRepository()
    ) {
        self.thingRepository = thingRepository
        self.userRepository = userRepository
        
        bind(
            userRepository: userRepository,
            thingRepository: thingRepository,
            subscriptions: &subscriptions
        )
    }
    
    private func bind(userRepository: UserRepository, thingRepository: ThingRepository, subscriptions: inout [AnyCancellable]) {
        
        // 1. Validate $viewAppeared
        // 2. Fetch auth state
        // 3. If auth state is not authenticated present auth sheet
        let userRepoSubscription = Publishers.CombineLatest(
            userRepository.fetchAuthState(),
            $viewAppeared.filter({ $0 }).first()
        ).sink { [weak self] authState, _ in
            if case .unauthenticated = authState {
                self?.sheetNavigation = .auth
            }
        }
        
        subscriptions.append(userRepoSubscription)
        
        // 1. Validate user is authenticated
        // 2. Fetch state for thing with id
        // 3. Map model state to viewModel state
        // 4. Assign to .state property
        let thingRepoSubscription = userRepository.fetchAuthState()
        .filter { $0 == .authenticated }.first()
        .flatMap { _ in thingRepository.fetchThing(forId: "test") }
        .map { result in
            
            switch result {
            case .failure(let error):
                return StatusViewModelData(
                   runningStatus: StatusRunningStatusData(label: "Error"),
                   attributes: [
                        StatusAttributeData(label: "Error:", value: (error as NSError).localizedDescription),
                   ]
               )
            case .success(let thing):
                return StatusViewModelData(
                    runningStatus: StatusRunningStatusData(label: (thing.state.running) ? "Stop" : "Start"),
                    attributes: [
                        StatusAttributeData(label: "Mode:", value: thing.state.mode),
                        StatusAttributeData(label: "Battery:", value: "\(thing.state.battery)")
                    ]
                )
            }
        }
        .eraseToAnyPublisher()
        .assign(to: \.state, on: self)
        
        subscriptions.append(thingRepoSubscription)
    }
    
    private func bind(_ userRepository: UserRepository, subscriptions: inout [AnyCancellable]) {
        
        
    }
    
    // MARK: - Handle view events
    
    func apply(_ eventEvent: StatusViewEvent) {
        
        switch eventEvent {
        case .onAppear:
            viewAppeared = true
        case .runningStatusButtonTapped:
            break;
        }
    }
}
