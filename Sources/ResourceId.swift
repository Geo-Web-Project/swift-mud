//
//  ResourceId.swift
//  MUDTesting
//
//  Created by codynhat on 2023-08-03.
//

import Web3

enum ResourceType: String {
    case table = "tb"
    case offchaintable = "ot"
    case namespace = "ns"
    case module = "md"
    case system = "sy"
}

struct ResourceId {
    let bytes: Bytes
    
    var type: ResourceType {
        ResourceType(rawValue: Array(bytes[0..<2]).makeString())!
    }
    var namespace: Bytes {
        Array(bytes[2..<16])
    }
    var name: String {
        Array(bytes[16..<32]).makeString()
    }
    
    init(bytes: Bytes) {
        self.bytes = bytes
    }
    
    init(type: ResourceType, namespace: Bytes, name: String) {
        var namespaceBytes = namespace
        var nameBytes = name.makeBytes()
        if namespaceBytes.count < 14 {
            for _ in 0...(14-namespaceBytes.count-1) {
                namespaceBytes.append(0)
            }
        }
        
        if nameBytes.count < 16 {
            for _ in 0...(16-nameBytes.count-1) {
                nameBytes.append(0)
            }
        }
        
        self.bytes = Array(type.rawValue.makeBytes()[0..<2] + namespaceBytes + nameBytes)
    }
}
