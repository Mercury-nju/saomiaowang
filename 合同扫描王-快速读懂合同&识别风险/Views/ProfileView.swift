//
//  ProfileView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @Environment(ContractStore.self) var contractStore
    @Environment(UserStore.self) var userStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @State private var showClearAlert = false
    @State private var showLogoutAlert = false
    @State private var showSubscription = false
    
    private let privacyPolicyURL = "https://mercury-nju.github.io/saomiaowang/privacy-policy.html"
    private let userAgreementURL = "https://mercury-nju.github.io/saomiaowang/user-agreement.html"
    private let eulaURL = "https://mercury-nju.github.io/saomiaowang/eula.html"
    
    var body: some View {
        NavigationStack {
            List {
                // 会员状态
                Section {
                    membershipCard
                }
                
                // 用户信息
                Section {
                    if userStore.isLoggedIn {
                        loggedInHeader
                    } else {
                        loginSection
                    }
                }
                
                // 统计
                Section("使用统计") {
                    LabeledContent("已分析合同", value: "\(contractStore.analyzedContracts)")
                    LabeledContent("总合同数", value: "\(contractStore.totalContracts)")
                    LabeledContent("识别风险", value: "\(contractStore.highRiskCount)")
                }
                
                // 数据管理
                Section("数据管理") {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("清除所有合同", systemImage: "trash")
                    }
                }
                
                // 法律条款
                Section("关于") {
                    Link(destination: URL(string: privacyPolicyURL)!) {
                        HStack {
                            Label("隐私政策", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: userAgreementURL)!) {
                        HStack {
                            Label("用户协议", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: eulaURL)!) {
                        HStack {
                            Label("许可协议 (EULA)", systemImage: "doc.plaintext")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    LabeledContent("版本", value: "1.0.0")
                }
                
                // 退出登录
                if userStore.isLoggedIn {
                    Section {
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("退出登录")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的")
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("将删除所有合同数据，无法恢复。")
            }
            .alert("退出登录", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("退出", role: .destructive) {
                    userStore.logout()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }
    
    // MARK: - 会员卡片
    private var membershipCard: some View {
        Button {
            if !subscriptionStore.isVIP {
                showSubscription = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(subscriptionStore.isVIP ?
                              LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(subscriptionStore.isVIP ? .white : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionStore.isVIP ? subscriptionStore.subscriptionType.rawValue : "免费用户")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if subscriptionStore.isVIP {
                        if let expDate = subscriptionStore.expirationDate {
                            Text("有效期至 \(expDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("剩余 \(subscriptionStore.remainingFreeUsage) 次免费体验")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !subscriptionStore.isVIP {
                    Text("开通")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(14)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 已登录头部
    private var loggedInHeader: some View {
        HStack(spacing: 14) {
            // 头像
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Text(String(userStore.displayName.prefix(1)))
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userStore.displayName)
                    .font(.headline)
                
                if let email = userStore.userEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 登录区域
    private var loginSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "person.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("登录后同步数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleSignInResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 处理登录结果
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                
                var fullName: String?
                if let nameComponents = appleIDCredential.fullName {
                    let givenName = nameComponents.givenName ?? ""
                    let familyName = nameComponents.familyName ?? ""
                    fullName = "\(familyName)\(givenName)".isEmpty ? nil : "\(familyName)\(givenName)"
                }
                
                let email = appleIDCredential.email
                
                userStore.saveUser(userID: userID, name: fullName, email: email)
            }
        case .failure(let error):
            print("登录失败: \(error.localizedDescription)")
        }
    }
    
    private func clearAllData() {
        for contract in contractStore.contracts {
            contractStore.deleteContract(contract)
        }
    }
}

#Preview {
    ProfileView()
        .environment(ContractStore())
        .environment(UserStore())
        .environment(SubscriptionStore())
}
