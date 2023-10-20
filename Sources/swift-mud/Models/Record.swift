//
//  Record.swift
//  swift-mud
//
//  Created by codynhat on 2023-10-19.
//


import SwiftData
import Web3
import Web3ContractABI
import Foundation

enum SetRecordError: Error {
    case invalidData
    case invalidNativeType
    case invalidNativeValue
}

protocol Record {
    var table: Table? { get set }
    var uniqueKey: String { get }
    
    static func setRecord(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
    static func spliceStaticData(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
    static func spliceDynamicData(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
    static func deleteRecord(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
}

//@Model
//class Record {
//    // Reference to table that record belongs to
//    var table: Table?
//        
//    init() {}
//}
