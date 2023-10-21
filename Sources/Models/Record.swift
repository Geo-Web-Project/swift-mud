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

public enum SetRecordError: Error {
    case invalidData
    case invalidNativeType
    case invalidNativeValue
}

public protocol Record {
    var table: Table? { get set }
    var uniqueKey: String { get }
    
    static func setRecord(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
    static func spliceStaticData(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
    static func spliceDynamicData(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
    static func deleteRecord(modelContext: ModelContext, table: Table, values: [String: Any], blockNumber: EthereumQuantity) throws
}
