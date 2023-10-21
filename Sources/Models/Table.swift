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
    var namespace: Namespace?
    
    var tableName: String
    
    init(tableName: String) {
        self.tableName = tableName
    }
}
