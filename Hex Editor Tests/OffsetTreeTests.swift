//
//  OffsetTreeTests.swift
//  Hex Editor Tests
//
//  Created by Philip Kronawetter on 2020-02-08.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import XCTest

struct Element: OffsetTreeElement {
	typealias Value = Data
	var data = Data()

	var size: Int {
		data.count
	}

	func value(for range: Range<Int>) -> Self.Value? {
		return data[range]
	}

	mutating func replace(in range: Range<Int>, with value: Self.Value) -> Bool {
		data.replaceSubrange(range, with: value)
		return true
	}

	mutating func split(at offset: Int) -> Element {
		let new = data.dropFirst(offset)
		data.removeLast(data.count - offset)
		return Self(data: Data(new))
	}
}

class OffsetTreeTests: XCTestCase {
	let offsetTree = OffsetTree()

    override func setUp() {
		/*
						┌────────────────────────┬────────────────────────┐
						│           08           │           17           │
						└────────────────────────┴────────────────────────┘
					  ╱ +0                       │ +8                       ╲ + 17
			  ┌──────┬──────┐             ┌──────┬──────┐                ┌──────┐
			  │  02  │  05  │             │  03  │  06  │                │  03  │
			  └──────┴──────┘             └──────┴──────┘                └──────┘
			╱ +0     │ +2    ╲ +5       ╱ +0     │ +3    ╲ +6          ╱ +0      ╲ +3
		┌──┬──┐   ┌──┬──┐  ┌──┬──┐  ┌──┬──┐   ┌──┬──┐  ┌──┬──┐     ┌──┬──┐      ┌──┐
		│00│01│   │01│02│  │01│02│  │01│02│   │01│02│  │01│02│     │01│02│      │01│
		└──┴──┘   └──┴──┘  └──┴──┘  └──┴──┘   └──┴──┘  └──┴──┘     └──┴──┘      └──┘
		*/
		for i in 0..<22 {
			offsetTree.insert(Element(data: Data([UInt8(i)])), offset: i)
		}
    }

	override func tearDown() {
		for i in 0..<22 {
			if offsetTree[i] == nil {
				print("Reading tree at index \(i) returned nil")
			}
		}
	}

