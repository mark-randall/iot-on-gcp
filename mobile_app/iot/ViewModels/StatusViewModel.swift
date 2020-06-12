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
        var localUpdatePending: Bool = false
    }

    struct ActionButtonStatusData {
        
        enum Action: Equatable {
            case loading
            case start
            case stop
            case error(NSError)
        }
        
        var action: Action
        
        var label: String {
            switch action {
            case .loading: return "Loading"
            case .start: return "start"
            case .stop: return "stop"
            case .error: return "Error"
            }
        }
        
        var isEnabled: Bool {
            switch action {
            case .loading: return false
            case .start: return true
            case .stop: return true
            case .error: return false
            }
        }
    }
    
    struct ScheduledRunTimesData: Identifiable {
        var id: String { time }
        let time: String
    }
    
    enum NavBarItem: Identifiable {
        case signIn
        case signOut
        
        var id: String { label }
        
        var label: String {
            switch self {
            case .signIn: return "Sign in"
            case .signOut: return "Sign out"
            }
        }
    }
    
    var actionButtonStatus: ActionButtonStatusData = ActionButtonStatusData(action: .loading)
    var attributes: [StatusAttributeData] = []
    var scheduledRunTimes: [ScheduledRunTimesData] = []
    var leftBarButtonItems: [NavBarItem] = []
    
}

// MARK: - ViewModel ViewEvents

// Events which can be applied to ViewModel
enum StatusViewEvent: AnalyticsEvent {
    case onAppear
    case actionButtonTapped(StatusViewModelData.ActionButtonStatusData)
    case attributedEditTapped(StatusViewModelData.StatusAttributeData)
    case attributeUpdated(StatusViewModelData.StatusAttributeData, newValue: String)
    case navBarItemTapped(StatusViewModelData.NavBarItem)
    case addScheduledRunTimeButtonTapped
    case scheduleRunTimeSelected(Date)
    case dismissSheet
    
    // MARK: - AnalyticEvent
    
    var name: String {
        
        switch self {
        case .actionButtonTapped(let status):
            return "\(status.label)".components(separatedBy: "(").first ?? "invalid"
        case .navBarItemTapped(let item):
            return "\(item)".components(separatedBy: "(").first ?? "invalid"
        default:
            return "\(self)".components(separatedBy: "(").first ?? "invalid"
        }
    }
    
    var parameters: [String : Any]? {
        
        switch self {
        case .attributedEditTapped(let item):
            return [
                "label": item.label
            ]
        case .attributeUpdated(let item, let newValue):
            return [
                "label": item.label,
                "value_old": item.value,
                "value_new": newValue
            ]
        default:
            return nil
        }
    }
}

// MARK: - ViewModel

final class StatusViewModel: ObservableObject {

    // MARK: - Dependencies
    
    private let thingRepository: ThingRepository
    private let userRepository: UserRepository
    private let analyticsManager: AnalyticsManager
    
    // MARK: - State
    
    let title = "IoT"
    @Published private(set) var state = StatusViewModelData()
    
    @Published var sheetNavigation: ScreenData? = nil
    @Published var alert: AlertData? = nil
    @Published var isLoading: Bool = false
    
    // MARK: - Private state
    
    let deviceId: String
    
    @Published private var viewAppeared = false
    private var subscriptions: [AnyCancellable] = []
    
    // MARK: - Init
    
    init(
        deviceId: String = "test",
        thingRepository: ThingRepository = FirebaseThingRepository(),
        userRepository: UserRepository = FirebaseUserRepository(),
        analyticsManager: AnalyticsManager = FirebaseAnalyticsManager()
    ) {
        self.deviceId = deviceId
        self.thingRepository = thingRepository
        self.userRepository = userRepository
        self.analyticsManager = analyticsManager
        
        bind(
            userRepository: userRepository,
            thingRepository: thingRepository,
            subscriptions: &subscriptions
        )
    }
    
    // MARK: - Bind to model
    
