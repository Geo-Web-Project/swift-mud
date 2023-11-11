//
//  ResourceId.swift
//  swift-mud
//
//  Created by codynhat on 2023-08-03.
//

import Web3

public enum ResourceType: String {
    case table = "tb"
    case offchaintable = "ot"
    case namespace = "ns"
    case module = "md"
    case system = "sy"
}

public struct ResourceId {
    public let bytes: Bytes
    
    public var type: ResourceType {
        ResourceType(rawValue: Array(bytes[0..<2]).makeString())!
    }
    public var namespace: Bytes {
        Array(bytes[2..<16])
    }
    public var name: String {
        Array(bytes[16..<32]).makeString()
    }
    
    public init(bytes: Bytes) {
        self.bytes = bytes
    }
    
    public init(type: ResourceType, namespace: Bytes, name: String) {
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
