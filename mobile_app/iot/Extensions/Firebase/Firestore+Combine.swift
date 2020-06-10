//
//  Firestore+Combine.swift
//
//  Created by Mark Randall on 10/4/19.
//  Copyright © 2019 Mark Randall. All rights reserved.
//

import Foundation
import Combine
import FirebaseFirestore

// MARK: - FirestoreQueryPublisher

struct FirestoreQueryPublisher: Combine.Publisher {
    
    typealias Output = Result<QuerySnapshot, Error>
    typealias Failure = Never
    
    let query: Query
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {

        // TODO: How do I remove the listener
        query.addSnapshotListener { snapshot, error in
            
            if let error = error {
                _ = subscriber.receive(.failure(error))
            } else if let snapshot = snapshot {
                _ = subscriber.receive(.success(snapshot))
            }
        }
    }
}

// MARK: - FirestoreQueryPublisher

struct FirestoreDocumentPublisher: Combine.Publisher {
    
    typealias Output = Result<DocumentSnapshot, Error>
    typealias Failure = Never
    
    let document: DocumentReference
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {

        // TODO: How do I remove the listener
        document.addSnapshotListener { snapshot, error in
            
            if let error = error {
                _ = subscriber.receive(.failure(error))
            } else if let snapshot = snapshot {
                _ = subscriber.receive(.success(snapshot))
            }
        }
    }
}

// MARK: - FirestoreDocumentUpdatePublisher

struct FirestoreDocumentUpdatePublisher: Combine.Publisher {
    
    typealias Output = Result<Bool, Error>
    typealias Failure = Never
    
    let document: DocumentReference
    let update: [AnyHashable: Any]
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {

        document.updateData(update) { error in
    
            if let error = error {
                _ = subscriber.receive(.failure(error))
            } else {
                _ = subscriber.receive(.success(true))
            }
    
            _ = subscriber.receive(completion: .finished)
        }
    }
}

// MARK: - FirestoreDocumentSetPublisher

struct FirestoreDocumentSetPublisher: Combine.Publisher {
    
    typealias Output = Result<Bool, Error>
    typealias Failure = Never
    
    let document: DocumentReference
    let set: [String: Any]
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {

        document.setData(set) { error in
    
            if let error = error {
                _ = subscriber.receive(.failure(error))
            } else {
                _ = subscriber.receive(.success(true))
            }
    
            _ = subscriber.receive(completion: .finished)
        }
    }
}

// MARK: - FirebaseFirestore.Query

extension FirebaseFirestore.Query {

    func snapshotListenerPublisher() -> FirestoreQueryPublisher {
        FirestoreQueryPublisher(query: self)
    }
}

// MARK: - FirebaseFirestore.DocumentReference

extension FirebaseFirestore.DocumentReference {

    func snapshotListenerPublisher() -> FirestoreDocumentPublisher {
        FirestoreDocumentPublisher(document: self)
    }
    
    func updatePublisher(_ update: [AnyHashable: Any]) -> FirestoreDocumentUpdatePublisher {
        FirestoreDocumentUpdatePublisher(document: self, update: update)
    }
    
    func setPublisher(_ set: [String: Any]) -> FirestoreDocumentSetPublisher {
        FirestoreDocumentSetPublisher(document: self, set: set)
    }
}
