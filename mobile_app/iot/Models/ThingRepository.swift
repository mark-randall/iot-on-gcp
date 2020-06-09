//
//  ThingRepository.swift
//  iot
//
//  Created by Mark Randall on 6/8/20.
//  Copyright © 2020 Mark Randall. All rights reserved.
//

import Combine
import FirebaseFirestore

protocol ThingRepository {
    
    func fetchThing(forId id: String) -> AnyPublisher<Result<Thing, Error>, Never>
}

final class FirebaseThingRepository: ThingRepository {
    
    private let db = Firestore.firestore()
    
    func fetchThing(forId id: String) -> AnyPublisher<Result<Thing, Error>, Never> {
                
        return db.collection("devices").document(id)
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
}


