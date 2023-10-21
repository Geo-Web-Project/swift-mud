//
//  World.swift
//  swift-mud
//
//  Created by codynhat on 2023-10-19.
//

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
