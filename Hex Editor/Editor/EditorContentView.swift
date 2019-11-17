//
//  EditorContentView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-01.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class EditorContentView: UIView {
	var font = UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular) {
		didSet {
			setNeedsLayout()
		}
	}

	var dataSource: EditorDataSource? = nil {
		didSet {
			setNeedsLayout()
		}
	}

	var visibleRect = CGRect.zero {
		didSet {
			if visibleRect != oldValue {
				// TODO: Handle size change
				
				removeSublayersOutsideVisibleRect()
				addMissingWordGroupSublayersAtBegin()
				addMissingWordGroupSublayersAtEnd()

				layer.setNeedsLayout()
			}
		}
	}

	private var estimatedLineHeight: CGFloat {
		return round(font.lineHeight * 1.5)
	}

	private var widthPerWord: CGFloat {
		return font.pointSize * 2.0
	}

	private var wordsPerLine: Int {
		return Int(bounds.width / widthPerWord)
	}

	private func estimatedWordOffset(at point: CGPoint) -> Int {
		return Int(point.y / estimatedLineHeight) * wordsPerLine
	}

	private var wordGroupSublayers: [EditorAtomicWordGroupLayer] = []
	private var cache = AtomicWordGroupLayerImageCache()

	private func removeSublayersOutsideVisibleRect() {
		guard let dataSource = dataSource else {
			assert(wordGroupSublayers.isEmpty)
			return
		}

		func remove(sequence: AnySequence<EditorAtomicWordGroupLayer>) -> Int {
			var sublayersToRemove = 0

			for sublayer in sequence {
				if sublayer.frame.intersects(visibleRect) {
					break
				} else {
					sublayersToRemove += 1
				}
			}

			sequence.prefix(sublayersToRemove).forEach { $0.removeFromSuperlayer() }

			return sublayersToRemove
		}

		let removedFromBegin = remove(sequence: AnySequence(wordGroupSublayers))
		wordGroupSublayers.removeFirst(removedFromBegin)

		let removedFromEnd = remove(sequence: AnySequence(wordGroupSublayers.reversed()))
		wordGroupSublayers.removeLast(removedFromEnd)
	}

	private func addMissingWordGroupSublayersAtBegin() {
		// TODO: Add sublayers when scrolling upwards
	}

	private func addMissingWordGroupSublayersAtEnd() {
		guard let dataSource = dataSource else {
			return
		}

		var lastFrame: CGRect
		let initialOffset: Int
		if let lastSublayer = wordGroupSublayers.last {
			let wordGroup = dataSource.atomicWordGroup(at: lastSublayer.wordOffset)

			lastFrame = lastSublayer.frame
			initialOffset = (lastSublayer.wordOffset + wordGroup.size)
		} else {
			let wordOffset = max(estimatedWordOffset(at: visibleRect.origin), 0)
			precondition(wordOffset % wordsPerLine == 0)

			let y = CGFloat(wordOffset / wordsPerLine) * estimatedLineHeight
			lastFrame = CGRect(x: .zero, y: y, width: .zero, height: .zero)
			initialOffset = wordOffset
		}

		var lastLineHeight = estimatedLineHeight // TODO: Calculate actual height of last line

		func frame(for size: CGSize) -> CGRect {
			var newFrame = CGRect(x: lastFrame.maxX, y: lastFrame.minY, width: size.width, height: size.height)
			
			if newFrame.maxX > bounds.maxX {
				// Line break
				// TODO: Line break should work differently, should first fill all remaining space in current line
				newFrame.origin.x = .zero
				newFrame.origin.y += lastLineHeight
			}

			return newFrame
		}

		var currentOffset = initialOffset
		let scale = UIScreen.main.scale

		while currentOffset < dataSource.totalWordCount {
			// TODO: Once introduced, convert from presentation offset to file offset
			let wordGroup = dataSource.atomicWordGroup(at: currentOffset)

			// TODO: Request image asynchronously
			// TODO: Pass current font to image generation
			let image = cache.image(for: AtomicWordGroupLayerData(text: wordGroup.text, size: wordGroup.size))
			let size = CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)

			let newFrame = frame(for: size)

			if newFrame.intersects(visibleRect) {
				let sublayer = EditorAtomicWordGroupLayer(wordOffset: currentOffset)
				sublayer.contents = image
				sublayer.isOpaque = true
				sublayer.frame = newFrame

				lastFrame = newFrame

				wordGroupSublayers.append(sublayer)
				layer.addSublayer(sublayer)

				currentOffset += wordGroup.size
			} else {
				break
			}
		}

		//displayedWordOffset = (displayedWordOffset?.lowerBound ?? initialOffset)..<currentOffset
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		guard let dataSource = dataSource else {
			return .zero
		}

		let wordCount = dataSource.totalWordCount
		let maximumWidth = size.width
		let wordsPerLine = floor(maximumWidth / widthPerWord)
		let lineCount = ceil(CGFloat(wordCount) / wordsPerLine)

		let width = wordsPerLine * widthPerWord
		let height = lineCount * estimatedLineHeight

		return CGSize(width: width, height: height)
	}
}
