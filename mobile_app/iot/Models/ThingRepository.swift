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

protocol ThingRepository {
    
    func fetch(forId id: String) -> AnyPublisher<Result<Thing, Error>, Never>
    
    func sendCommand(forId id: String, command: ThingCommand) -> Future<Result<Bool, Error>, Never>
    
    func updateMode(forId id: String, mode: String) -> Future<Result<Bool, Error>, Never>
}

final class FirebaseThingRepository: ThingRepository {
    
    private lazy var db = Firestore.firestore()
    private lazy var functions = Functions.functions()
    
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
    
    func sendCommand(forId id: String, command: ThingCommand) -> Future<Result<Bool, Error>, Never> {
        
        return Future { [weak self] promise in
        
            guard let self = self else { preconditionFailure(); }
            
            let commandData = [
                "type": "running_state",
                "value": command.rawValue
            ]
            
            self.functions.httpsCallable("deviceCommand").call(["id": id, "command": commandData]) { result, error in
                
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
    
    func updateMode(forId id: String, mode: String) -> Future<Result<Bool, Error>, Never> {
        
        return Future { [weak self] promise in
        
            guard let self = self else { preconditionFailure(); }
            
            let update = ["mode": mode]
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
}
