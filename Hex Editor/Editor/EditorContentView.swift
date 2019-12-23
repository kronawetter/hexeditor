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

	var contentInsets = UIEdgeInsets(top: 2.0, left: 10.0, bottom: 10.0, right: 10.0) {
		didSet {
			setNeedsLayout()
		}
	}

	private var lineSpacing: CGFloat {
		return round(font.lineHeight * 0.5)
	}

	private var estimatedLineHeight: CGFloat {
		return floor(font.lineHeight * UIScreen.main.scale) / UIScreen.main.scale + lineSpacing // TODO
	}

	private var widthPerWord: CGFloat {
		// TODO: Get width of characters
		return font.pointSize * 1.25
	}

	private var wordsPerLine: Int {
		return Int((bounds.width - contentInsets.left - contentInsets.right) / widthPerWord)
	}

	func width(for wordsPerLine: Int) -> CGFloat {
		return CGFloat(wordsPerLine) * widthPerWord + contentInsets.left + contentInsets.right
	}

	private func estimatedWordOffset(for point: CGPoint) -> (offset: Int, origin: CGPoint) {
		let offset = Int((max(point.y, .zero) - contentInsets.top) / estimatedLineHeight) * wordsPerLine
		let x = contentInsets.left
		let y = CGFloat(offset / wordsPerLine) * estimatedLineHeight + contentInsets.top

		return (offset: offset, origin: CGPoint(x: x, y: y))
	}

	private var cache = AtomicWordGroupLayerImageCache()

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = .systemBackground
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func removeSublayersOutsideVisibleRect() {
		if let sublayers = layer.sublayers {
			sublayers.filter { !$0.frame.intersects(visibleRect) } .forEach { $0.removeFromSuperlayer() }
		}
	}

	private enum OriginReferencePoint {
		case topLeft
		case bottomLeft
	}

	private func layoutLine(offset: Int, origin: CGPoint, reference: OriginReferencePoint) {
		let dataSource = self.dataSource!
		precondition(offset.isMultiple(of: wordsPerLine))
		precondition((0..<dataSource.totalWordCount).contains(offset))

		let upperBound = min(offset + wordsPerLine, dataSource.totalWordCount)

		var groups: [(offset: Int, totalSize: Int, image: CGImage)] = []
		var currentOffset = offset
		while currentOffset < upperBound {
			let wordGroup = dataSource.atomicWordGroup(at: currentOffset) // TODO: Make return type a struct with member function `size`, so wordGroup.range.count can be replaced with wordGroup.size

			let offset1 = currentOffset - wordGroup.range.lowerBound
			let totalSize = wordGroup.range.count // TODO: groups.map { $0.totalSize }.sum() can be greater than upperBound - lowerBound
			let image = cache.image(text: wordGroup.text, size: totalSize)
			groups.append((offset: offset1, totalSize: totalSize, image: image))

			currentOffset += totalSize - offset1
		}

		let scale = UIScreen.main.scale
		let lineHeight = groups.map { CGFloat($0.image.height) / scale }.max()!

		let offsetFromYOrigin: CGFloat
		switch reference {
		case .topLeft:
			offsetFromYOrigin = self.lineSpacing

		case .bottomLeft:
			offsetFromYOrigin = -lineHeight - self.lineSpacing
		}

		var wordOffsetInLine = 0
		for group in groups {
			let sublayer = EditorAtomicWordGroupLayer(wordOffset: offset + wordOffsetInLine)
			sublayer.contents = group.image
			sublayer.contentsGravity = .topLeft
			sublayer.contentsScale = scale
			sublayer.isOpaque = true
			sublayer.frame = CGRect(x: CGFloat(wordOffsetInLine) * widthPerWord + origin.x, y: origin.y + offsetFromYOrigin, width: CGFloat(group.totalSize - group.offset) * widthPerWord, height: lineHeight)

			layer.addSublayer(sublayer)

			wordOffsetInLine += group.totalSize - group.offset
		}
	}

	private func addMissingWordGroupSublayersAtBegin() {
		while true {
			guard let firstSublayer = layer.sublayers?.compactMap({ $0 as? EditorAtomicWordGroupLayer }).min(by: { $0.wordOffset < $1.wordOffset }) else {
				break
			}

			let offset = ((firstSublayer.wordOffset / wordsPerLine) - 1) * wordsPerLine
			let origin = CGPoint(x: contentInsets.left, y: firstSublayer.frame.minY)

			if offset >= 0, origin.y > visibleRect.minY {
				layoutLine(offset: offset, origin: origin, reference: .bottomLeft)
			} else {
				break
			}
		}
	}

	private func addMissingWordGroupSublayersAtEnd() {
		while true {
			let offset: Int
			let origin: CGPoint
			if let lastSublayer = layer.sublayers?.compactMap({ $0 as? EditorAtomicWordGroupLayer }).max(by: { $0.wordOffset < $1.wordOffset }) {
				offset = ((lastSublayer.wordOffset / wordsPerLine) + 1) * wordsPerLine
				origin = CGPoint(x: contentInsets.left, y: lastSublayer.frame.maxY) // TODO: Use actual line height
			} else {
				(offset, origin) = estimatedWordOffset(for: visibleRect.origin)
			}

			if offset <= dataSource!.totalWordCount, origin.y < visibleRect.maxY {
				layoutLine(offset: offset, origin: origin, reference: .topLeft)
			} else {
				break
			}
		}
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		guard let dataSource = dataSource else {
			return .zero
		}

		let wordCount = dataSource.totalWordCount
		let maximumWidth = size.width - contentInsets.left - contentInsets.right
		let wordsPerLine = floor(maximumWidth / widthPerWord)
		let lineCount = ceil(CGFloat(wordCount) / wordsPerLine)

		let width = wordsPerLine * widthPerWord + contentInsets.left + contentInsets.right
		let height = lineCount * estimatedLineHeight + contentInsets.top + contentInsets.bottom

		return CGSize(width: width, height: height)
	}
}
