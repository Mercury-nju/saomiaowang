//
//  ContractStore.swift
//  合同扫描王-快速读懂合同&识别风险
//

import Foundation
import SwiftUI
import Observation

@Observable
class ContractStore {
    var contracts: [Contract] = []
    var qaRecords: [QARecord] = []
    
    private let contractsKey = "saved_contracts"
    private let qaRecordsKey = "saved_qa_records"
    
    init() {
        loadContracts()
        loadQARecords()
    }
    
    // MARK: - 合同管理
    func addContract(_ contract: Contract) {
        contracts.insert(contract, at: 0)
        saveContracts()
    }
    
    func updateContract(_ contract: Contract) {
        if let index = contracts.firstIndex(where: { $0.id == contract.id }) {
            var updatedContract = contract
            updatedContract.updatedAt = Date()
            contracts.remove(at: index)
            contracts.insert(updatedContract, at: index)
            saveContracts()
        }
    }
    
    func deleteContract(_ contract: Contract) {
        contracts.removeAll { $0.id == contract.id }
        qaRecords.removeAll { $0.contractId == contract.id }
        saveContracts()
        saveQARecords()
    }
    
    func getContract(by id: UUID) -> Contract? {
        return contracts.first { $0.id == id }
    }
    
    // MARK: - 问答记录管理
    func addQARecord(_ record: QARecord) {
        qaRecords.insert(record, at: 0)
        saveQARecords()
    }
    
    func getQARecords(for contractId: UUID) -> [QARecord] {
        return qaRecords.filter { $0.contractId == contractId }
    }
    
    // MARK: - 持久化
    private func saveContracts() {
        if let encoded = try? JSONEncoder().encode(contracts) {
            UserDefaults.standard.set(encoded, forKey: contractsKey)
        }
    }
    
    private func loadContracts() {
        if let data = UserDefaults.standard.data(forKey: contractsKey),
           let decoded = try? JSONDecoder().decode([Contract].self, from: data) {
            contracts = decoded
        }
    }
    
    private func saveQARecords() {
        if let encoded = try? JSONEncoder().encode(qaRecords) {
            UserDefaults.standard.set(encoded, forKey: qaRecordsKey)
        }
    }
    
    private func loadQARecords() {
        if let data = UserDefaults.standard.data(forKey: qaRecordsKey),
           let decoded = try? JSONDecoder().decode([QARecord].self, from: data) {
            qaRecords = decoded
        }
    }
    
    // MARK: - 统计
    var totalContracts: Int {
        contracts.count
    }
    
    var analyzedContracts: Int {
        contracts.filter { $0.status == .completed }.count
    }
    
    var highRiskCount: Int {
        contracts.compactMap { $0.analysisResult?.riskItems }
            .flatMap { $0 }
            .filter { $0.level == .high }
            .count
    }
}
