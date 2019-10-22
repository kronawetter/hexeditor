//
//  HexEditorTests.swift
//  HexEditorTests
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import XCTest
@testable import HexEditor

class HexEditorTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let string = "🐱abc🐶"
		var data = Array(string.utf8)
		data[0] = 0

		var manager = AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.LittleEndian, [UTF8.CodeUnit]>>(dataSource: data)
		manager.create(for: 2..<data.endIndex - 4)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