    func testRemoveFromLeafNodeWithTwoPairs() {
		offsetTree.remove(at: 3)

		let rootNode = offsetTree.root!
		let firstChildNodeOfRoot = rootNode.firstChild!.node
		let childNodeWithDeletedElement = firstChildNodeOfRoot.pairs[0].child!.node

		XCTAssertTrue(childNodeWithDeletedElement.isLeaf)
		XCTAssertEqual(childNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(childNodeWithDeletedElement.pairs[0].range, 1..<2)
		XCTAssertEqual((childNodeWithDeletedElement.pairs[0].element as! Element).data[0], 4)

		XCTAssertFalse(firstChildNodeOfRoot.isLeaf)
		XCTAssertEqual(firstChildNodeOfRoot.pairs.count, 2)
		XCTAssertEqual(firstChildNodeOfRoot.pairs[0].range, 2..<3)
		XCTAssertEqual(firstChildNodeOfRoot.pairs[1].range, 4..<5)
		XCTAssertEqual((firstChildNodeOfRoot.pairs[1].element as! Element).data[0], 5)
		XCTAssertEqual(firstChildNodeOfRoot.pairs[1].child!.baseOffset, 4)

		XCTAssertFalse(rootNode.isLeaf)
		XCTAssertEqual(rootNode.pairs.count, 2)
		XCTAssertEqual(rootNode.pairs[0].range, 7..<8)
		XCTAssertEqual(rootNode.pairs[0].child!.baseOffset, 7)
		XCTAssertEqual(rootNode.pairs[1].range, 16..<17)
		XCTAssertEqual(rootNode.pairs[1].child!.baseOffset, 16)
    }

	func testRemoveFromLeafNodeWithOnePairRotateRight() {
		offsetTree.remove(at: 21)

		let rootNode = offsetTree.root!
		let lastChildOfRootNode = rootNode.pairs.last!.child!.node
		let firstChildOfLastChildOfRootNode = lastChildOfRootNode.firstChild!.node
		let lastChildOfLastChildOfRootNode = lastChildOfRootNode.pairs.last!.child!.node

		XCTAssertEqual((lastChildOfRootNode.pairs[0].element as! Element).data[0], 19)
		XCTAssertEqual((firstChildOfLastChildOfRootNode.pairs[0].element as! Element).data[0], 18)
		XCTAssertEqual((lastChildOfLastChildOfRootNode.pairs[0].element as! Element).data[0], 20)
		XCTAssertEqual(offsetTree[19]![0], 19)
		XCTAssertEqual(offsetTree[20]![0], 20)
		XCTAssertNil(offsetTree[21])
	}

	func testRemoveRotateLeft() {
		offsetTree.remove(at: 9)

		let rootNode = offsetTree.root!
		let secondChildOfRootNode = rootNode.pairs[0].child!.node
		let childNodeWithDeletedElement = secondChildOfRootNode.firstChild!.node
		let sibblingNodeOfChildNodeWithDeletedElement = secondChildOfRootNode.pairs[0].child!.node

		XCTAssertEqual(secondChildOfRootNode.pairs.count, 2)
		XCTAssertEqual(childNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(sibblingNodeOfChildNodeWithDeletedElement.pairs.count, 2)
		XCTAssertEqual(offsetTree[8]![0], 8)
		XCTAssertEqual(offsetTree[9]![0], 10)
		XCTAssertEqual(offsetTree[10]![0], 11)

		offsetTree.remove(at: 9)
		
		XCTAssertEqual(secondChildOfRootNode.pairs.count, 2)
		XCTAssertEqual(childNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(sibblingNodeOfChildNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(offsetTree[8]![0], 8)
		XCTAssertEqual(offsetTree[9]![0], 11)
		XCTAssertEqual(offsetTree[10]![0], 12)
	}

	func testRemoveRotateLeft2() {
		offsetTree.remove(at: 12)

		let rootNode = offsetTree.root!
		let secondChildOfRootNode = rootNode.pairs[0].child!.node
		let childNodeWithDeletedElement = secondChildOfRootNode.pairs[0].child!.node
		let sibblingNodeOfChildNodeWithDeletedElement = secondChildOfRootNode.pairs[1].child!.node

		XCTAssertEqual(secondChildOfRootNode.pairs.count, 2)
		XCTAssertEqual(childNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(sibblingNodeOfChildNodeWithDeletedElement.pairs.count, 2)
		XCTAssertEqual(offsetTree[11]![0], 11)
		XCTAssertEqual(offsetTree[12]![0], 13)
		XCTAssertEqual(offsetTree[13]![0], 14)

		offsetTree.remove(at: 12)

		XCTAssertEqual(secondChildOfRootNode.pairs.count, 2)
		XCTAssertEqual(childNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(sibblingNodeOfChildNodeWithDeletedElement.pairs.count, 1)
		XCTAssertEqual(offsetTree[11]![0], 11)
		XCTAssertEqual(offsetTree[12]![0], 14)
		XCTAssertEqual(offsetTree[13]![0], 15)
	}

	func testRemoveMerge() {
		offsetTree.remove(at: 18)

		XCTAssertEqual(offsetTree[17]![0], 17)
		XCTAssertEqual(offsetTree[18]![0], 19)
		XCTAssertEqual(offsetTree[19]![0], 20)

		offsetTree.remove(at: 18)

		XCTAssertEqual(offsetTree[17]![0], 17)
		XCTAssertEqual(offsetTree[18]![0], 20)
		XCTAssertEqual(offsetTree[19]![0], 21)
	}

	func testRemoveMergeNoFirstChild() {
		offsetTree.remove(at: 12)
		offsetTree.remove(at: 14)
		
		offsetTree.remove(at: 14)

		XCTAssertEqual(offsetTree[11]![0], 11)
		XCTAssertEqual(offsetTree[12]![0], 13)
		XCTAssertEqual(offsetTree[13]![0], 14)
		XCTAssertEqual(offsetTree[14]![0], 17)
		XCTAssertEqual(offsetTree[15]![0], 18)
	}

	func testRemoveRootPair() {
		offsetTree.remove(at: 8)

		XCTAssertEqual(offsetTree[7]![0], 7)
		XCTAssertEqual(offsetTree[8]![0], 9)
		XCTAssertEqual(offsetTree[9]![0], 10)
	}

	func testRemoveAllElements() {
		for i in 0..<22 {
			print("---")
			offsetTree.remove(at: 0)

			for j in 0..<(22 - i - 1) {
				XCTAssertEqual(offsetTree[j]![0], UInt8(j + i + 1))
			}

			for j in (22 - i - 1)..<22 {
				XCTAssertNil(offsetTree[j])
			}
		}
	}

	func testRemoveAllElements2() {
		for i in 0..<22 {
			print("---")
			offsetTree.remove(at: 22 - i - 1)

			for j in 0..<(22 - i - 1) {
				XCTAssertEqual(offsetTree[j]![0], UInt8(j))
			}

			for j in (22 - i - 1)..<22 {
				XCTAssertNil(offsetTree[j])
			}
		}
	}
}
