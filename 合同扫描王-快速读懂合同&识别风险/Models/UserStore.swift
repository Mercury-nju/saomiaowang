//
//  UserStore.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation
import AuthenticationServices

@Observable
class UserStore {
    var isLoggedIn: Bool = false
    var userID: String?
    var userName: String?
    var userEmail: String?
    
    private let userIDKey = "apple_user_id"
    private let userNameKey = "apple_user_name"
    private let userEmailKey = "apple_user_email"
    
    init() {
        loadUser()
    }
    
    func loadUser() {
        userID = UserDefaults.standard.string(forKey: userIDKey)
        userName = UserDefaults.standard.string(forKey: userNameKey)
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        isLoggedIn = userID != nil
    }
    
    func saveUser(userID: String, name: String?, email: String?) {
        self.userID = userID
        self.userName = name
        self.userEmail = email
        self.isLoggedIn = true
        
        UserDefaults.standard.set(userID, forKey: userIDKey)
        if let name = name {
            UserDefaults.standard.set(name, forKey: userNameKey)
        }
        if let email = email {
            UserDefaults.standard.set(email, forKey: userEmailKey)
        }
    }
    
    func logout() {
        userID = nil
        userName = nil
        userEmail = nil
        isLoggedIn = false
        
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
    }
    
    var displayName: String {
        if let name = userName, !name.isEmpty {
            return name
        }
        if let email = userEmail {
            return email.components(separatedBy: "@").first ?? "用户"
        }
        return "用户"
    }
}
