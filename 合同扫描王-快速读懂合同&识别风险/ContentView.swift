//
//  ContentView.swift
//  合同扫描王-快速读懂合同&识别风险
//
//  Created by Mercury on 2026/1/9.
//

import SwiftUI

struct ContentView: View {
    @State private var contractStore = ContractStore()
    
    var body: some View {
        MainTabView()
            .environment(contractStore)
    }
}

#Preview {
    ContentView()
}
