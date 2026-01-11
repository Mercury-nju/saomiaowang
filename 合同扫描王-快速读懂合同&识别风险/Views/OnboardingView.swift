//
//  OnboardingView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import StoreKit

struct OnboardingView: View {
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    // 第一页：欢迎
                    WelcomePage()
                        .tag(0)
                    
                    // 第二页：核心功能
                    FeaturePage()
                        .tag(1)
                    
                    // 第三页：付费页
                    PaywallPage(
                        hasCompletedOnboarding: $hasCompletedOnboarding
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 底部（非付费页显示）
                if currentPage < 2 {
                    bottomSection
                }
            }
        }
    }
    
    // MARK: - 底部区域
    private var bottomSection: some View {
        VStack(spacing: 16) {
            // 页面指示器
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            
            // 继续按钮
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } label: {
                Text("继续")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 欢迎页
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo区域
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 12) {
                    Text("合同扫描王")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("快速读懂合同 · 识别潜在风险")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 特点列表
            VStack(spacing: 16) {
                FeatureRow(icon: "camera.fill", text: "拍照即可识别合同内容")
                FeatureRow(icon: "brain", text: "AI智能分析关键条款")
                FeatureRow(icon: "shield.checkerboard", text: "快速识别明显风险点")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - 功能页
struct FeaturePage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 功能展示
            VStack(spacing: 40) {
                Text("三步读懂合同")
                    .font(.system(size: 28, weight: .bold))
                
                VStack(spacing: 24) {
                    StepCard(
                        step: "1",
                        icon: "camera.viewfinder",
                        title: "扫描合同",
                        description: "拍照或上传合同文件",
                        color: .blue
                    )
                    
                    StepCard(
                        step: "2",
                        icon: "sparkles",
                        title: "AI分析",
                        description: "智能提取关键条款和风险",
                        color: .purple
                    )
                    
                    StepCard(
                        step: "3",
                        icon: "checkmark.shield",
                        title: "获取报告",
                        description: "清晰了解合同重点内容",
                        color: .green
                    )
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - 付费页
struct PaywallPage: View {
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Binding var hasCompletedOnboarding: Bool
    @State private var selectedPlan: String = "yearly"
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("解锁全部功能")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("无限次分析合同，识别风险")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // 权益
                VStack(spacing: 12) {
                    BenefitRow(icon: "infinity", text: "无限次合同分析")
                    BenefitRow(icon: "brain.head.profile", text: "AI智能问答")
                    BenefitRow(icon: "doc.on.doc", text: "合同对比功能")
                    BenefitRow(icon: "square.and.arrow.up", text: "导出分析报告")
                }
                .padding(.horizontal, 32)
                
                // 订阅选项
                VStack(spacing: 12) {
                    // 年度
                    PlanCard(
                        title: "年度会员",
                        price: "¥128",
                        period: "/年",
                        subtitle: "平均每月仅¥10.7",
                        isSelected: selectedPlan == "yearly",
                        badge: "推荐"
                    ) {
                        selectedPlan = "yearly"
                    }
                    
                    // 月度
                    PlanCard(
                        title: "月度会员",
                        price: "¥18",
                        period: "/月",
                        subtitle: "随时取消",
                        isSelected: selectedPlan == "monthly",
                        badge: nil
                    ) {
                        selectedPlan = "monthly"
                    }
                }
                .padding(.horizontal, 24)
                
                // 订阅按钮
                Button {
                    Task {
                        await purchase()
                    }
                } label: {
                    HStack {
                        if subscriptionStore.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("立即订阅")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .disabled(subscriptionStore.isPurchasing)
                .padding(.horizontal, 24)
                
                // 免费体验入口
                Button {
                    completeOnboarding()
                } label: {
                    Text("先免费体验一次")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 恢复购买
                Button {
                    Task {
                        await subscriptionStore.restorePurchases()
                        if subscriptionStore.isVIP {
                            completeOnboarding()
                        }
                    }
                } label: {
                    Text("恢复购买")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 说明
                VStack(spacing: 4) {
                    Text("订阅后可随时在系统设置中取消")
                    Text("AI分析仅供参考，重要合同请咨询专业律师")
                }
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func purchase() async {
        let productID = selectedPlan == "yearly" ? 
            SubscriptionStore.yearlyProductID : 
            SubscriptionStore.monthlyProductID
        
        if let product = subscriptionStore.products.first(where: { $0.id == productID }) {
            let success = await subscriptionStore.purchase(product)
            if success {
                completeOnboarding()
            }
        } else {
            // 产品未加载时直接进入
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
    }
}

// MARK: - 组件

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

struct StepCard: View {
    let step: String
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(step)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color.opacity(0.3))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let subtitle: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .blue : .primary)
                    
                    Text(period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(SubscriptionStore())
}
