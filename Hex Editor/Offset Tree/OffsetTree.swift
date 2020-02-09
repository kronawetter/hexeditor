//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

/*struct*/ class OffsetTree {
	typealias Index = Int
	
	var root: Node? = nil

	/*mutating*/ func insert(_ element: OffsetTreeElement, offset: Int) {
		if root != nil {
			if let pairSplittingResult = root!.insert(element, offset: offset) {
				let newRoot = Node(pairs: [pairSplittingResult])
				newRoot.firstChild = (node: root!, baseOffset: 0)
				newRoot.isLeaf = false
				root = newRoot
			}
		} else {
			let range = offset..<(offset + element.size)
			root = Node(initialElement: element, range: range)
		}
	}

	/*mutating*/ func split(at offset: Int) {
		if let newElement = root?.split(at: offset) {
			insert(newElement, offset: offset)
		}
	}

	/*mutating*/ func remove(at offset: Int) {
		_ = root?.remove(at: offset)

		if let root = root, root.pairs.isEmpty {
			// wrong -> only works when merged node is first child
			self.root = root.firstChild?.node
		}
	}

	func find(offset: Int) -> (node: Node, pairIndex: Int, offset: Int)? {
		return root?.find(offset: offset)
	}

	subscript(_ offset: Int) -> OffsetTreeElement.Value? {
		guard let (node, pairIndex, index) = find(offset: offset) else {
			return nil
		}

		return node.pairs[pairIndex].element.value(for: index..<(index + 1))
	}

	/*mutating*/ func clear() {
		root = nil
	}
}
