//
//  OffsetTreeNode.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

extension Range where Bound: Numeric {
	static func +(range: Range, offset: Bound) -> Range {
		return Range(uncheckedBounds: (lower: range.lowerBound + offset, upper: range.upperBound + offset))
	}
	
	static func -(range: Range, offset: Bound) -> Range {
		return range + offset * -1
	}
	
	func extended(by bound: Bound) -> Range {
		return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound + bound))
	}
}

extension OffsetTree {
	class Node {
		typealias Child = (node: Node, baseOffset: Int)

		struct Pair {
			// TODO: Change var -> let where appropriate
			var range: Range<Int>
			var element: OffsetTreeElement
			var child: Child? = nil
			
			init(offset: Int, element: OffsetTreeElement) {
				range = offset..<(offset + element.size)
				self.element = element
			}
		}
		
		var pairs: [Pair]
		var firstChild: Child?

		var isLeaf: Bool

		init(initialElement: OffsetTreeElement, range: Range<Int>) {
			let initialPair = Pair(offset: range.startIndex, element: initialElement)
			pairs = [initialPair]
			firstChild = nil
			isLeaf = true
		}

		init(pairs: [Pair]) {
			self.pairs = pairs
			firstChild = nil
			isLeaf = true
		}
		
		// Returns pair to insert in parent node after splitting
		func insert(_ element: OffsetTreeElement, offset: Int) -> Pair? {
			switch index(for: offset, reading: true) { // TODO: Check what reading paramater does
			case .existing(at: let index):
				let baseOffset = pairs[index].range.startIndex
				let offsetInElement = offset - baseOffset

				var firstExistingElement = pairs[index].element
				let secondExistingElement = firstExistingElement.split(at: offsetInElement)

				let newPair = Pair(offset: offset, element: element)

				if firstExistingElement.size > 0 {
					let firstExistingPair = Pair(offset: baseOffset, element: firstExistingElement)
					pairs[index] = firstExistingPair
					pairs.insert(newPair, at: index + 1)
				} else {
					pairs[index] = newPair
				}

				if secondExistingElement.size > 0 {
					let secondExistingPair = Pair(offset: newPair.range.endIndex, element: secondExistingElement)
					pairs.insert(secondExistingPair, at: index + (firstExistingElement.size > 0 ? 2 : 1))
				}

				// TODO: Current implementation requries that range of other pairs (also of nodes?) are updated. Check whether this can be avoided or implement updating of ranges

				if isExceedingMaximumPairCount {
					return split()
				} else {
					return nil
				}
			
			case .new(before: let index):
				let newPair = Pair(offset: offset, element: element)
				pairs.insert(newPair, at: index)
				
				if isExceedingMaximumPairCount {
					return split()
				} else {
					return nil
				}
			
			case .descend(to: let index):
				let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!
				let newOffset = offset - baseOffset

				if var splitResult = child.insert(element, offset: newOffset) {
					// TODO: This should be done as part of split()
					splitResult.range = splitResult.range + baseOffset
					splitResult.child?.baseOffset += baseOffset

					let index = pairs.enumerated().filter { $1.range.startIndex > offset }.first?.offset ?? pairs.endIndex // TOOD: Perform binary search
					pairs.insert(splitResult, at: index)
					
					isLeaf = !(firstChild != nil || pairs.first(where: { $0.child != nil }) != nil)
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
			let separatingPair = pairs[indexOfSeparatingPair]
			let baseOffsetOfSeparatingPair = separatingPair.range.lowerBound
			
			var pairsForNewNode = Array(pairs[(indexOfSeparatingPair + 1)..<pairs.endIndex]) // TODO: Remove array cast
			for index in pairsForNewNode.indices {
				pairsForNewNode[index].range = pairsForNewNode[index].range - baseOffsetOfSeparatingPair
				pairsForNewNode[index].child?.baseOffset -= baseOffsetOfSeparatingPair
			}
			
			let newChildNode = Node(pairs: pairsForNewNode)
			newChildNode.firstChild = pairs[indexOfSeparatingPair].child
			newChildNode.firstChild?.baseOffset -= baseOffsetOfSeparatingPair
			newChildNode.isLeaf = !(newChildNode.firstChild != nil || newChildNode.pairs.first(where: { $0.child != nil }) != nil)

			var newPair = separatingPair
			newPair.child = (node: newChildNode, baseOffset: baseOffsetOfSeparatingPair)

			pairs.removeSubrange(indexOfSeparatingPair..<pairs.endIndex)
			return newPair
		}
				
		var isExceedingMaximumPairCount: Bool {
			return pairs.count > 1020
		}

		func find(offset: Int) -> (node: Node, element: OffsetTreeElement, offset: Int)? {
			switch index(for: offset, reading: true) {
			case .descend(to: let index):
				let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!
				let newOffset = offset - baseOffset

				return child.find(offset: newOffset)

			case .new(before: _):
				return nil

			case .existing(at: let index):
				let baseOffset = pairs[index].range.startIndex
				let newOffset = offset - baseOffset

				return (node: self, element: pairs[index].element, offset: newOffset)
			}
		}

		enum IndexResult {
			case existing(at: Int)
			case new(before: Int)
			case descend(to: Int)
		}
		
		func index(for offset: Int, reading: Bool = false) -> IndexResult {
			var leftBound = pairs.startIndex
			var rightBound = pairs.endIndex - 1
			
			while leftBound <= rightBound {
				let index = (leftBound + rightBound) / 2
				let currentPair = pairs[index]
				let nextIndex = pairs.index(after: index)
				let nextPair = nextIndex < pairs.endIndex ? pairs[nextIndex] : nil

				if offset >= currentPair.range.startIndex {
					if (reading && offset < currentPair.range.endIndex) || (!reading && offset <= currentPair.range.endIndex) {
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
