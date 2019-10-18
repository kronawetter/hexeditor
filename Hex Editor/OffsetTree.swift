//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-15.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

struct OffsetTree<Value> {
	typealias Offset = Int
	
	/*struct Element {
		let offset: Offset
		let value: Value
	}*/
	
	class Node {
		struct Element {
			let value: Value
			let size: Offset
		}
		
		var offset: Offset
		var size: Offset
		var elements: [Element]
		var left: Node?
		var right: Node?
		
		init(offset: Offset, elements: [Element], left: Node? = nil, right: Node? = nil) {
			self.offset = offset
			self.elements = elements
			self.size = elements.reduce(0, { (result, element) -> Offset in
				return result + element.size
			})
			self.left = left
			self.right = right
		}
		
		var range: Range<Offset> {
			return offset..<(offset + size)
		}
				
		var acceptsValues: Bool {
			return size < 10
		}
		
		func insert(_ value: Value, at offset: Offset, size: Offset) {
			let element = Element(value: value, size: size)
			self.size += size
			
			if (offset < self.offset) {
				self.offset += offset - self.offset
				elements.insert(element, at: 0)
			} else {
				var currentOffset = self.offset
				
				if currentOffset == offset {
					elements.insert(element, at: 0)
				} else {
					for (index, existingElement) in elements.enumerated() {
						if currentOffset == offset {
							elements.insert(element, at: index + 1)
							return
						}
						currentOffset += existingElement.size
					}
					elements.append(element)
				}
			}
		}
	}
	
	private var root: Node? = nil
	
	mutating func insert(_ value: Value, at offset: Offset, size: Offset) {
		//print("Insert \(element.value) at \(element.offset)")
		
		switch findNode(for: offset, size: size) {
		case .found(node: let node, containsElementAtOffset: let exists):
			assert(!exists)
			node.insert(value, at: offset, size: size)
			//print("→ Extend node with offset \(node.offset)")
		case .notFound(lastNode: let parent):
			let node = Node(offset: offset, elements: [Node.Element(value: value, size: size)])
			
			if parent != nil {
				if offset < parent!.offset {
					parent!.left = node
					//print("→ New node with offset \(node.offset), left child of node with offset \(parent.offset)")
				} else {
					parent!.right = node
					//print("→ New node with offset \(node.offset), right child of node with offset \(parent.offset)")
				}
				
				//rightRotate(parent!, parent: &root)
			} else {
				root = node
			}
		}
	}
	
	enum NodeSearchResult {
		case found(node: Node, containsElementAtOffset: Bool)
		case notFound(lastNode: Node?)
	}
	
	private func rightRotate(_ node: Node, parent: inout Node?) {
		guard let left = node.left else {
			assertionFailure()
			return
		}
						
		let newNode = left
		newNode.left = left.left
		node.left = left.right
		newNode.right = node
		
		if parent != nil {
			if parent! === node {
				parent = newNode
			}
			else if parent!.left === node {
				parent!.left = newNode
			}
			else if parent!.right === node {
				parent!.right = newNode
			}
		}
	}
	
	private func findNode(for offset: Offset, size: Offset) -> NodeSearchResult {
		guard let root = root else {
			return .notFound(lastNode: nil)
		}
		
		var node = root
		
		while true {
			if node.range.contains(offset) {
				return .found(node: node, containsElementAtOffset: true)
			} else if offset < node.range.startIndex {
				if node.range.startIndex == offset + size && node.acceptsValues {
					return .found(node: node, containsElementAtOffset: false)
				} else if let left = node.left {
					node = left
				} else {
					return .notFound(lastNode: node)
				}
			} else if offset >= node.range.endIndex {
				if node.range.endIndex == offset && node.acceptsValues {
					return .found(node: node, containsElementAtOffset: false)
				} else if let right = node.right {
				   node = right
			   } else {
				   return .notFound(lastNode: node)
			   }
			}
		}
	}
}
