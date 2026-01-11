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
            // 背景
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    PainPointPage()
                        .tag(0)
                    
                    SolutionPage()
                        .tag(1)
                    
                    PaywallPage(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // 底部（非付费页）
                if currentPage < 2 {
                    bottomSection
                }
            }
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            // 页面指示器
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                }
            }
            
            Button {
                withAnimation {
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
            .padding(.bottom, 50)
        }
    }
}

// MARK: - 第一页：痛点
struct PainPointPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding(.bottom, 32)
            
            // 痛点文案
            VStack(spacing: 16) {
                Text("看不懂合同？")
                    .font(.system(size: 32, weight: .bold))
                
                Text("担心签了才发现有坑？")
                    .font(.system(size: 32, weight: .bold))
            }
            
            Spacer()
            
            // 痛点列表
            VStack(alignment: .leading, spacing: 16) {
                PainPointRow(icon: "clock", text: "合同太长，没时间细看")
                PainPointRow(icon: "questionmark.circle", text: "专业术语多，看不懂")
                PainPointRow(icon: "exclamationmark.triangle", text: "隐藏条款，容易踩坑")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

struct PainPointRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red.opacity(0.7))
                .frame(width: 28)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 第二页：解决方案 + 报告预览
struct SolutionPage: View {
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            VStack(spacing: 8) {
                Text("AI帮你3秒读懂合同")
                    .font(.system(size: 26, weight: .bold))
                
                Text("识别风险，避免踩坑")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            .padding(.bottom, 24)
            
            // 模拟报告
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // 合同信息
                    DemoCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                Text("房屋租赁合同")
                                    .font(.headline)
                                Spacer()
                                Text("已分析")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Divider()
                            
                            DemoInfoRow(label: "租期", value: "12个月")
                            DemoInfoRow(label: "月租", value: "¥5,000")
                            DemoInfoRow(label: "押金", value: "¥10,000")
                        }
                    }
                    
                    // 风险提示
                    DemoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .foregroundColor(.orange)
                                Text("发现 2 个风险")
                                    .font(.headline)
                            }
                            
                            Divider()
                            
                            DemoRiskItem(
                                level: "高",
                                color: .red,
                                title: "违约金过高",
                                desc: "提前退租需付3个月租金"
                            )
                            
                            DemoRiskItem(
                                level: "中",
                                color: .orange,
                                title: "押金退还条款模糊",
                                desc: "未明确退还时间和条件"
                            )
                        }
                    }
                    
                    // 关键条款
                    DemoCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .foregroundColor(.purple)
                                Text("关键条款")
                                    .font(.headline)
                            }
                            
                            Divider()
                            
                            DemoClauseItem(tag: "付款", text: "每月1日前付款")
                            DemoClauseItem(tag: "维修", text: "500元以下租客承担")
                            DemoClauseItem(tag: "转租", text: "禁止转租")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
    }
}

struct DemoCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct DemoInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct DemoRiskItem: View {
    let level: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(level)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(color)
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DemoClauseItem: View {
    let tag: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(4)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 第三页：付费页
struct PaywallPage: View {
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Binding var hasCompletedOnboarding: Bool
    @State private var selectedPlan: String = "yearly"
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 顶部图标和标题
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 50)
                        
                        Text("解锁全部功能")
                            .font(.system(size: 26, weight: .bold))
                    }
                    
                    // 权益列表
                    VStack(spacing: 0) {
                        PaywallBenefitRow(icon: "infinity", text: "无限次合同分析")
                        Divider().padding(.leading, 48)
                        PaywallBenefitRow(icon: "brain.head.profile", text: "AI智能风险识别")
                        Divider().padding(.leading, 48)
                        PaywallBenefitRow(icon: "bubble.left.and.bubble.right", text: "合同问答助手")
                        Divider().padding(.leading, 48)
                        PaywallBenefitRow(icon: "square.and.arrow.up", text: "导出分析报告")
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // 订阅选项
                    VStack(spacing: 12) {
                        // 年度
                        PaywallPlanCard(
                            title: "年度会员",
                            price: "¥128",
                            period: "/年",
                            subtitle: "平均每月 ¥10.7",
                            badge: "推荐",
                            badgeColor: .blue,
                            isSelected: selectedPlan == "yearly"
                        ) {
                            selectedPlan = "yearly"
                        }
                        
                        // 月度
                        PaywallPlanCard(
                            title: "月度会员",
                            price: "¥18",
                            period: "/月",
                            subtitle: "按月订阅，随时取消",
                            badge: nil,
                            badgeColor: .clear,
                            isSelected: selectedPlan == "monthly"
                        ) {
                            selectedPlan = "monthly"
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 按钮区域
                    VStack(spacing: 14) {
                        Button {
                            Task { await purchase() }
                        } label: {
                            HStack {
                                if subscriptionStore.isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("立即开通")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(subscriptionStore.isPurchasing)
                    }
                    .padding(.horizontal, 20)
                    
                    // 底部
                    VStack(spacing: 10) {
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
                        
                        Text("订阅自动续期，可随时在系统设置中取消")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                        
                        Text("AI分析仅供参考，重要合同请咨询专业律师")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            
            // 关闭按钮
            Button {
                completeOnboarding()
            } label: {
                Image(systemName: "xmark")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
    }
    
    private func purchase() async {
        let productID = selectedPlan == "yearly" ?
            SubscriptionStore.yearlyProductID :
            SubscriptionStore.monthlyProductID
        
        if let product = subscriptionStore.products.first(where: { $0.id == productID }) {
            let success = await subscriptionStore.purchase(product)
            if success { completeOnboarding() }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
    }
}

struct PaywallBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct PaywallPlanCard: View {
    let title: String
    let price: String
    let period: String
    let subtitle: String
    let badge: String?
    let badgeColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 选中圆圈
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // 标题和副标题
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 价格
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
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
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(SubscriptionStore())
}
