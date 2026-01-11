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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 顶部
                VStack(spacing: 12) {
                    // 用户数
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("已有 10,000+ 用户使用")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 30)
                    
                    Text("解锁全部功能")
                        .font(.system(size: 28, weight: .bold))
                    
                    // 评分
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text("4.9")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                // 权益
                VStack(spacing: 14) {
                    BenefitItem(icon: "infinity", text: "无限次合同分析", highlight: true)
                    BenefitItem(icon: "bolt.fill", text: "AI智能风险识别", highlight: true)
                    BenefitItem(icon: "bubble.left.and.bubble.right.fill", text: "合同问答助手", highlight: false)
                    BenefitItem(icon: "square.and.arrow.up", text: "导出分析报告", highlight: false)
                }
                .padding(.horizontal, 24)
                
                // 订阅选项
                VStack(spacing: 10) {
                    // 年度 - 推荐
                    SubscriptionOption(
                        title: "年度会员",
                        price: "¥128",
                        period: "/年",
                        originalPrice: "¥216",
                        badge: "省¥88",
                        subtitle: "每天仅需¥0.35",
                        isSelected: selectedPlan == "yearly"
                    ) {
                        selectedPlan = "yearly"
                    }
                    
                    // 月度
                    SubscriptionOption(
                        title: "月度会员",
                        price: "¥18",
                        period: "/月",
                        originalPrice: nil,
                        badge: nil,
                        subtitle: "随时取消",
                        isSelected: selectedPlan == "monthly"
                    ) {
                        selectedPlan = "monthly"
                    }
                }
                .padding(.horizontal, 20)
                
                // 订阅按钮
                VStack(spacing: 12) {
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
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    .disabled(subscriptionStore.isPurchasing)
                    
                    // 免费试用
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("先免费体验1次")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                
                // 底部说明
                VStack(spacing: 8) {
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
                    
                    Text("自动续订，可随时取消 · AI分析仅供参考")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
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

struct BenefitItem: View {
    let icon: String
    let text: String
    let highlight: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(highlight ? .blue : .secondary)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(highlight ? .primary : .secondary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(.green)
        }
    }
}

struct SubscriptionOption: View {
    let title: String
    let price: String
    let period: String
    let originalPrice: String?
    let badge: String?
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 选中指示
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.4))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let original = originalPrice {
                        Text(original)
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(SubscriptionStore())
}