    private func bind(userRepository: UserRepository, thingRepository: ThingRepository, subscriptions: inout [AnyCancellable]) {
        
        let deviceId = self.deviceId
        
        // 1. Validate $viewAppeared
        // 2. Fetch auth state
        // 3. If auth state is not authenticated present auth sheet
        let userRepoSubscription = Publishers.CombineLatest(
            userRepository.fetchAuthState(),
            $viewAppeared.filter({ $0 }).first()
        ).sink { [weak self] authState, _ in
            
            if case .unauthenticated = authState {
                self?.sheetNavigation = .auth
                self?.state.leftBarButtonItems = [.signIn]
            } else {
                self?.state.leftBarButtonItems = [.signOut]
            }
            
            self?.analyticsManager.setUserProperty(UserProperty.authState(authState))
        }
        
        subscriptions.append(userRepoSubscription)
        
        // 1. Validate user is authenticated
        // 2. Fetch state for thing with id
        // 2a. Fetch device config
        // 2b. Fetch device schedule
        // 3. Map models state to viewModel state
        // 4. Assign to .state property
        let thingRepoSubscription = userRepository.fetchAuthState()
        .filter { $0 == .authenticated }.first()
        .flatMap { _ in
            thingRepository.fetch(forId: deviceId)
            .combineLatest(
                thingRepository.fetchConfig(forId: deviceId),
                thingRepository.fetchSchedule(forId: deviceId)
            )
        }
        .map { [weak self] results in
            
            let result = results.0
            let configResult = results.1
            let scheduleResult = results.2

            switch result {
            case .failure(let error):
                
                return StatusViewModelData(
                    actionButtonStatus: StatusViewModelData.ActionButtonStatusData(action: .error(error as NSError)),
                    attributes: [
                        StatusViewModelData.StatusAttributeData(id: "error", value: (error as NSError).localizedDescription),
                    ],
                    leftBarButtonItems: self?.state.leftBarButtonItems ?? []
                )
                // TODO: handle re fetching when user signsout. This causes Firestore subscription to error out
                
            case .success(let thing):
                
                // Map models to state
                return StatusViewModelData(
                    actionButtonStatus: StatusViewModelData.ActionButtonStatusData(action: (thing.state.running) ? .stop : .start),
                    attributes: [
                        StatusViewModelData.StatusAttributeData(
                            id: "mode",
                            value: (try? configResult.get().mode) ?? thing.state.mode,
                            isEditable: true,
                            localUpdatePending: thing.state.mode != ((try? configResult.get().mode) ?? thing.state.mode)
                        ),
                        StatusViewModelData.StatusAttributeData(
                            id: "battery",
                            value: "\(thing.state.battery)"
                        )
                    ],
                    scheduledRunTimes: (((try? scheduleResult.get()) ?? [ThingSchedule]()).map { scheduled in
                        StatusViewModelData.ScheduledRunTimesData(time: "\(scheduled.time)")
                    }),
                    leftBarButtonItems: [.signOut]
                )
            }
        }
        .handleEvents(receiveOutput: { [weak self] _ in
            self?.isLoading = false
        })
        .eraseToAnyPublisher()
        .assign(to: \.state, on: self)
        
        subscriptions.append(thingRepoSubscription)
        
        let errorPresentation = $alert.filter { $0 != nil }.sink(receiveValue: { [weak self] in
            self?.analyticsManager.logEvent($0!)
        })
        
        subscriptions.append(errorPresentation)
    }
    
    // MARK: - Handle view events
    
    func apply(_ eventEvent: StatusViewEvent) {
        
        if case .onAppear = eventEvent { analyticsManager.setScreeName(.statusView) }
        analyticsManager.logEvent(eventEvent)
        
        switch eventEvent {
            
        case .onAppear:
            viewAppeared = true
        
        case .actionButtonTapped:
            
            // Validate internal state
            assert(state.actionButtonStatus.isEnabled)
            
            // Map actionStatus.action to ThingCommand
            let repositoryAction: ThingCommand?
            switch state.actionButtonStatus.action {
            case .start: repositoryAction = .start
            case .stop: repositoryAction = .stop
            default: repositoryAction = nil
            }
            guard let thingAction = repositoryAction else { assertionFailure(); return }
            
            isLoading = true
            let request = thingRepository.sendCommand(forId: deviceId, command: thingAction).sink(receiveValue: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .failure(let error):
                    self?.alert = AlertData(error: error)
                case .success: break
                }
            })
            subscriptions.append(request)
            
        case .attributedEditTapped(let attribute):
            sheetNavigation = .editAttribute(attribute, ["1", "2", "3"]) // TODO: pull real values
            
        case .attributeUpdated(let attribute, let newValue):
            
            sheetNavigation = nil
            guard attribute.id == "mode" else { assertionFailure(); return }
            
            isLoading = true
            let update = thingRepository.updateConfig(forId: deviceId, config: ThingConfigUpdate(mode: newValue)).sink(receiveValue: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .failure(let error):
                    self?.alert = AlertData(error: error)
                case .success: break
                }
            })
            subscriptions.append(update)
            
        case .navBarItemTapped(let navItem):
            
            switch navItem {
                
            case .signOut:
                isLoading = true
                let logout = userRepository.logout().sink(receiveValue: { [weak self] result in
                    self?.isLoading = false
                    
                    switch result {
                    case .failure(let error):
                        self?.alert = AlertData(error: error)
                    case .success: break
                    }
                })
                subscriptions.append(logout)
            
            case .signIn:
                sheetNavigation = .auth
            }
            
        case .addScheduledRunTimeButtonTapped:
            sheetNavigation = .scheduleRunTime
            
        case .scheduleRunTimeSelected(let date):
            sheetNavigation = nil
            isLoading = true
            let schedule = thingRepository.createSchedule(forId: deviceId, schedule: ScheduleCreaton(time: date)).sink(receiveValue: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .failure(let error):
                    self?.alert = AlertData(error: error)
                case .success: break
                }
            })
            subscriptions.append(schedule)
            
        case .dismissSheet:
            sheetNavigation = nil
        }
    }
}
