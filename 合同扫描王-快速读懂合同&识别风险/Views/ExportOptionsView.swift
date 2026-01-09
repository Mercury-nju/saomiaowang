//
//  ExportOptionsView.swift
//  合同扫描王-快速读懂合同&识别风险
//

import SwiftUI

struct ExportOptionsView: View {
    @Environment(\.dismiss) var dismiss
    let contract: Contract
    
    @State private var selectedScope: ExportService.ExportScope = .full
    @State private var selectedFormat: ExportService.ExportFormat = .pdf
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedData: Data?
    @State private var exportedText: String?
    
    var body: some View {
        NavigationStack {
            List {
                // 导出范围
                Section("导出范围") {
                    ForEach(scopeOptions, id: \.0) { option in
                        Button {
                            selectedScope = option.1
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.0)
                                        .foregroundColor(.primary)
                                    Text(option.2)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedScope == option.1 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // 导出格式
                Section("导出格式") {
                    ForEach(formatOptions, id: \.0) { option in
                        Button {
                            selectedFormat = option.1
                        } label: {
                            HStack {
                                Image(systemName: option.2)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text(option.0)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedFormat == option.1 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // 预览信息
                Section("导出预览") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("合同名称")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(contract.title)
                        }
                        
                        if let analysis = contract.analysisResult {
                            HStack {
                                Text("关键条款")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(analysis.keyTerms.count) 条")
                            }
                            
                            HStack {
                                Text("风险提示")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(analysis.riskItems.count) 项")
                            }
                        }
                    }
                }
            }
            .navigationTitle("导出报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportReport()
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Text("导出")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let data = exportedData {
                    ShareSheet(items: [data])
                } else if let text = exportedText {
                    ShareSheet(items: [text])
                }
            }
        }
    }
    
    private var scopeOptions: [(String, ExportService.ExportScope, String)] {
        [
            ("完整报告", .full, "包含摘要、关键条款、风险提示和简明解读"),
            ("仅关键条款", .keyTerms, "仅导出识别到的关键条款"),
            ("仅风险提示", .risks, "仅导出风险提示和建议"),
            ("仅摘要", .summary, "仅导出合同摘要")
        ]
    }
    
    private var formatOptions: [(String, ExportService.ExportFormat, String)] {
        [
            ("PDF文档", .pdf, "doc.fill"),
            ("纯文本", .text, "doc.text")
        ]
    }
    
    private func exportReport() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            switch selectedFormat {
            case .pdf:
                if let data = ExportService.shared.generatePDF(for: contract, scope: selectedScope) {
                    DispatchQueue.main.async {
                        exportedData = data
                        exportedText = nil
                        isExporting = false
                        showShareSheet = true
                    }
                }
            case .text:
                let text = ExportService.shared.generateText(for: contract, scope: selectedScope)
                DispatchQueue.main.async {
                    exportedText = text
                    exportedData = nil
                    isExporting = false
                    showShareSheet = true
                }
            }
        }
    }
}

// MARK: - 分享Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportOptionsView(contract: Contract(title: "测试合同", originalText: "测试内容"))
}
