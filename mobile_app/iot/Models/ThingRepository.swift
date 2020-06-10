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
            
            self.functions.httpsCallable("deviceCommand").call(["id": id, "command": command.rawValue]) { result, error in
                
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
}
