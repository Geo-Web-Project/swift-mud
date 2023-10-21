//
//  ResourceIdTests.swift
//
//
//  Created by codynhat on 2023-10-20.
//

import XCTest
import Web3
@testable import SwiftMUD

final class ResourceIdTests: XCTestCase {
    func testHexToResourceId() throws {
        let rawTableId = Data(hex: "0x746200000000000000000000000000014f7269656e746174696f6e436f6d0000")
        
        let resourceId = ResourceId(bytes: rawTableId.makeBytes())
        XCTAssertEqual(resourceId.type, .table)
        XCTAssertEqual(resourceId.namespace, Bytes(arrayLiteral: 0,0,0,0,0,0,0,0,0,0,0,0,0,1))
        XCTAssertEqual(resourceId.name, "OrientationCom")
    }
    
    func testResourceIdFromParts() {        
        let resourceId = ResourceId(type: .table, namespace: Bytes(arrayLiteral: 0,0,0,0,0,0,0,0,0,0,0,0,0,1), name: "OrientationCom")
        XCTAssertEqual(resourceId.type, .table)
        XCTAssertEqual(resourceId.namespace, Bytes(arrayLiteral: 0,0,0,0,0,0,0,0,0,0,0,0,0,1))
        XCTAssertEqual(resourceId.name, "OrientationCom")
    }
}
