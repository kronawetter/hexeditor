//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-15.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct OffsetTree<NodeValues: OffsetTreeNodePayload> {
	typealias Offset = Int
	
	class Node {
		var offset: Offset
		var left: Node?
		var right: Node?
		var values: NodeValues
		
		init(offset: Offset, left: Node? = nil, right: Node? = nil) {
			self.offset = offset
			self.left = left
			self.right = right
			self.values = NodeValues()
		}
		
		var size: Offset {
			return values.size
		}
				
		var acceptsValues: Bool {
			return values.size < 10
		}
		
		func insert(_ value: NodeValues.Value, at offset: Offset, size: Offset) {
			if let offsetDelta = values.insert(value, at: offset, size: size) {
				self.offset += offsetDelta
			}
		}
	}
	
	private var root: Node? = nil
	
	mutating func insert(_ value: NodeValues.Value, at offset: Offset, size: Offset) {
		switch findNode(for: offset, size: size) {
		case .found(node: let node, offsetOfNode: let offsetOfNode, containsElement: let exists):
			precondition(!exists)
			node.insert(value, at: offset - offsetOfNode, size: size)
		
		case .notFound(lastNode: let parent, offsetOfLastNode: let offsetOfLastNode):
			let node = Node(offset: offset - (offsetOfLastNode ?? 0))
			node.insert(value, at: 0, size: size)
			
			if parent != nil {
				if offset < parent!.offset {
					parent!.left = node
				} else {
					parent!.right = node
				}
			} else {
				root = node
			}
		}
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
	
	private enum NodeSearchResult {
		case found(node: Node, offsetOfNode: Offset, containsElement: Bool)
		case notFound(lastNode: Node?, offsetOfLastNode: Offset?)
	}
	
	private func findNode(for offset: Offset, size: Offset) -> NodeSearchResult {
		guard let root = root else {
			return .notFound(lastNode: nil, offsetOfLastNode: nil)
		}
		
		var node = root
		var currentOffset = 0
		
		while true {
			currentOffset += node.offset
			let range = currentOffset..<(currentOffset + node.size)
			
			if range.contains(offset) {
				return .found(node: node, offsetOfNode: currentOffset, containsElement: true)
			} else if offset < range.startIndex {
				if range.startIndex == offset + size && node.acceptsValues {
					return .found(node: node, offsetOfNode: currentOffset, containsElement: false)
				} else if let left = node.left {
					node = left
				} else {
					return .notFound(lastNode: node, offsetOfLastNode: currentOffset)
				}
			} else if offset >= range.endIndex {
				if range.endIndex == offset && node.acceptsValues {
					return .found(node: node, offsetOfNode: currentOffset, containsElement: false)
				} else if let right = node.right {
				   node = right
			   } else {
				   return .notFound(lastNode: node, offsetOfLastNode: currentOffset)
			   }
			}
		}
	}
}
