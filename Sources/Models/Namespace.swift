//
//  Namespace.swift
//  swift-mud
//
//  Created by codynhat on 2023-10-19.
//

import Foundation
import SwiftData
import Web3
import CryptoSwift

@Model
public final class Namespace {
    // Reference to world that namespace belongs to
    public var world: World?
    
    // bytes14 namespace
    public var namespaceId: String
        
    @Relationship(deleteRule: .cascade, inverse: \Table.namespace)
    public var tables = [Table]()
    
    public var lastSyncedBlock: UInt?
    
    public init(namespaceId: Bytes, lastSyncedBlock: UInt) {
        self.namespaceId = namespaceId.toHexString()
        self.lastSyncedBlock = lastSyncedBlock
    }
}

extension StoreActor {
    public func getOrCreateNamespace(resourceId: ResourceId, world: World, blockNumber: EthereumQuantity) throws -> Namespace {
        let namespace = world.namespaces.first(where: { namespace in
            namespace.namespaceId == resourceId.namespace.toHexString()
        })
        
        if let namespace {
            return namespace
        } else {
            let newNamespace = Namespace(namespaceId: resourceId.namespace, lastSyncedBlock: UInt(blockNumber.quantity))
            modelContext.insert(newNamespace)
            world.namespaces.append(newNamespace)
            
            try modelContext.save()
            
            return newNamespace
        }
    }
    
    public func fetchLastSyncedBlockForNamespace(namespaceId: String) throws -> UInt? {
        let lastBlockFetch = FetchDescriptor<Namespace>(
            predicate: #Predicate { $0.namespaceId == namespaceId }
        )
        let results = try modelContext.fetch(lastBlockFetch)
        let lastSyncedBlock = results.count > 0 ? results[0].lastSyncedBlock : nil
        
        return lastSyncedBlock
    }
}
