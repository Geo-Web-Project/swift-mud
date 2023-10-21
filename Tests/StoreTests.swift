import XCTest
import SwiftData
import Web3
import Web3ContractABI
import CryptoSwift
@testable import SwiftMUD

@Model
class TestRecord: Record {
    var table: Table?
    
    @Attribute(.unique) var uniqueKey: String

    var key: Data
    var value: UInt8
    
    init(uniqueKey: String, key: Data, value: UInt8) {
        self.uniqueKey = uniqueKey
        self.key = key
        self.value = value
    }
    
    static func setRecord(modelContext: ModelContext, table: Table, values: [String : Any], blockNumber: EthereumQuantity) throws {
        guard let keys = values["keyTuple"] as? [Data] else { throw SetRecordError.invalidData }
        guard let key = try ProtocolParser.decodeStaticField(abiType: SolidityType.bytes(length: 32), data: keys[0].makeBytes()) as? Data else { throw SetRecordError.invalidNativeValue }
        
        guard let staticData = values["staticData"] as? Data else { throw SetRecordError.invalidData }
        guard let value = try ProtocolParser.decodeStaticField(abiType: SolidityType.uint8, data: staticData.makeBytes()) as? UInt8 else { throw SetRecordError.invalidNativeValue }
        
        let digest: Array<UInt8> = Array(table.namespace!.world!.uniqueKey.hexToBytes() + table.namespace!.namespaceId.hexToBytes() + table.tableName.makeBytes() + key.makeBytes())
        let uniqueKey = SHA3(variant: .keccak256).calculate(for: digest).toHexString()
        
        let latestValue = FetchDescriptor<TestRecord>(
            predicate: #Predicate { $0.uniqueKey == uniqueKey }
        )
        let results = try modelContext.fetch(latestValue)
        
        if let existingRecord = results.first {
            existingRecord.value = value
        } else {
            let record = TestRecord(uniqueKey: uniqueKey, key: key, value: value)
            record.table = table
            modelContext.insert(record)
        }
    }
    
    static func spliceStaticData(modelContext: ModelContext, table: Table, values: [String : Any], blockNumber: EthereumQuantity) throws {
        
    }
    
    static func spliceDynamicData(modelContext: ModelContext, table: Table, values: [String : Any], blockNumber: EthereumQuantity) throws {
        
    }
    
    static func deleteRecord(modelContext: ModelContext, table: Table, values: [String : Any], blockNumber: EthereumQuantity) throws {
        
    }
}

final class StoreTests: XCTestCase {
    var store: Store?
    var modelContext: ModelContext?
    
    let basicEvent: [String : Any] = [
        "tableId": Data(hex: "0x746200000000000000000000000000014f7269656e746174696f6e436f6d0000"),
        "keyTuple": [Data(hex: "0x1")],
        "staticData": Data(hexString: UInt8(10).makeBytes().toHexString(), length: 1)!
    ]
    
