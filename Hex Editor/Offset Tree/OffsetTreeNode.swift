//
//  OffsetTreeNode.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

extension OffsetTree {
	class Node {
		struct Pair {
			var range: Range<Int>
			var element: Element
			var child: Node?
		}
		
		var pairs: [Pair]
		var firstChild: Node? = nil
				
		init(initialElement: Element, range: Range<Int>) {
			let initialPair = Pair(range: range, element: initialElement, child: nil)
			pairs = [initialPair]
		}
		
		func insert(_ element: Element, range: Range<Int>) {
			switch index(for: range.lowerBound) {
			case .element(let index):
				precondition(index <= pairs.endIndex)
				if (index < pairs.endIndex) {
					pairs[index].range = range
					pairs[index].element = element
				} else {
					pairs.append(Pair(range: range, element: element, child: nil))
				}
				
			case .node(let index):
				func isValid(_ pairIndex: Int) -> Bool {
					return index >= 0
				}

				let offset = isValid(index) ? pairs[index].range.endIndex : 0
				let rangeInChild = (range.startIndex - offset)..<(range.endIndex - offset)
				
				if let child = isValid(index) ? pairs[index].child : firstChild {
					child.insert(element, range: rangeInChild)
				} else {
					let newChild = Node(initialElement: element, range: rangeInChild)
					if isValid(index) {
						pairs[index].child = newChild
					} else {
						firstChild = newChild
					}
				}
			}
		}
		
		enum FindResult {
			case element(Int)
			case node(Int)
		}
		
		func index(for offset: Int) -> FindResult {
			var leftBound = pairs.startIndex
			var rightBound = pairs.endIndex - 1
			
			while leftBound <= rightBound {
				let index = (leftBound + rightBound) / 2
				let currentPair = pairs[index]
				let nextPair = index < pairs.endIndex - 1 ? pairs[index + 1] : nil

				if offset >= currentPair.range.startIndex {
					if offset < currentPair.range.endIndex {
						return .element(index)
					} else if let nextPair = nextPair {
						if offset < nextPair.range.startIndex {
							return .node(index)
						} else {
						   leftBound = index + 1
					   }
					} else {
						return .element(pairs.endIndex)
					}
				} else {
					rightBound = index - 1
				}
			}
			
			precondition(offset < pairs.first!.range.startIndex)
			return .node(-1)
		}
	}
}
