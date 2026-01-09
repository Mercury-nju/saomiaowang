//
//  QAView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI
import Combine

struct QAView: View {
    @Environment(ContractStore.self) var contractStore
    @Environment(\.dismiss) var dismiss
    let contract: Contract
    
    @State private var question = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // 欢迎消息
                            if messages.isEmpty {
                                welcomeMessage
                            }
                            
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                LoadingBubble()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 输入区域
                inputArea
            }
            .navigationTitle("AI问答")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            messages = []
                        } label: {
                            Label("清空对话", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadHistory()
            }
        }
    }
    
    // MARK: - 欢迎消息
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("AI合同助手")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("您可以针对这份合同提出任何问题，我会为您解答")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 快捷问题
            VStack(spacing: 12) {
                Text("常见问题")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(quickQuestions, id: \.self) { q in
                    Button {
                        question = q
                        sendMessage()
                    } label: {
                        Text(q)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
    
    private var quickQuestions: [String] {
        [
            "这份合同的主要风险是什么？",
            "违约责任是怎么规定的？",
            "合同的有效期是多久？",
            "如何解除这份合同？"
        ]
    }
    
    // MARK: - 输入区域
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("输入您的问题...", text: $question, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isInputFocused)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(question.isEmpty ? .gray : .blue)
            }
            .disabled(question.isEmpty || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 发送消息
    private func sendMessage() {
        let userQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userQuestion.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(role: .user, content: userQuestion)
        messages.append(userMessage)
        question = ""
        isInputFocused = false
        isLoading = true
        
        // 获取历史记录作为上下文
        let qaRecords = contractStore.getQARecords(for: contract.id)
        
        Task {
            do {
                let answer = try await AIService.shared.askQuestion(
                    question: userQuestion,
                    contractText: contract.originalText,
                    context: qaRecords
                )
                
                await MainActor.run {
                    // 添加AI回复
                    let aiMessage = ChatMessage(role: .assistant, content: answer)
                    messages.append(aiMessage)
                    
                    // 保存问答记录
                    let record = QARecord(
                        question: userQuestion,
                        answer: answer,
                        contractId: contract.id
                    )
                    contractStore.addQARecord(record)
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        content: "抱歉，回答问题时出现错误：\(error.localizedDescription)"
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - 加载历史
    private func loadHistory() {
        let records = contractStore.getQARecords(for: contract.id)
        for record in records.reversed() {
            messages.append(ChatMessage(role: .user, content: record.question))
            messages.append(ChatMessage(role: .assistant, content: record.answer))
        }
    }
}

// MARK: - 聊天消息模型
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
    
    enum MessageRole {
        case user
        case assistant
    }
}

// MARK: - 聊天气泡
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray6))
                    .cornerRadius(16)
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - 加载气泡
struct LoadingBubble: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .opacity(dotCount % 3 == index ? 1 : 0.3)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount += 1
        }
    }
}

#Preview {
    QAView(contract: Contract(title: "测试合同", originalText: "这是测试内容"))
        .environment(ContractStore())
}
