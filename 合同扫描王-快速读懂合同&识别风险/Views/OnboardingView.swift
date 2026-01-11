//
//  OnboardingView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.text.viewfinder",
            title: "扫描识别",
            subtitle: "拍照或上传合同，AI自动识别文字内容",
            color: .blue
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "智能分析",
            subtitle: "快速提炼关键条款，了解合同大致内容",
            color: .purple
        ),
        OnboardingPage(
            icon: "exclamationmark.shield",
            title: "风险识别",
            subtitle: "识别明显风险点，为您的决策提供参考",
            color: .orange
        ),
        OnboardingPage(
            icon: "bubble.left.and.bubble.right",
            title: "AI问答",
            subtitle: "针对合同内容提问，获取即时解答",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面内容
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 底部区域
            VStack(spacing: 20) {
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                
                // 按钮
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "继续" : "开始使用")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                // 跳过按钮
                if currentPage < pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("跳过")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 免责提示
                    Text("AI分析仅供参考，重要合同请咨询专业律师")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
    }
}

// MARK: - 页面数据
struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - 单页视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(page.color)
            }
            
            // 文字
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
