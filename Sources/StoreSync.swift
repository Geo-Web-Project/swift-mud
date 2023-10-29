//
//  StoreSync.swift
//  swift-mud
//
//  Created by codynhat on 2023-08-08.
//

import Foundation
import SwiftData
import Web3
import Web3ContractABI

public class StoreSync {
    enum StoreSyncError: Error {
        case chainIdNotFound
    }
    
    private let modelContext: ModelContext
    private let web3: Web3
    private let store: Store
    private static let storeSetRecordTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreSetRecord))
    private static let storeSpliceStaticDataTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreSpliceStaticData))
    private static let storeSpliceDynamicDataTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreSpliceDynamicData))
    private static let storeDeleteRecordTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreDeleteRecord))
    private static let allStoreTopics = [storeSetRecordTopic, storeSpliceStaticDataTopic, storeSpliceDynamicDataTopic, storeDeleteRecordTopic]

    public init(modelContext: ModelContext, web3: Web3, store: Store) {
        self.modelContext = modelContext
        self.web3 = web3
        self.store = store
    }
    
    public func syncLogs(worldAddress: EthereumAddress, namespace: Bytes) async throws {
        let addressStr = worldAddress.hex(eip55: true)
        let lastBlockFetch = FetchDescriptor<World>(
            predicate: #Predicate { $0.worldAddress == addressStr }
        )
        let results = try modelContext.fetch(lastBlockFetch)
        let lastSyncedBlock = results.count > 0 ? results[0].lastSyncedBlock : nil
        var fromBlock: EthereumQuantityTag = .earliest
        if let lastSyncedBlock {
            fromBlock = .block(BigUInt(lastSyncedBlock))
        }
        
        let chainId = try await getChainId()
        let tableIds = self.store.getRegisteredTableIds(namespace: namespace).map{ EthereumData($0.bytes) }
        
        return try await withCheckedThrowingContinuation { continuation in
            web3.eth.getLogs(addresses: [worldAddress], topics: [StoreSync.allStoreTopics, tableIds], fromBlock: fromBlock, toBlock: .latest, response: { resp in
                if let error = resp.error {
                    return continuation.resume(throwing: error)
                }
                guard let logs = resp.result else { return continuation.resume() }
                
                for log in logs {
                    self.handleLog(chainId: chainId, log: log)
                }
                
                return continuation.resume()
            })
        }
    }
    
    public func subscribeToLogs(worldAddress: EthereumAddress, namespace: Bytes) async throws {
        let chainId = try await getChainId()
        let tableIds = self.store.getRegisteredTableIds(namespace: namespace).map{ EthereumData($0.bytes) }

        try web3.eth.subscribeToLogs(addresses: [worldAddress], topics: [StoreSync.allStoreTopics, tableIds]) {_ in } onEvent: { resp in
            if let res = resp.result {
                self.handleLog(chainId: chainId, log: res)
            }
        }
    }
    
    public func handleLog(chainId: UInt, log: EthereumLogObject) {
        do {
            switch log.topics[0] {
            case StoreSync.storeSetRecordTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreSetRecord, from: log)
                try self.store.handleStoreSetRecordEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber!)
            case StoreSync.storeSpliceStaticDataTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreSpliceStaticData, from: log)
                try self.store.handleStoreSpliceStaticDataEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber!)
            case StoreSync.storeSpliceDynamicDataTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreSpliceDynamicData, from: log)
                try self.store.handleStoreSpliceDynamicDataEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber!)
            case StoreSync.storeDeleteRecordTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreDeleteRecord, from: log)
                try self.store.handleStoreDeleteRecordEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber!)
            default:
                return
            }
        } catch {
           print(error)
        }
    }
    
    public func getChainId() async throws -> UInt {
        let chainIdValue: EthereumQuantity? = try await withCheckedThrowingContinuation { continuation in
            let req = BasicRPCRequest(id: web3.properties.rpcId, jsonrpc: Web3.jsonrpc, method: "eth_chainId", params: [])
            web3.provider.send(request: req) { (resp: Web3Response<EthereumQuantity>) in
                if let error = resp.error {
                    return continuation.resume(throwing: error)
                }
                
                return continuation.resume(returning: resp.result)
            }
        }
        
        
        guard let quantity = chainIdValue?.quantity else { throw StoreSyncError.chainIdNotFound }
        let chainId = UInt(quantity)
        
        return chainId
    }
}
