//
//  ThingRepository.swift
//  iot
//
//  Created by Mark Randall on 6/8/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Combine
import FirebaseFirestore
import FirebaseFunctions

enum ThingCommand: String {
    case start
    case stop
}

struct ThingConfigUpdate {
    let mode: String
}

struct ScheduleCreaton {
    let id = UUID().uuidString
    let time: Date
}

protocol ThingRepository {
    
    func fetch(forId id: String) -> AnyPublisher<Result<Thing, Error>, Never>
    
    func fetchConfig(forId id: String) -> AnyPublisher<Result<ThingConfig, Error>, Never>
    
    func updateConfig(forId id: String, config: ThingConfigUpdate) -> Future<Result<Bool, Error>, Never>
    
    func sendCommand(forId id: String, command: ThingCommand) -> Future<Result<Bool, Error>, Never>

    func createSchedule(forId id: String, schedule: ScheduleCreaton) -> Future<Result<Bool, Error>, Never>
    
    func fetchSchedule(forId id: String) -> AnyPublisher<Result<[ThingSchedule], Error>, Never>
}

final class FirebaseThingRepository: ThingRepository {
    
    private lazy var db = Firestore.firestore()
    private lazy var functions = Functions.functions()
    
    // MARK: - State
    
    func fetch(forId id: String) -> AnyPublisher<Result<Thing, Error>, Never> {
                
        db.collection("devices").document(id)
        .snapshotListenerPublisher()
        .handleEvents(receiveOutput: { result in
            print(result)
        }).map { result in
            
            switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let snapshot):
                do {
                    let model = try snapshot.data(as: Thing.self)! // TODO: improve error handling
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Config
    
    func fetchConfig(forId id: String) -> AnyPublisher<Result<ThingConfig, Error>, Never> {
                
        db.collection("device_configs").document(id)
        .snapshotListenerPublisher()
        .handleEvents(receiveOutput: { result in
            print(result)
        }).map { result in
            
            switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let snapshot):
                do {
                    let model = try snapshot.data(as: ThingConfig.self)! // TODO: improve error handling
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateConfig(forId id: String, config: ThingConfigUpdate) -> Future<Result<Bool, Error>, Never> {
        
        Future { [weak self] promise in
        
            guard let self = self else { preconditionFailure(); }
            
            let update = ["mode": config.mode]
            self.db.collection("device_configs").document(id).updateData(update) { error in
    
                // TODO: should I wait for this completions
                if let error = error {
                    promise(.success(.failure(error)))
                } else {
                    promise(.success(.success(true)))
                }
            }
        }
    }
    
    // MARK: - Commands
    
    func sendCommand(forId id: String, command: ThingCommand) -> Future<Result<Bool, Error>, Never> {
        
        Future { [weak self] promise in
        
            guard let self = self else { preconditionFailure(); }
            
            let commandData = [
                "type": "running_state",
                "value": command.rawValue
            ]
            
            self.functions.httpsCallable("callable_deviceCommand").call(["id": id, "command": commandData]) { result, error in
                
                if let error = error {
                    promise(.success(.failure(error)))
                } else if result != nil {
                    promise(.success(.success(true)))
                } else {
                    preconditionFailure()
                }
            }
        }
    }
    
    // MARK: - Scheduled commands
    
    func createSchedule(forId id: String, schedule: ScheduleCreaton) -> Future<Result<Bool, Error>, Never> {
        
        Future { [weak self] promise in
            
            guard let self = self else { preconditionFailure(); }
            
            self.db.document("device_configs/\(id)/schedule/\(schedule.id)").setData(["time": Timestamp(date: schedule.time)]) { error in
    
                // TODO: should I wait for this completions
                if let error = error {
                    promise(.success(.failure(error)))
                } else {
                    promise(.success(.success(true)))
                }
            }
        }
    }
    
    func fetchSchedule(forId id: String) -> AnyPublisher<Result<[ThingSchedule], Error>, Never> {
        
        db.collection("device_configs/\(id)/schedule")
        .snapshotListenerPublisher()
        .handleEvents(receiveOutput: { result in
            print(result)
        }).map { result in
            
            switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let querySnapshot):
                let models = querySnapshot.documents.compactMap { snapshot in
                    try? snapshot.data(as: ThingSchedule.self)
                }
                return .success(models)
            }
        }.eraseToAnyPublisher()
    }
}
