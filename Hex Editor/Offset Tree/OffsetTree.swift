//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct OffsetTree<ElementStorage: OffsetTreeElementStorage> {
	typealias Element = ElementStorage.Element
	typealias Elements = ElementStorage.Elements
	typealias Index = Int
	
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

	mutating func insert(_ elements: Elements, offset: Int) {
		// TODO: Add support for inserting multiple elements when tree is non-empty
		precondition(root == nil)

		let range = offset..<(offset + elements.reduce(0) { $0 + $1.size }) // TODO: Inefficient in case of constant sized elements
		root = Node(initialElements: elements, range: range)
	}

	func find(offset: Int) -> (node: Node, elementStorage: ElementStorage, offset: Int)? {
		guard let root = root else {
			return nil
		}

		return root.find(offset: offset)
	}

	subscript(_ offset: Int) -> Element? {
		guard let (_, elementStorage, index) = find(offset: offset) else {
			return nil
		}

		return elementStorage[index]
	}

	mutating func clear() {
		root = nil
	}
}

extension OffsetTree {
	func iterator(for offset: Index) -> AnyIterator<Element> {
		let iterator = Iterator(tree: self, currentOffset: offset)

		return AnyIterator(iterator)
	}

	struct Iterator: IteratorProtocol {
		let tree: OffsetTree
		var currentOffset: Int

		mutating func next() -> Element? {
			guard let (_, elementStorage, index) = tree.find(offset: currentOffset), let element = elementStorage[index] else {
				return nil
			}

			currentOffset += element.size
			return element
		}
	}
}

/*extension OffsetTree: FileAccessor where ElementStorage == LinearOffsetTreeElementStorage<UInt8> {
	func iterator<ReturnedElement: FixedWidthInteger>(for offset: Index) -> AnyIterator<ReturnedElement> {
		let bytesPerWord = MemoryLayout<ReturnedElement>.stride

		precondition(offset.isMultiple(of: bytesPerWord))

		let iterator = FileAccessorIterator<ReturnedElement>(tree: self, currentOffset: offset / bytesPerWord)

		return AnyIterator(iterator)
	}

	struct FileAccessorIterator<ReturnedElement: FixedWidthInteger>: IteratorProtocol {
		let tree: OffsetTree
		var currentOffset: Int

		mutating func next() -> ReturnedElement? {
			let bytesPerWord = MemoryLayout<ReturnedElement>.stride

			guard let (_, elementStorage, index) = tree.find(offset: currentOffset) else {
				return nil
			}

			currentOffset += bytesPerWord

			return elementStorage.elements.withUnsafeBytes {
				return $0.bindMemory(to: ReturnedElement.self)
			} [index / bytesPerWord]
		}
	}
}*/

extension OffsetTree: FileAccessor where ElementStorage == DataOffsetTreeElementStorage {
	func iterator<ReturnedElement: FixedWidthInteger>(for offset: Index) -> AnyIterator<ReturnedElement> {
		let bytesPerWord = MemoryLayout<ReturnedElement>.stride

		precondition(offset.isMultiple(of: bytesPerWord))

		let iterator = FileAccessorIterator<ReturnedElement>(tree: self, currentOffset: offset / bytesPerWord)

		return AnyIterator(iterator)
	}

	struct FileAccessorIterator<ReturnedElement: FixedWidthInteger>: IteratorProtocol {
		let tree: OffsetTree
		var currentOffset: Int

		mutating func next() -> ReturnedElement? {
			let bytesPerWord = MemoryLayout<ReturnedElement>.stride

			guard let (_, elementStorage, index) = tree.find(offset: currentOffset) else {
				return nil
			}

			currentOffset += bytesPerWord

			return elementStorage.data.withUnsafeBytes {
				return $0.bindMemory(to: ReturnedElement.self)
			} [index / bytesPerWord]
		}
	}
}
