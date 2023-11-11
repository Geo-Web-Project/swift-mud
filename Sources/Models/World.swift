//
//  World.swift
//  swift-mud
//
//  Created by codynhat on 2023-10-19.
//

import Foundation
import SwiftData
import Web3
import CryptoSwift

@Model
public final class World {
    public var chainId: UInt
    public var worldAddress: String
    public var lastSyncedBlock: UInt
    
    // keccak256(chainId + worldAddress)
    @Attribute(.unique) public var uniqueKey: String
    
    @Relationship(deleteRule: .cascade, inverse: \Namespace.world)
    public var namespaces = [Namespace]()
    
    public init(chainId: UInt, worldAddress: EthereumAddress, lastSyncedBlock: UInt) {
        self.chainId = chainId
        self.worldAddress = worldAddress.hex(eip55: true)
        self.lastSyncedBlock = lastSyncedBlock
        
        let digest: Array<UInt8> = Array(chainId.makeBytes() + (try! worldAddress.makeBytes()))
        self.uniqueKey = SHA3(variant: .keccak256).calculate(for: digest).toHexString()
    }
}

extension StoreActor {
    public func getOrCreateWorld(chainId: UInt, worldAddress: EthereumAddress, blockNumber: EthereumQuantity) throws -> World {
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
        
        try modelContext.save()
        
        return world
    }
    
    public func fetchLastSyncedBlock(worldAddress: EthereumAddress) throws -> UInt? {
        let addressStr = worldAddress.hex(eip55: true)
        let lastBlockFetch = FetchDescriptor<World>(
            predicate: #Predicate { $0.worldAddress == addressStr }
        )
        let results = try modelContext.fetch(lastBlockFetch)
        let lastSyncedBlock = results.count > 0 ? results[0].lastSyncedBlock : nil
        
        return lastSyncedBlock
    }
    
    public func updateWorld(world: World, chainId: UInt, worldAddress: EthereumAddress, lastSyncedBlock: UInt) throws {
        world.chainId = chainId
        world.worldAddress =  worldAddress.hex(eip55: true)
        world.lastSyncedBlock = lastSyncedBlock
        try modelContext.save()
    }
}
