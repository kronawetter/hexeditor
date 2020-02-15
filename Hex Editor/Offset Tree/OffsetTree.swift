//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

/*struct*/ class OffsetTree<Value: Collection> {
	var root: Node? = nil

	/*mutating*/ func insert<T: OffsetTreeElement>(_ element: T, offset: Int) where T.Value == Value {
		let typeErasedElement = AnyOffsetTreeElement.make(element)

		if root != nil {
			if let pairSplittingResult = root!.insert(typeErasedElement, offset: offset) {
				let newRoot = Node(pairs: [pairSplittingResult])
				newRoot.firstChild = (node: root!, baseOffset: 0)
				newRoot.isLeaf = false
				root = newRoot
			}
		} else {
			let range = offset..<(offset + element.size)
			root = Node(initialElement: typeErasedElement, range: range)
		}
	}

	/*mutating*/ func split(at offset: Int) {
		if let newElement = root?.split(at: offset) {
			insert(newElement, offset: offset)
		}
	}

	/*mutating*/ func remove(at offset: Int) {
		_ = root?.remove(at: offset)

		if let root = root {
			if !root.isLeaf {
				//print("Rebalancing of root")
				root.rebalance(index: -1)
			}

			// wrong -> only works when merged node is first child
			if root.pairs.isEmpty {
				self.root = root.firstChild?.node
			}
		}
	}

	func find(offset: Int) -> (node: Node, pairIndex: Int, offset: Int)? {
		return root?.find(offset: offset)
	}

	func value(at offset: Int) -> Value.Element? {
		guard let (node, pairIndex, index) = find(offset: offset) else {
			return nil
		}

		return node.pairs[pairIndex].element.value(for: index..<(index + 1))?.first
	}

	subscript(_ offset: Int) -> Value.Element? {
		return value(at: offset)
	}

	/*mutating*/ func clear() {
		root = nil
	}
}

extension OffsetTree {
	struct Iterator: IteratorProtocol {
		private let offsetTree: OffsetTree
		private var offset: Int

		init(_ offsetTree: OffsetTree, at offset: Int) {
			self.offsetTree = offsetTree
			self.offset = offset
		}

		mutating func next() -> Value.Element? {
			defer {
				offset += 1
			}

			return offsetTree.value(at: offset)
		}
	}

	func iterator(startingAt offset: Int) -> OffsetTree.Iterator {
		Iterator(self, at: offset)
	}
}
