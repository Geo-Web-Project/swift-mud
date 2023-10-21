//
//  Namespace.swift
//  swift-mud
//
//  Created by codynhat on 2023-10-19.
//


import SwiftData
import Web3
import CryptoSwift

@Model
public final class Namespace {
    // Reference to world that namespace belongs to
    var world: World?
    
    // bytes14 namespace
    var namespaceId: String
    
    @Relationship(deleteRule: .cascade, inverse: \Table.namespace)
    var tables = [Table]()
    
    init(namespaceId: Bytes) {
        self.namespaceId = namespaceId.toHexString()
    }
}
