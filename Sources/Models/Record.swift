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
    
    static func setRecord(storeActor: StoreActor, table: Table, values: [String: Any], blockNumber: EthereumQuantity) async throws
    static func spliceStaticData(storeActor: StoreActor, table: Table, values: [String: Any], blockNumber: EthereumQuantity) async throws
    static func spliceDynamicData(storeActor: StoreActor, table: Table, values: [String: Any], blockNumber: EthereumQuantity) async throws
    static func deleteRecord(storeActor: StoreActor, table: Table, values: [String: Any], blockNumber: EthereumQuantity) async throws
}
