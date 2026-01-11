//
//  SubscriptionView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部
                    headerSection
                    
                    // 权益对比
                    benefitsSection
                    
                    // 订阅选项
                    subscriptionOptions
                    
                    // 购买按钮
                    purchaseButton
                    
                    // 恢复购买
                    restoreButton
                    
                    // 说明
                    disclaimerSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("开通会员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedProduct == nil {
                    selectedProduct = subscriptionStore.products.first
                }
            }
        }
    }
    
    // MARK: - 头部
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            Text("解锁全部功能")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("无限次合同分析，智能风险识别")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 权益对比
    private var benefitsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("功能")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("免费")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 50)
                Text("VIP")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .frame(width: 50)
            }
            .padding()
            .background(Color(.systemGray6))
            
            Divider()
            
            benefitRow("合同分析", free: "1次", vip: "无限")
            benefitRow("AI问答", free: "1次", vip: "无限")
            benefitRow("风险识别", free: "✓", vip: "✓")
            benefitRow("导出报告", free: "✓", vip: "✓")
            benefitRow("合同对比", free: "✗", vip: "✓")
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func benefitRow(_ title: String, free: String, vip: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(free)
                    .font(.subheadline)
                    .foregroundColor(free == "✗" ? .red : .secondary)
                    .frame(width: 50)
                Text(vip)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .frame(width: 50)
            }
            .padding()
            
            Divider().padding(.leading)
        }
    }
    
    // MARK: - 订阅选项
    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionStore.products, id: \.id) { product in
                SubscriptionOptionCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isMonthly: product.id == SubscriptionStore.monthlyProductID
                ) {
                    selectedProduct = product
                }
            }
            
            // 如果产品未加载，显示占位
            if subscriptionStore.products.isEmpty {
                SubscriptionPlaceholder(
                    title: "月度会员",
                    price: "¥18/月",
                    subtitle: "自动续订，可随时取消",
                    isSelected: true
                )
                
                SubscriptionPlaceholder(
                    title: "年度会员",
                    price: "¥128/年",
                    subtitle: "平均¥10.7/月，省¥110",
                    isSelected: false
                )
            }
        }
    }
    
    // MARK: - 购买按钮
    private var purchaseButton: some View {
        Button {
            Task {
                if let product = selectedProduct {
                    let success = await subscriptionStore.purchase(product)
                    if success {
                        dismiss()
                    }
                }
            }
        } label: {
            HStack {
                if subscriptionStore.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("立即开通")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(subscriptionStore.isPurchasing || selectedProduct == nil)
    }
    
    // MARK: - 恢复购买
    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionStore.restorePurchases()
                if subscriptionStore.isVIP {
                    dismiss()
                }
            }
        } label: {
            Text("恢复购买")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 说明
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("订阅说明")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("• 订阅将通过您的Apple ID账户自动续订\n• 可随时在设置中取消订阅\n• 月度会员¥18/月\n• 年度会员¥128/年，平均每月仅¥10.7")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 订阅选项卡片
struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let isMonthly: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isMonthly ? "月度会员" : "年度会员")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !isMonthly {
                            Text("推荐")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(isMonthly ? "¥18/月" : "¥128/年，平均¥10.7/月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .orange : .primary)
                    
                    if !isMonthly {
                        Text("省¥110")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - 占位卡片
struct SubscriptionPlaceholder: View {
    let title: String
    let price: String
    let subtitle: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(price)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .orange : .primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    SubscriptionView()
        .environment(SubscriptionStore())
}
