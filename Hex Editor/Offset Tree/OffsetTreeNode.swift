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
			switch index(for: offset, includeStartIndex: false, includeEndIndex: false) {
			case .existing(at: _):
				preconditionFailure()

			case .new(before: let index):
				let newPair = Pair(offset: offset, element: element)
				pairs.insert(newPair, at: index)

				// TODO: Clean up updating range of subsequent pairs (including their nodes)
				for index2 in (index + 1)..<pairs.endIndex {
					pairs[index2].range = pairs[index2].range + newPair.range.count
					pairs[index2].child?.baseOffset += newPair.range.count
				}

				if isExceedingMaximumPairCount {
					return splitPair()
				} else {
					return nil
				}

			case .descend(to: let index):
				let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!
				let newOffset = offset - baseOffset

				if var pairSplittingResult = child.insert(element, offset: newOffset) {
					// TODO: This should be done as part of splitPair()
					pairSplittingResult.range = pairSplittingResult.range + baseOffset
					pairSplittingResult.child?.baseOffset += baseOffset

					for index2 in (index + 1)..<pairs.endIndex {
						pairs[index2].range = pairs[index2].range + element.size
						pairs[index2].child?.baseOffset += element.size
					}

					let pairSplittingResultIndex = pairs.enumerated().filter { $1.range.startIndex > pairSplittingResult.range.startIndex }.first?.offset ?? pairs.endIndex // TOOD: Perform binary search
					pairs.insert(pairSplittingResult, at: pairSplittingResultIndex)

					isLeaf = !(firstChild != nil || pairs.first(where: { $0.child != nil }) != nil)
				} else {
					// TODO: Clean up updating range of subsequent pairs (including their nodes)
					for index2 in (index + 1)..<pairs.endIndex {
						pairs[index2].range = pairs[index2].range + element.size
						pairs[index2].child?.baseOffset += element.size
					}
				}

				if isExceedingMaximumPairCount {
					return splitPair()
				} else {
					return nil
				}
			}
		}

		func split(at offset: Int) -> OffsetTreeElement? {
			switch index(for: offset, includeStartIndex: false, includeEndIndex: false) {
			case .existing(at: let index):
				let baseOffset = pairs[index].range.startIndex
				let offsetInElement = offset - baseOffset

				pairs[index].range = baseOffset..<offset
				let newElement = pairs[index].element.split(at: offsetInElement)
				pairs[index].child?.baseOffset -= newElement.size

				// TODO: Clean up updating range of subsequent pairs (including their nodes)
				for index2 in (index + 1)..<pairs.endIndex {
					pairs[index2].range = pairs[index2].range - newElement.size
					pairs[index2].child?.baseOffset -= newElement.size
				}

				return newElement

			case .new(before: _):
				return nil

			case .descend(to: let index):
				let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!
				let newOffset = offset - baseOffset

				let newElement = child.split(at: newOffset)

				if let newElement = newElement {
					// TODO: Is this also necessary here?
					// pairs[index].child?.baseOffset -= newElement.size

					// TODO: Clean up updating range of subsequent pairs (including their nodes)
					for index2 in (index + 1)..<pairs.endIndex {
						pairs[index2].range = pairs[index2].range - newElement.size
						pairs[index2].child?.baseOffset -= newElement.size
					}
				}

				return newElement
			}
		}

		func splitPair() -> Pair {
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
			return pairs.count > 3//1020
		}

		func find(offset: Int) -> (node: Node, element: OffsetTreeElement, offset: Int)? {
			switch index(for: offset, includeStartIndex: true, includeEndIndex: false) {
			case .descend(to: let index):
				let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!
				let newOffset = offset - baseOffset

				return child.find(offset: newOffset)

			case .new(before: _):
				return nil//preconditionFailure()

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

		func index(for offset: Int, includeStartIndex: Bool, includeEndIndex: Bool) -> IndexResult {
			var leftBound = pairs.startIndex
			var rightBound = pairs.endIndex - 1
			
			while leftBound <= rightBound {
				let index = (leftBound + rightBound) / 2
				let currentPair = pairs[index]
				let nextIndex = pairs.index(after: index)
				let nextPair = nextIndex < pairs.endIndex ? pairs[nextIndex] : nil

				if offset > currentPair.range.startIndex || (includeStartIndex && offset == currentPair.range.startIndex) {
					if offset < currentPair.range.endIndex {
						return .existing(at: index)
					} else if includeEndIndex && offset == currentPair.range.endIndex {
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
							return .new(before: nextIndex)
						} else {
							return .descend(to: index)
						}
					}
				} else if !includeStartIndex && offset == currentPair.range.startIndex {
					if isLeaf {
						return .new(before: index)
					} else {
						return .descend(to: index - 1)
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