    func basicEvent(tableId: Data) -> [String : Any] {
        var event = basicEvent
        event["tableId"] = tableId
        return event
    }
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, allowsSave: true)
        guard let container: ModelContainer = try? ModelContainer(for: World.self, TestRecord.self, configurations: config) else {
            XCTFail("Failed to set up model container")
            return
        }
        modelContext = ModelContext(container)
        store = Store(modelContext: modelContext!)
        store?.registerRecordType(tableName: "OrientationCom", handler: TestRecord.self)
    }
    
    func testResourcesDoNotExist() async throws {
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
        
        try modelContext?.save()
                
        let worlds = try modelContext!.fetch(FetchDescriptor<World>())
        XCTAssertEqual(worlds.count, 1)
        XCTAssertEqual(worlds.first?.chainId, 420)
        XCTAssertEqual(worlds.first?.worldAddress, "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")
        
        let namespaces = try modelContext!.fetch(FetchDescriptor<Namespace>())
        XCTAssertEqual(namespaces.count, 1)
        XCTAssertEqual(namespaces.first?.world, worlds.first)
        XCTAssertEqual(namespaces.first?.namespaceId, Bytes(arrayLiteral: 0,0,0,0,0,0,0,0,0,0,0,0,0,1).toHexString())
        
        let tables = try modelContext!.fetch(FetchDescriptor<Table>())
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables.first?.namespace, namespaces.first)
        XCTAssertEqual(tables.first?.tableName, "OrientationCom")
        
        let records = try modelContext!.fetch(FetchDescriptor<TestRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.table, tables.first)
        XCTAssertEqual(records.first?.key, Data(hex: "0x1"))
        XCTAssertEqual(records.first?.value, UInt8(10))
    }
    
    func testResourcesExists() async throws {
        try store!.handleStoreSetRecordEvent(
            chainId: 420,
            worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
            event: basicEvent,
            blockNumber: EthereumQuantity(integerLiteral: 1)
        )
                
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
        
        try modelContext?.save()
        
        let worlds = try modelContext!.fetch(FetchDescriptor<World>())
        XCTAssertEqual(worlds.count, 1)
        XCTAssertEqual(worlds.first?.chainId, 420)
        XCTAssertEqual(worlds.first?.worldAddress, "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")
        
        let namespaces = try modelContext!.fetch(FetchDescriptor<Namespace>())
        XCTAssertEqual(namespaces.count, 1)
        XCTAssertEqual(namespaces.first?.world, worlds.first)
        XCTAssertEqual(namespaces.first?.namespaceId, Bytes(arrayLiteral: 0,0,0,0,0,0,0,0,0,0,0,0,0,1).toHexString())
        
        let tables = try modelContext!.fetch(FetchDescriptor<Table>())
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables.first?.namespace, namespaces.first)
        XCTAssertEqual(tables.first?.tableName, "OrientationCom")
        
        let records = try modelContext!.fetch(FetchDescriptor<TestRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.table, tables.first)
        XCTAssertEqual(records.first?.key, Data(hex: "0x1"))
        XCTAssertEqual(records.first?.value, UInt8(10))
    }
    
    func testMultipleWorlds() async throws {
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
                
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 1,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
        
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 1,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c6")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
        
        try modelContext?.save()
        
        let worlds = try modelContext!.fetch(FetchDescriptor<World>())
        XCTAssertEqual(worlds.count, 3)
        
        let namespaces = try modelContext!.fetch(FetchDescriptor<Namespace>())
        XCTAssertEqual(namespaces.count, 3)
        
        let tables = try modelContext!.fetch(FetchDescriptor<Table>())
        XCTAssertEqual(tables.count, 3)
        
        let records = try modelContext!.fetch(FetchDescriptor<TestRecord>())
        XCTAssertEqual(records.count, 3)
    }
    
    func testMultipleNamespaces() async throws {
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
                
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent(tableId: Data(hex: "0x746200000000000000000000000000114f7269656e746174696f6e436f6d0000")), // Different namespace
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
        
        try modelContext?.save()
        
        let worlds = try modelContext!.fetch(FetchDescriptor<World>())
        XCTAssertEqual(worlds.count, 1)
        
        let namespaces = try modelContext!.fetch(FetchDescriptor<Namespace>())
        XCTAssertEqual(namespaces.count, 2)
        
        let tables = try modelContext!.fetch(FetchDescriptor<Table>())
        XCTAssertEqual(tables.count, 2)
        
        let records = try modelContext!.fetch(FetchDescriptor<TestRecord>())
        XCTAssertEqual(records.count, 2)
    }
    
    func testMultipleTables() async throws {
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent,
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
                
        XCTAssertNoThrow(
            try store!.handleStoreSetRecordEvent(
                chainId: 420,
                worldAddress: EthereumAddress(hexString: "0xfF5Be16460704eFd0263dB1444Eaa216b77477c5")!,
                event: basicEvent(tableId: Data(hex: "0x746200000000000000000000000000015363616c65436f6d0000000000000000")), // Different table
                blockNumber: EthereumQuantity(integerLiteral: 1)
            )
        )
        
        try modelContext?.save()
        
        let worlds = try modelContext!.fetch(FetchDescriptor<World>())
        XCTAssertEqual(worlds.count, 1)
        
        let namespaces = try modelContext!.fetch(FetchDescriptor<Namespace>())
        XCTAssertEqual(namespaces.count, 1)
        
        let tables = try modelContext!.fetch(FetchDescriptor<Table>())
        XCTAssertEqual(tables.count, 2)
        
        let records = try modelContext!.fetch(FetchDescriptor<TestRecord>())
        XCTAssertEqual(records.count, 1)
    }
}
