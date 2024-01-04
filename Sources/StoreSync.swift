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
    
    private let web3: Web3
    private let store: Store
    private static let storeSetRecordTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreSetRecord))
    private static let storeSpliceStaticDataTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreSpliceStaticData))
    private static let storeSpliceDynamicDataTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreSpliceDynamicData))
    private static let storeDeleteRecordTopic = try! EthereumData.string(ABI.encodeEventSignature(Store.StoreDeleteRecord))
    private static let allStoreTopics = [storeSetRecordTopic, storeSpliceStaticDataTopic, storeSpliceDynamicDataTopic, storeDeleteRecordTopic]

    public init(web3: Web3, store: Store) {
        self.web3 = web3
        self.store = store
    }
    
    public func syncLogs(worldAddress: EthereumAddress, namespace: Bytes) async throws {
        let lastSyncedBlock = try await store.storeActor.fetchLastSyncedBlockForNamespace(namespaceId: namespace.toHexString())
        var fromBlock: EthereumQuantityTag = .earliest
        if let lastSyncedBlock {
            fromBlock = .block(BigUInt(lastSyncedBlock))
        }
        
        let chainId = try await getChainId()
        let tableIds = self.store.getRegisteredTableIds(namespace: namespace).map{ EthereumData($0.bytes) }
        
        let logs: [EthereumLogObject] = try await withCheckedThrowingContinuation { continuation in
            web3.eth.getLogs(addresses: [worldAddress], topics: [StoreSync.allStoreTopics, tableIds], fromBlock: fromBlock, toBlock: .latest, response: { resp in
                if let error = resp.error {
                    return continuation.resume(throwing: error)
                }
                guard let logs = resp.result else { return continuation.resume(returning: []) }
                
                return continuation.resume(returning: logs)
            })
        }
        
        for log in logs {
            await self.handleLog(chainId: chainId, log: log)
        }
    }
    
    public func subscribeToLogs(worldAddress: EthereumAddress, namespace: Bytes) async throws {
        let chainId = try await getChainId()
        let tableIds = self.store.getRegisteredTableIds(namespace: namespace).map{ EthereumData($0.bytes) }
        
        try web3.eth.subscribeToLogs(addresses: [worldAddress], topics: [StoreSync.allStoreTopics, tableIds]) {_ in } onEvent: { resp in
            if let res = resp.result {
                Task.detached {
                    await self.handleLog(chainId: chainId, log: res)
                }
            }
        }
    }
    
    public func handleLog(chainId: UInt, log: EthereumLogObject) async {
        do {
            switch log.topics[0] {
            case StoreSync.storeSetRecordTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreSetRecord, from: log)
                try await self.store.handleStoreSetRecordEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber ?? EthereumQuantity(quantity: 0))
            case StoreSync.storeSpliceStaticDataTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreSpliceStaticData, from: log)
                try await self.store.handleStoreSpliceStaticDataEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber ?? EthereumQuantity(quantity: 0))
            case StoreSync.storeSpliceDynamicDataTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreSpliceDynamicData, from: log)
                try await self.store.handleStoreSpliceDynamicDataEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber ?? EthereumQuantity(quantity: 0))
            case StoreSync.storeDeleteRecordTopic:
                let event = try ABIDecoder.decodeEvent(Store.StoreDeleteRecord, from: log)
                try await self.store.handleStoreDeleteRecordEvent(chainId: chainId, worldAddress: log.address, event: event, blockNumber: log.blockNumber ?? EthereumQuantity(quantity: 0))
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
