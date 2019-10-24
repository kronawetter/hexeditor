//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct OffsetTree<ElementStorage: OffsetTreeElementStorage> {
	typealias Element = ElementStorage.Element
	
	var root: Node? = nil

	mutating func insert(_ element: Element, offset: Int) {
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

	subscript(_ offset: Int) -> Element? {
		guard let root = root else {
			return nil
		}

		return root.find(offset: offset)
	}

	mutating func clear() {
		root = nil
	}
}
