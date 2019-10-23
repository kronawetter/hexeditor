//
//  OffsetTreeNode.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

extension Range where Bound: Numeric {
	static func -(range: Range, offset: Bound) -> Range {
		return Range(uncheckedBounds: (lower: range.lowerBound - offset, upper: range.upperBound - offset))
	}
	
	func extended(by bound: Bound) -> Range {
		return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound + bound))
	}
}

extension OffsetTree {
	class Node {
		struct Pair {
			// TODO: Change var -> let where appropriate
			var range: Range<Int>
			var elementStorage: ElementStorage
			var child: Node? = nil
			
			init(offset: Int, initialElement: Element) {
				range = offset..<(offset + initialElement.size)
				elementStorage = ElementStorage(initialElement: initialElement)
			}
		}
		
		var pairs: [Pair]
		var firstChild: Node? = nil
		
		init(initialElement: Element, range: Range<Int>) {
			let initialPair = Pair(offset: range.startIndex, initialElement: initialElement)
			pairs = [initialPair]
		}
		
		init(pairs: [Pair]) {
			self.pairs = pairs
		}
		
		// Returns pair to insert in parent node after splitting
		func insert(_ element: Element, offset: Int) -> Pair? {
			switch index(for: offset) {
			case .existing(at: let index):
				let baseOffset = 0//pairs[index].range.startIndex
				pairs[index].elementStorage.insert(element, at: offset - baseOffset)
				pairs[index].range = pairs[index].range.extended(by: element.size)
				return nil

			case .new(before: let index):
				let newPair = Pair(offset: offset, initialElement: element)
				pairs.insert(newPair, at: index)
				if isExceedingMaximumPairCount {
					return split()
				} else {
					return nil
				}
			
			case .descend(to: let index):
				let child: Node
				let baseOffset: Int
				if index >= 0 {
					child = pairs[index].child!
					baseOffset = 0//pairs[index].range.endIndex
				} else {
					child = firstChild!
					baseOffset = 0//pairs.first!.range.startIndex
				}
				
				let newOffset = offset - baseOffset
				if let splitResult = child.insert(element, offset: newOffset) {
					let index = pairs.enumerated().filter { $1.range.startIndex > offset }.first?.offset ?? pairs.endIndex // TOOD: Perform binary search
					pairs.insert(splitResult, at: index)
				}
				if isExceedingMaximumPairCount {
					return split()
				} else {
					return nil
				}
			}
		}
				
		func split() -> Pair {
			let indexOfSeparatingPair = pairs.count / 2
			
			/*for index in pairs.indices.filter({ $0 != indexOfSeparatingPair }) {
				pairs[index].range = pairs[index].range - pairs[indexOfSeparatingPair].range.startIndex
			}*/
						
			let pairsForNewNode = Array(pairs[(indexOfSeparatingPair + 1)..<pairs.endIndex]) // TODO: Remove array cast
			let newNode = Node(pairs: pairsForNewNode)
			newNode.firstChild = pairs[indexOfSeparatingPair].child
			
			var newPair = pairs[indexOfSeparatingPair]
			newPair.child = newNode

			pairs.removeSubrange(indexOfSeparatingPair..<pairs.endIndex)
			return newPair
		}
		
		var isLeaf: Bool {
			return pairs.compactMap { $0.child } .isEmpty && firstChild == nil
		}
		
		var isExceedingMaximumPairCount: Bool {
			return pairs.count > 2
		}
		
		enum FindResult {
			case existing(at: Int)
			case new(before: Int)
			case descend(to: Int)
		}
		
		func index(for offset: Int) -> FindResult {
			var leftBound = pairs.startIndex
			var rightBound = pairs.endIndex - 1
			
			while leftBound <= rightBound {
				let index = (leftBound + rightBound) / 2
				let currentPair = pairs[index]
				let nextIndex = pairs.index(after: index)
				let nextPair = nextIndex < pairs.endIndex ? pairs[nextIndex] : nil

				if offset >= currentPair.range.startIndex {
					if offset <= currentPair.range.endIndex {
						return .existing(at: index)
					} else if let nextPair = nextPair {
						if offset < nextPair.range.startIndex {
							if isLeaf {
								return .new(before: nextIndex)
							} else {
								return .descend(to: index)
							}
						} else {
						   leftBound = pairs.index(after: index)
					   }
					} else {
						if isLeaf {
							return .new(before: pairs.index(after: index))
						} else {
							return .descend(to: index)
						}
					}
				} else {
					rightBound = pairs.index(before: index)
				}
			}
			
			precondition(offset < pairs.first!.range.startIndex)
			if isLeaf {
				return .new(before: pairs.startIndex)
			} else {
				return .descend(to: -1)
			}
		}
	}
}
