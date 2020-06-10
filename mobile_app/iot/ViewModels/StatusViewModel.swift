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

// State of ViewModel
struct StatusViewModelData {
    
    struct StatusAttributeData: Identifiable {
        let id: String
        var label: String { "\(id.capitalized):" }
        let value: String
        var isEditable: Bool = false
    }

    struct ActionButtonStatusData {
        
        enum Action: Equatable {
            case start
            case stop
            case error(NSError)
        }
        
        var action: Action
        
        var label: String {
            switch action {
            case .start: return "start"
            case .stop: return "stop"
            case .error: return "Error"
            }
        }
        
        var isEnabled: Bool {
            switch action {
            case .start: return true
            case .stop: return true
            case .error: return false
            }
        }
    }
    
    var actionButtonStatus: ActionButtonStatusData
    var attributes: [StatusAttributeData] = []
}

// MARK: - ViewModel ViewEvents

// Events which can be applied to ViewModel
enum StatusViewEvent {
    case onAppear
    case actionButtonTapped
    case attributedEditTapped(StatusViewModelData.StatusAttributeData)
    case attributeUpdated(StatusViewModelData.StatusAttributeData, newValue: String)
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
    
    let title = "IoT"
    @Published private(set) var state: StatusViewModelData? = nil
    
    @Published var sheetNavigation: ScreenData? = nil
    @Published var alert: AlertData? = nil
    @Published var isLoading: Bool = true
    
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
        .flatMap { _ in thingRepository.fetch(forId: "test") }
        .map { result in
            
            switch result {
            case .failure(let error):
                return StatusViewModelData(
                    actionButtonStatus: StatusViewModelData.ActionButtonStatusData(action: .error(error as NSError)),
                    attributes: [
                        StatusViewModelData.StatusAttributeData(id: "error", value: (error as NSError).localizedDescription),
                    ]
               )
            case .success(let thing):
                return StatusViewModelData(
                    actionButtonStatus: StatusViewModelData.ActionButtonStatusData(action: (thing.state.running) ? .stop : .start),
                    attributes: [
                        StatusViewModelData.StatusAttributeData(id: "mode", value: thing.state.mode, isEditable: true),
                        StatusViewModelData.StatusAttributeData(id: "battery", value: "\(thing.state.battery)")
                    ]
                )
            }
        }
        .handleEvents(receiveOutput: { [weak self] _ in
            self?.isLoading = false
        })
        .eraseToAnyPublisher()
        .assign(to: \.state, on: self)
        
        subscriptions.append(thingRepoSubscription)
    }
    
    // MARK: - Handle view events
    
    func apply(_ eventEvent: StatusViewEvent) {
        
        switch eventEvent {
            
        case .onAppear:
            viewAppeared = true
        
        case .actionButtonTapped:
            
            // Validate internal state
            guard let actionStatus = state?.actionButtonStatus else { assertionFailure(); return }
            assert(actionStatus.isEnabled)
            
            // Map actionStatus.action to ThingCommand
            let repositoryAction: ThingCommand?
            switch actionStatus.action {
            case .start: repositoryAction = .start
            case .stop: repositoryAction = .stop
            default: repositoryAction = nil
            }
            guard let thingAction = repositoryAction else { assertionFailure(); return }
            
            isLoading = true
            let request = thingRepository.sendCommand(forId: "test", command: thingAction).sink(receiveValue: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .failure(let error):
                    self?.alert = AlertData(error: error)
                case .success:
                    self?.alert = AlertData(success: "Command sent")
                }
            })
            subscriptions.append(request)
            
        case .attributedEditTapped(let attribute):
            sheetNavigation = .editAttribute(attribute, ["1", "2", "3"]) // TODO: pull real values
            
        case .attributeUpdated(let attribute, let newValue):
            
            sheetNavigation = nil
            
            guard attribute.id == "mode" else { assertionFailure(); return }
            
            isLoading = true
            let update = thingRepository.updateMode(forId: "test", mode: newValue).sink(receiveValue: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .failure(let error):
                    self?.alert = AlertData(error: error)
                case .success:
                    self?.alert = AlertData(success: "Config update sents")
                }
            })
            subscriptions.append(update)
        }
    }
}
