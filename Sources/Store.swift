//
//  Store.swift
//  swift-mud
//
//  Created by codynhat on 2023-07-26.
//

import Web3
import Web3ContractABI
import SwiftData
import Foundation

public class Store {
    enum StoreError: Error {
        case invalidTableId
        case unknownTableId
    }
    
    static var StoreSetRecord: SolidityEvent {
        let inputs: [SolidityEvent.Parameter] = [
            SolidityEvent.Parameter(name: "tableId", type: .bytes(length: 32), indexed: true),
            SolidityEvent.Parameter(name: "keyTuple", type: .array(type: .bytes(length: 32), length: nil), indexed: false),
            SolidityEvent.Parameter(name: "staticData", type: .bytes(length: nil), indexed: false),
            SolidityEvent.Parameter(name: "encodedLengths", type: .bytes(length: 32), indexed: false),
            SolidityEvent.Parameter(name: "dynamicData", type: .bytes(length: nil), indexed: false),
        ]
        return SolidityEvent(name: "Store_SetRecord", anonymous: false, inputs: inputs)
    }
    
    static var StoreSpliceStaticData: SolidityEvent {
        let inputs: [SolidityEvent.Parameter] = [
            SolidityEvent.Parameter(name: "tableId", type: .bytes(length: 32), indexed: true),
            SolidityEvent.Parameter(name: "keyTuple", type: .array(type: .bytes(length: 32), length: nil), indexed: false),
            SolidityEvent.Parameter(name: "start", type: .uint48, indexed: false),
            SolidityEvent.Parameter(name: "data", type: .bytes(length: nil), indexed: false),
        ]
        return SolidityEvent(name: "Store_SpliceStaticData", anonymous: false, inputs: inputs)
    }
    
    static var StoreSpliceDynamicData: SolidityEvent {
        let inputs: [SolidityEvent.Parameter] = [
            SolidityEvent.Parameter(name: "tableId", type: .bytes(length: 32), indexed: true),
            SolidityEvent.Parameter(name: "keyTuple", type: .array(type: .bytes(length: 32), length: nil), indexed: false),
            SolidityEvent.Parameter(name: "start", type: .uint48, indexed: false),
            SolidityEvent.Parameter(name: "deleteCount", type: .uint40, indexed: false),
            SolidityEvent.Parameter(name: "encodedLengths", type: .bytes(length: 32), indexed: false),
            SolidityEvent.Parameter(name: "data", type: .bytes(length: nil), indexed: false),
        ]
        return SolidityEvent(name: "Store_SpliceDynamicData", anonymous: false, inputs: inputs)
    }
    
    static var StoreDeleteRecord: SolidityEvent {
        let inputs: [SolidityEvent.Parameter] = [
            SolidityEvent.Parameter(name: "tableId", type: .bytes(length: 32), indexed: true),
            SolidityEvent.Parameter(name: "keyTuple", type: .array(type: .bytes(length: 32), length: nil), indexed: false),
        ]
        return SolidityEvent(name: "Store_DeleteRecord", anonymous: false, inputs: inputs)
    }
    
    public let storeActor: StoreActor
    var eventHandlers: [String: Record.Type] = [:]
    
    public init(storeActor: StoreActor) {
        self.storeActor = storeActor
    }
    
    public func registerRecordType(tableName: String, handler: Record.Type) {
        eventHandlers[tableName] = handler
    }
    
    func getRegisteredTableIds(namespace: Bytes) -> [ResourceId] {
        eventHandlers.keys.map { tableName in
            ResourceId(type: .table, namespace: namespace, name: tableName)
        }
    }
    
    func handleStoreSetRecordEvent(chainId: UInt, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) async throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try await storeActor.getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = try await storeActor.getOrCreateNamespace(resourceId: resourceId, world: world, blockNumber: blockNumber)
        
        // Create Table if does not exist
        let table = try await storeActor.getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try await eventHandler.setRecord(storeActor: storeActor, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    func handleStoreSpliceStaticDataEvent(chainId: UInt, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) async throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try await storeActor.getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = try await storeActor.getOrCreateNamespace(resourceId: resourceId, world: world, blockNumber: blockNumber)
        
        // Create Table if does not exist
        let table = try await storeActor.getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try await eventHandler.spliceStaticData(storeActor: storeActor, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    func handleStoreSpliceDynamicDataEvent(chainId: UInt, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) async throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try await storeActor.getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = try await storeActor.getOrCreateNamespace(resourceId: resourceId, world: world, blockNumber: blockNumber)
        
        // Create Table if does not exist
        let table = try await storeActor.getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try await eventHandler.spliceDynamicData(storeActor: storeActor, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    func handleStoreDeleteRecordEvent(chainId: UInt, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) async throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try await storeActor.getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = try await storeActor.getOrCreateNamespace(resourceId: resourceId, world: world, blockNumber: blockNumber)
        
        // Create Table if does not exist
        let table = try await storeActor.getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try await eventHandler.deleteRecord(storeActor: storeActor, table: table, values: event, blockNumber: blockNumber)
        }
    }
}
