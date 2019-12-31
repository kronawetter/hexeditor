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
		return round(font.pointSize * 1.25)
	}

	private var wordGroupSpacingWidth: CGFloat {
		return round(widthPerWord * 0.3)
	}

	private var wordsPerWordSpacingGroup = 2 // TODO: Make non-constant and public/internal

	private var widthPerWordSpacingGroup: CGFloat {
		return widthPerWord * CGFloat(wordsPerWordSpacingGroup) + wordGroupSpacingWidth
	}

	private var wordSpacingGroupsPerLine: Int {
		let width = bounds.width - contentInsets.left - contentInsets.right

		return Int((width + wordGroupSpacingWidth) / widthPerWordSpacingGroup)
	}

	private var wordsPerLine: Int {
		return wordSpacingGroupsPerLine * wordsPerWordSpacingGroup
	}

	func size(for wordsPerLine: Int) -> CGSize {
		assert(wordsPerLine.isMultiple(of: wordsPerWordSpacingGroup))
		let wordSpacingGroupsPerLine = wordsPerLine / wordsPerWordSpacingGroup

		guard let dataSource = dataSource else {
			return .zero
		}

		let lineCount = Int(ceil(Double(dataSource.totalWordCount) / Double(wordsPerLine)))

		let width = CGFloat(wordSpacingGroupsPerLine) * widthPerWordSpacingGroup - wordGroupSpacingWidth + contentInsets.left + contentInsets.right
		let height = CGFloat(lineCount) * estimatedLineHeight + contentInsets.top + contentInsets.bottom

		return CGSize(width: width, height: height)
	}

	private func estimatedWordOffset(for point: CGPoint) -> (offset: Int, origin: CGPoint) {
		assert(point.x == .zero)

		let offset = Int((max(point.y, .zero) - contentInsets.top) / estimatedLineHeight) * wordsPerLine
		let x = contentInsets.left
		let y = CGFloat(offset / wordsPerLine) * estimatedLineHeight + contentInsets.top

		return (offset: offset, origin: CGPoint(x: x, y: y))
	}

	private var cache = AtomicWordGroupLayerImageCache()

	private let tapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

	private let textInteraction = UITextInteraction(for: .editable)

	var inputDelegate: UITextInputDelegate? = nil

	private var selection: Range<Int>? = 0..<0 {
		willSet {
			inputDelegate?.selectionWillChange(self)
		}
		didSet {
			print(selection)
			inputDelegate?.selectionDidChange(self)
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = .systemBackground

		tapGestureRecognizer.addTarget(self, action: #selector(tap(sender:)))
		tapGestureRecognizer.isEnabled = true
		addGestureRecognizer(tapGestureRecognizer)

		textInteraction.textInput = self
		addInteraction(textInteraction)
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
			sublayer.frame = CGRect(x: origin.x + CGFloat(wordOffsetInLine) * widthPerWord + CGFloat(wordOffsetInLine / wordsPerWordSpacingGroup) * wordGroupSpacingWidth, y: origin.y + offsetFromYOrigin, width: CGFloat(group.totalSize - group.offset) * widthPerWord, height: lineHeight) // TODO: Width is incorrect if a multi-word group spans across multiple word spacing groups

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

	override var canBecomeFirstResponder: Bool {
		true
	}

	@objc func tap(sender: UITapGestureRecognizer) {
		if !isFirstResponder && canBecomeFirstResponder {
			becomeFirstResponder()
		}
	}

	private func rectForAtomicWordGroup(at offset: Int) -> CGRect? {
		guard let dataSource = dataSource, let sublayers = layer.sublayers else {
			return nil
		}

		let wordGroup = dataSource.atomicWordGroup(at: offset)

		if let sublayer = sublayers.first(where: { ($0 as? EditorAtomicWordGroupLayer)?.wordOffset == wordGroup.range.startIndex }) {
			return sublayer.frame
		} else {
			// TODO: Estimate rect
			return nil
		}
	}

	/*override func sizeThatFits(_ size: CGSize) -> CGSize {
		guard let dataSource = dataSource else {
			return .zero
		}

		let maximumWidth = size.width - contentInsets.left - contentInsets.right
		let wordSpacingGroupsPerLine = Int((maximumWidth + wordGroupSpacingWidth) / widthPerWordSpacingGroup)
		let wordsPerLine = wordSpacingGroupsPerLine * wordsPerWordSpacingGroup
		let lineCount = Int(ceil(Double(dataSource.totalWordCount) / Double(wordsPerLine)))

		let width = self.width(for: wordsPerLine)
		let height = CGFloat(lineCount) * estimatedLineHeight + contentInsets.top + contentInsets.bottom

		return CGSize(width: width, height: height)
	}*/
}

extension EditorContentView: UIKeyInput {
	var hasText: Bool {
		true
	}

	func insertText(_ text: String) {
		print(text)
	}

	func deleteBackward() {

	}
}

extension EditorContentView: UITextInput {
	class Tokenizer: NSObject, UITextInputTokenizer {
		func rangeEnclosingPosition(_ position: UITextPosition, with granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextRange? {
			nil
		}

		func isPosition(_ position: UITextPosition, atBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
			false
		}

		func position(from position: UITextPosition, toBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextPosition? {
			nil
		}

		func isPosition(_ position: UITextPosition, withinTextUnit granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
			false
		}
	}

	class TextPosition: UITextPosition {
		let index: Int

		init(_ index: Int) {
			self.index = index
		}
	}

	class TextRange: UITextRange {
		let range: Range<Int>

		init(_ range: Range<Int>) {
			self.range = range
		}

		override var isEmpty: Bool {
			range.isEmpty
		}

		override var start: UITextPosition {
			TextPosition(range.startIndex)
		}

		override var end: UITextPosition {
			TextPosition(range.endIndex)
		}
	}

	class TextSelectionRect: UITextSelectionRect {
		private let _rect: CGRect
		private let _containsStart: Bool
		private let _containsEnd: Bool

		init(rect: CGRect, containsStart: Bool, containsEnd: Bool) {
			_rect = rect
			_containsStart = containsStart
			_containsEnd = containsEnd
		}

		override var rect: CGRect {
			_rect
		}

		override var writingDirection: NSWritingDirection {
			.leftToRight
		}

		override var containsStart: Bool {
			_containsStart
		}

		override var containsEnd: Bool {
			_containsEnd
		}

		override var isVertical: Bool {
			false
		}
	}

	func text(in range: UITextRange) -> String? {
		""
	}

	func replace(_ range: UITextRange, withText text: String) {

	}

	var selectedTextRange: UITextRange? {
		get {
			guard let selection = selection else {
				return nil
			}

			return TextRange(selection)
		}
		set(selectedTextRange) {
			let selectedTextRange = selectedTextRange as! TextRange?

			selection = selectedTextRange?.range ?? nil
		}
	}

	var markedTextRange: UITextRange? {
		nil
	}

	var markedTextStyle: [NSAttributedString.Key : Any]? {
		get {
			nil
		}
		set(markedTextStyle) {

		}
	}

	func setMarkedText(_ markedText: String?, selectedRange: NSRange) {

	}

	func unmarkText() {

	}

	var beginningOfDocument: UITextPosition {
		TextPosition(0)
	}

	var endOfDocument: UITextPosition {
		TextPosition(dataSource?.totalWordCount ?? 0)
	}

	func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
		// When selecting text via drag gesture, function might get called with unintialized arguments, so arguments are not force-casted
		guard let fromPosition = fromPosition as? TextPosition, let toPosition = toPosition as? TextPosition else {
			return nil
		}

		return TextRange(fromPosition.index..<toPosition.index)
	}

	func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
		let position = position as! TextPosition

		guard let dataSource = dataSource else {
			return nil
		}

		// TODO: Handle multi-word groups
		let newIndex = position.index + offset

		if (0..<dataSource.totalWordCount).contains(newIndex) {
			return TextPosition(newIndex)
		} else {
			return nil
		}
	}

	func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
		let position = position as! TextPosition

		// TODO: Handle multi-word groups
		// TODO: "Return nil if the computed text position is less than 0 or greater than the length of the backing string."
		switch direction {
		case .right:
			return TextPosition(min(position.index + offset, dataSource?.totalWordCount ?? 0))
		case .left:
			return TextPosition(max(position.index - offset, 0))
		case .up:
			return TextPosition(max(position.index - offset * wordsPerLine, 0))
		case .down:
			return TextPosition(min(position.index + offset * wordsPerLine, dataSource?.totalWordCount ?? 0))
		@unknown default:
			assertionFailure()
			return nil
		}
	}

	func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
		let position = position as! TextPosition
		let other = other as! TextPosition

		if position.index < other.index {
			return .orderedAscending
		} else if position.index > other.index {
			return .orderedDescending
		} else {
			return .orderedSame
		}
	}

	func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
		let from = from as! TextPosition
		let toPosition = toPosition as! TextPosition

		// TODO: UTF-16 characters?!
		return toPosition.index - from.index
	}

	var tokenizer: UITextInputTokenizer {
		Tokenizer()
	}

	func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
		// TODO
		switch direction {
		case .left:
			fallthrough
		case .up:
			return range.start
		case .right:
			fallthrough
		case .down:
			return range.end
		@unknown default:
			assertionFailure()
			return nil
		}
	}

	func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
		let position = position as! TextPosition

		guard let dataSource = dataSource else {
			return nil
		}

		// TODO check whether select from cursor to begin/end of line/document shortcuts work
		switch direction {
		case .left:
			return TextRange(((position.index / wordsPerLine) * wordsPerLine)..<position.index)
		case .up:
			return TextRange(0..<position.index)
		case .right:
			return TextRange(position.index..<min((position.index / wordsPerLine) * (wordsPerLine + 1), dataSource.totalWordCount))
		case .down:
			return TextRange(position.index..<dataSource.totalWordCount)
		@unknown default:
			assertionFailure()
			return nil
		}
	}

	func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
		.leftToRight
	}

	func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {

	}

	func firstRect(for range: UITextRange) -> CGRect {
		guard let range = range as? TextRange else {
			return .zero
		}

		let offsetAtStartOfFirstRect = range.range.startIndex
		let offsetAtEndOfLine = ((range.range.startIndex / wordsPerLine) + 1) * wordsPerLine - 1 // Last offset still included in line
		let offsetAtEndOfFirstRect = min(offsetAtEndOfLine, range.range.endIndex)

		if let rectAtStartOfFirstRect = rectForAtomicWordGroup(at: offsetAtStartOfFirstRect), let rectAtEndOfFirstRect = rectForAtomicWordGroup(at: offsetAtEndOfFirstRect) {
			return rectAtStartOfFirstRect.union(rectAtEndOfFirstRect)
		} else {
			return .zero
		}
	}

	func caretRect(for position: UITextPosition) -> CGRect {
		let position = position as! TextPosition

		guard let rect = rectForAtomicWordGroup(at: position.index) else {
			// TODO
			return CGRect(x: contentInsets.left, y: contentInsets.top, width: 2.0, height: estimatedLineHeight)//.zero
		}

		print(rect)
		return CGRect(x: rect.minX, y: rect.minY, width: 2.0, height: rect.height)
	}

	func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
		let rect = firstRect(for: range)
		print(rect)
		return [TextSelectionRect(rect: rect, containsStart: true, containsEnd: true)]
	}

	func closestPosition(to point: CGPoint) -> UITextPosition? {
		nil
	}

	func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
		nil
	}

	func characterRange(at point: CGPoint) -> UITextRange? {
		nil
	}
}
