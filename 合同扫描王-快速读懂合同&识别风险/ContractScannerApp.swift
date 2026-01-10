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
    @State private var showDisclaimer = false
    
    private let disclaimerKey = "has_accepted_disclaimer"
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(contractStore)
                .environment(userStore)
                .onAppear {
                    if !UserDefaults.standard.bool(forKey: disclaimerKey) {
                        showDisclaimer = true
                    }
                }
                .alert("重要提示", isPresented: $showDisclaimer) {
                    Button("我已知晓并同意") {
                        UserDefaults.standard.set(true, forKey: disclaimerKey)
                    }
                } message: {
                    Text("本应用使用AI技术分析合同，分析结果仅供参考，可能无法识别所有潜在风险，不构成法律建议。签署重要合同前，请咨询专业律师。")
                }
        }
    }
}
