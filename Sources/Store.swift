//
//  MUDStore.swift
//  MUDTesting
//
//  Created by codynhat on 2023-07-26.
//

import Web3
import Web3ContractABI
import SwiftData
import Foundation

class Store {
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
    
    let modelContext: ModelContext
    var eventHandlers: [String: Record.Type] = [:]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func registerRecordType(tableName: String, handler: Record.Type) {
        eventHandlers[tableName] = handler
    }
    
    func getRegisteredTableIds(namespace: Bytes) -> [ResourceId] {
        eventHandlers.keys.map { tableName in
            ResourceId(type: .table, namespace: namespace, name: tableName)
        }
    }
    
    func handleStoreSetRecordEvent(chainId: UInt64, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = getOrCreateNamespace(resourceId: resourceId, world: world)
        
        // Create Table if does not exist
        let table = getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try eventHandler.setRecord(modelContext: modelContext, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    func handleStoreSpliceStaticDataEvent(chainId: UInt64, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = getOrCreateNamespace(resourceId: resourceId, world: world)
        
        // Create Table if does not exist
        let table = getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try eventHandler.spliceStaticData(modelContext: modelContext, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    func handleStoreSpliceDynamicDataEvent(chainId: UInt64, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = getOrCreateNamespace(resourceId: resourceId, world: world)
        
        // Create Table if does not exist
        let table = getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try eventHandler.spliceDynamicData(modelContext: modelContext, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    func handleStoreDeleteRecordEvent(chainId: UInt64, worldAddress: EthereumAddress, event: [String: Any], blockNumber: EthereumQuantity) throws {
        guard let tableIdData = event["tableId"] as? Data else { throw StoreError.invalidTableId }
        let resourceId = ResourceId(bytes: tableIdData.makeBytes())
        guard resourceId.type == .table else { throw StoreError.invalidTableId }
        
        // Create World if does not exist
        let world = try getOrCreateWorld(chainId: chainId, worldAddress: worldAddress, blockNumber: blockNumber)
        
        // Create Namespace if does not exist
        let namespace = getOrCreateNamespace(resourceId: resourceId, world: world)
        
        // Create Table if does not exist
        let table = getOrCreateTable(resourceId: resourceId, namespace: namespace)
        
        if let eventHandler = eventHandlers[table.tableName] {
            try eventHandler.deleteRecord(modelContext: modelContext, table: table, values: event, blockNumber: blockNumber)
        }
    }
    
    
    private func getOrCreateWorld(chainId: UInt64, worldAddress: EthereumAddress, blockNumber: EthereumQuantity) throws -> World {
        let addressStr = worldAddress.hex(eip55: true)
        let worldPredicate = FetchDescriptor<World>(
            predicate: #Predicate { $0.chainId == chainId && $0.worldAddress == addressStr }
        )
        let worlds = try modelContext.fetch(worldPredicate)
        var world: World
        if worlds.first != nil {
            world = worlds.first!
            world.lastSyncedBlock = UInt(blockNumber.quantity)
        } else {
            world = World(chainId: chainId, worldAddress: worldAddress, lastSyncedBlock: UInt(blockNumber.quantity))
            modelContext.insert(world)
        }
        
        return world
    }
    
    private func getOrCreateNamespace(resourceId: ResourceId, world: World) -> Namespace {
        let namespace = world.namespaces.first(where: { namespace in
            namespace.namespaceId == resourceId.namespace.toHexString()
        })
        
        if let namespace {
            return namespace
        } else {
            let newNamespace = Namespace(namespaceId: resourceId.namespace)
            modelContext.insert(newNamespace)
            world.namespaces.append(newNamespace)
            return newNamespace
        }
    }
    
    private func getOrCreateTable(resourceId: ResourceId, namespace: Namespace) -> Table {
        let table = namespace.tables.first(where: { table in
            table.tableName == resourceId.name
        })
        
        if let table {
            return table
        } else {
            let newTable = Table(tableName: resourceId.name)
            modelContext.insert(newTable)
            namespace.tables.append(newTable)
            return newTable
        }
    }
}
