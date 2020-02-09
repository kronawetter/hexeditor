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

					var leftBound = pairs.startIndex
					var rightBound = pairs.endIndex

					while leftBound < rightBound {
						let index = (leftBound + rightBound) / 2
						let pair = pairs[index]

						if pair.range.startIndex > pairSplittingResult.range.startIndex {
							rightBound = index
						} else {
							leftBound = pairs.index(after: index)
						}
					}
					
					let pairSplittingResultIndex = (leftBound + rightBound) / 2
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

		// Returns removed element
		func remove(at offset: Int) -> OffsetTreeElement {
			switch index(for: offset, includeStartIndex: true, includeEndIndex: false) {
			case .new(before: _):
				preconditionFailure()

			case .existing(at: let index):
				let pairWithElementToRemove = pairs[index]
				let removedElement = pairWithElementToRemove.element

				for index2 in (index + 1)..<pairs.endIndex {
					pairs[index2].range = pairs[index2].range - removedElement.size
					pairs[index2].child?.baseOffset -= removedElement.size
				}

				if isLeaf {
					pairs.remove(at: index)

					if pairs.isEmpty {
						print("Removed leaf pair -> empty node")
					} else {
						print("Removed leaf pair -> non-empty node")
					}
				} else {
					print("Finding right-most child for non-leaf pair removal")
					let childContainingNewParentElement = index > 0 ? pairs[index - 1].child! : firstChild!
					let newParentElement = childContainingNewParentElement.node.remove(at: offset - childContainingNewParentElement.baseOffset - 1)
					print("Found right-most child for non-leaf pair removal")

					let newRange = (offset - newParentElement.size)..<offset

					pairs[index].element = newParentElement
					pairs[index].range = newRange
					pairs[index].child = pairWithElementToRemove.child // can be removed
					pairs[index].child?.baseOffset -= removedElement.size

					print("Removed non-leaf pair")

					rebalance(index: index - 1)
				}

				return removedElement

			case .descend(let index):
				let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!
				let newOffset = offset - baseOffset

				print("Descended")
				let removedElement = child.remove(at: newOffset)

				for index2 in (index + 1)..<pairs.endIndex {
					pairs[index2].range = pairs[index2].range - removedElement.size
					pairs[index2].child?.baseOffset -= removedElement.size
				}

				rebalance(index: index)
				return removedElement
			}
		}

		func rebalance(index: Int) {
			let (child, baseOffset) = index >= 0 ? pairs[index].child! : firstChild!

			if child.pairCountStatus == .insufficent {
				let leftSibbling: Child?
				if index == 0 {
					leftSibbling = firstChild!
				} else if index > 0 {
					leftSibbling = pairs[index - 1].child!
				} else {
					leftSibbling = nil
				}
				let rightSibbling = index < pairs.endIndex - 1 ? pairs[index + 1].child! : nil

				if let rightSibbling = rightSibbling, rightSibbling.node.pairCountStatus == .sufficient {
					// Rotate left

					var oldParentPair = pairs[index + 1]
					var newParentPair = rightSibbling.node.pairs.first!
					let childOfNewParentPair = newParentPair.child

					newParentPair.range = newParentPair.range + rightSibbling.baseOffset
					newParentPair.child = oldParentPair.child

					oldParentPair.range = oldParentPair.range - baseOffset
					oldParentPair.child = rightSibbling.node.firstChild
					oldParentPair.child?.baseOffset += rightSibbling.baseOffset - baseOffset

					child.pairs.append(oldParentPair)

					pairs[index + 1] = newParentPair
					rightSibbling.node.pairs.removeFirst()
					rightSibbling.node.firstChild = childOfNewParentPair

					print("Rotated left")
				} else if let leftSibbling = leftSibbling, leftSibbling.node.pairCountStatus == .sufficient {
					// Rotate right

					var oldParentPair = pairs[index]
					var newParentPair = leftSibbling.node.pairs.last!
					let childOfNewParentPair = newParentPair.child

					newParentPair.range = newParentPair.range + leftSibbling.baseOffset
					newParentPair.child = (node: child, baseOffset: 0)

					oldParentPair.child = child.firstChild
					oldParentPair.child?.baseOffset += baseOffset

					child.firstChild = childOfNewParentPair
					child.firstChild?.baseOffset += leftSibbling.baseOffset
					child.pairs.insert(oldParentPair, at: 0)

					pairs[index] = newParentPair
					leftSibbling.node.pairs.removeLast()

					print("Rotated right")
				} else {
					// Merge

					let parentPairIndex: Int
					let receivingChild: Child

					if index >= 0 {
						parentPairIndex = index
						receivingChild = index > 0 ? pairs[index - 1].child! : firstChild!
					} else {
						parentPairIndex = 0
						receivingChild = firstChild!
					}

					let parentPair = pairs[parentPairIndex]

					var modifiedParentPair = parentPair
					modifiedParentPair.range = modifiedParentPair.range - receivingChild.baseOffset
					modifiedParentPair.child = parentPair.child!.node.firstChild
					modifiedParentPair.child?.baseOffset += parentPair.child!.baseOffset - receivingChild.baseOffset

					receivingChild.node.pairs.append(modifiedParentPair)

					for pair in parentPair.child!.node.pairs {
						var pair = pair
						pair.range = pair.range + parentPair.child!.baseOffset - receivingChild.baseOffset
						pair.child?.baseOffset += parentPair.child!.baseOffset - receivingChild.baseOffset
						receivingChild.node.pairs.append(pair)
					}

					pairs.remove(at: parentPairIndex)

					print("Merged, node now has \(pairs.count) pair(s), receiving node now has \(receivingChild.node.pairs.count) pair(s)")
				}
			} else {
				print("No rebalancing required")
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

		static let maximumPairCount = 3

		enum PairCountStatus {
			case insufficent
			case barelySufficient
			case sufficient
			case exceeding
		}

		var pairCountStatus: PairCountStatus {
			let minimumPairCount = (Self.maximumPairCount - 1) / 2
			let maximumPairCount = Self.maximumPairCount
			if pairs.count < minimumPairCount {
				return .insufficent
			} else if pairs.count == minimumPairCount {
				return .barelySufficient
			} else if pairs.count <= maximumPairCount {
				return .sufficient
			} else {
				return .exceeding
			}
		}

		var isExceedingMaximumPairCount: Bool {
			return pairCountStatus == .exceeding
		}

		func find(offset: Int) -> (node: Node, pairIndex: Int, offset: Int)? {
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

				return (node: self, pairIndex: index, offset: newOffset)
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
