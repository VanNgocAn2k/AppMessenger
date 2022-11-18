//
//  DatabaseManager.swift
//  AppMessenger
//
//  Created by Van Ngoc An  on 18/11/2022.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
//    public func test() {
//        database.child("foo").setValue(["something": true ])
//    }
}
// account management
extension DatabaseManager {
    public func userExist(with email: String,
                          completion: @escaping ((Bool) -> Void)) {
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    // inserts new user to data base
    public func insertUser(with user: AppMessengerUser) {
        database.child(user.emailAddress).setValue(["first_name": user.firstName,
                                                    "last_name": user.lastName])
    }
}
struct AppMessengerUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
}
