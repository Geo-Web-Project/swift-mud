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
final class World {
    var chainId: UInt64
    var worldAddress: String
    var lastSyncedBlock: UInt
    
    // keccak256(chainId + worldAddress)
    @Attribute(.unique) var uniqueKey: String
    
    @Relationship(deleteRule: .cascade, inverse: \Namespace.world)
    var namespaces = [Namespace]()
    
    init(chainId: UInt64, worldAddress: EthereumAddress, lastSyncedBlock: UInt) {
        self.chainId = chainId
        self.worldAddress = worldAddress.hex(eip55: true)
        self.lastSyncedBlock = lastSyncedBlock
        
        let digest: Array<UInt8> = Array(chainId.makeBytes() + (try! worldAddress.makeBytes()))
        self.uniqueKey = SHA3(variant: .keccak256).calculate(for: digest).toHexString()
    }
}
