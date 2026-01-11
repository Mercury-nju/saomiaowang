//
//  ContractScannerApp.swift
//  合同扫描王-快速读懂合同&识别风险
//
//  Created by Mercury on 2026/1/9.
//

import SwiftUI

@main
struct ContractScannerApp: App {
    @State private var contractStore = ContractStore()
    @State private var userStore = UserStore()
    @State private var subscriptionStore = SubscriptionStore()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(contractStore)
                    .environment(userStore)
                    .environment(subscriptionStore)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environment(subscriptionStore)
            }
        }
    }
}
