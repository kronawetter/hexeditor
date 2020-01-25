//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct OffsetTree {
	typealias Index = Int
	
	var root: Node? = nil

	mutating func insert(_ element: OffsetTreeElement, offset: Int) {
		if let root = root {
			if let splitResult = root.insert(element, offset: offset) {
				let newRoot = Node(pairs: [splitResult])
				newRoot.firstChild = (node: root, baseOffset: 0)
				self.root = newRoot
			}
		} else {
			let range = offset..<(offset + element.size)
			root = Node(initialElement: element, range: range)
		}
	}

	func find(offset: Int) -> (node: Node, element: OffsetTreeElement, offset: Int)? {
		guard let root = root else {
			return nil
		}

		return root.find(offset: offset)
	}

	subscript(_ offset: Int) -> OffsetTreeElement.Value? {
		guard let (_, element, index) = find(offset: offset) else {
			return nil
		}

		return element.value(for: index..<(index + 1))
	}

	mutating func clear() {
		root = nil
	}
}
