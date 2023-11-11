//
//  Table.swift
//  swift-mud
//
//  Created by codynhat on 2023-10-19.
//


import SwiftData
import Web3
import CryptoSwift

@Model
public final class Table {
    // Reference to namespace that table belongs to
    public var namespace: Namespace?
    
    public var tableName: String
    
    public init(tableName: String) {
        self.tableName = tableName
    }
}

extension StoreActor {
    public func getOrCreateTable(resourceId: ResourceId, namespace: Namespace) throws -> Table {
        let table = namespace.tables.first(where: { table in
            table.tableName == resourceId.name
        })
        
        if let table {
            return table
        } else {
            let newTable = Table(tableName: resourceId.name)
            modelContext.insert(newTable)
            namespace.tables.append(newTable)
            
            try modelContext.save()
            
            return newTable
        }
    }
}
