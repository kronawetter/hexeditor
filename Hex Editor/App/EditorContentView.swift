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
				removeWordGroupSublayersBeforeVisibleRect()
				removeWordGroupSublayersAfterVisibleRect()
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

	private var displayedWordOffset: Range<Int>? = nil

	private var wordGroupSublayers: [CALayer] = []
	private var cache = AtomicWordGroupLayerImageCache()

	// TODO: Eliminate code duplication
	private func removeWordGroupSublayersBeforeVisibleRect() {
		guard let dataSource = dataSource, let displayedWordOffset = displayedWordOffset else {
			assert(wordGroupSublayers.isEmpty)
			return
		}

		var currentOffset = displayedWordOffset.lowerBound
		var sublayersToRemove = 0

		while currentOffset < displayedWordOffset.upperBound {
			let sublayer = wordGroupSublayers[sublayersToRemove]

			if sublayer.frame.intersects(visibleRect) {
				break
			} else {
				// TODO: Once introduced, convert from presentation offset to file offset
				let wordGroup = dataSource.atomicWordGroup(at: currentOffset)

				currentOffset += wordGroup.size
				sublayersToRemove += 1
			}
		}

		wordGroupSublayers.prefix(sublayersToRemove).forEach { $0.removeFromSuperlayer() }
		wordGroupSublayers.removeFirst(sublayersToRemove)

		if wordGroupSublayers.isEmpty {
			self.displayedWordOffset = nil
		} else {
			self.displayedWordOffset = currentOffset..<displayedWordOffset.upperBound
		}
	}

	private func removeWordGroupSublayersAfterVisibleRect() {
		guard let dataSource = dataSource, let displayedWordOffset = displayedWordOffset else {
			assert(wordGroupSublayers.isEmpty)
			return
		}

		var currentOffset = displayedWordOffset.upperBound
		var sublayersToRemove = 0

		while currentOffset > displayedWordOffset.lowerBound {
			let sublayer = wordGroupSublayers[wordGroupSublayers.count - sublayersToRemove - 1]

			if sublayer.frame.intersects(visibleRect) {
				break
			} else {
				// TODO: Once introduced, convert from presentation offset to file offset
				// TODO: currentOffset might not be a valid starting offset for an atomic word group with non-one size
				let wordGroup = dataSource.atomicWordGroup(at: currentOffset - 1)

				currentOffset -= wordGroup.size
				sublayersToRemove += 1
			}
		}

		wordGroupSublayers.suffix(sublayersToRemove).forEach { $0.removeFromSuperlayer() }
		wordGroupSublayers.removeLast(sublayersToRemove)

		if wordGroupSublayers.isEmpty {
			self.displayedWordOffset = nil
		} else {
			self.displayedWordOffset = displayedWordOffset.lowerBound..<currentOffset
		}
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
		if let displayedWordOffset = displayedWordOffset {
			let lastSublayer = wordGroupSublayers.last! // TODO: Put displayedWordOffset and wordGroupSublayers (both non-optional) into optional tuple
			lastFrame = lastSublayer.frame
			initialOffset = displayedWordOffset.upperBound
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
				let sublayer = CALayer()
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

		displayedWordOffset = (displayedWordOffset?.lowerBound ?? initialOffset)..<currentOffset
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
