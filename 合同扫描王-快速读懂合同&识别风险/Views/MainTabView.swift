//
//  MainTabView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            ContractListView()
                .tabItem {
                    Label("合同", systemImage: "doc.text.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .environment(ContractStore())
        .environment(UserStore())
        .environment(SubscriptionStore())
}
