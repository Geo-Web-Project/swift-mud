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
    public var world: World?
    
    // bytes14 namespace
    public var namespaceId: String
    
    @Relationship(deleteRule: .cascade, inverse: \Table.namespace)
    public var tables = [Table]()
    
    public init(namespaceId: Bytes) {
        self.namespaceId = namespaceId.toHexString()
    }
}

extension StoreActor {
    public func getOrCreateNamespace(resourceId: ResourceId, world: World) throws -> Namespace {
        let namespace = world.namespaces.first(where: { namespace in
            namespace.namespaceId == resourceId.namespace.toHexString()
        })
        
        if let namespace {
            return namespace
        } else {
            let newNamespace = Namespace(namespaceId: resourceId.namespace)
            modelContext.insert(newNamespace)
            world.namespaces.append(newNamespace)
            
            try modelContext.save()
            
            return newNamespace
        }
    }
}
