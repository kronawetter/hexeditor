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
			removeSublayers()
			setNeedsLayout()
		}
	}

	var dataSource: EditorViewDataSource? = nil {
		didSet {
			removeSublayers()
			setNeedsLayout()
		}
	}

	var delegate: EditorViewDelegate? = nil

	var visibleRect = CGRect.zero {
		didSet {
			if visibleRect != oldValue {
				layer.setNeedsLayout()
			}
		}
	}

	var contentInsets = UIEdgeInsets(top: 2.0, left: 10.0, bottom: 10.0, right: 10.0) {
		didSet {
			removeSublayers()
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

	var wordsPerWordSpacingGroup = 2 {
		didSet {
			removeSublayers()
			setNeedsLayout()
		}
	}

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

	private func estimatedFrame(for offset: Int) -> CGRect {
		// TODO: Handle multi-word groups

		let (lineOffset, offsetInLine) = offset.quotientAndRemainder(dividingBy: wordsPerLine)
		return CGRect(x: CGFloat(offsetInLine) * widthPerWord + CGFloat(offsetInLine / wordsPerWordSpacingGroup) * wordGroupSpacingWidth + contentInsets.left, y: CGFloat(lineOffset) * estimatedLineHeight, width: widthPerWord, height: estimatedLineHeight)
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
			print(selection as Any)
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
	}

	override func becomeFirstResponder() -> Bool {
		addInteraction(textInteraction)

		return super.becomeFirstResponder()
	}

	override func resignFirstResponder() -> Bool {
		defer {
			removeInteraction(textInteraction)
		}

		return super.resignFirstResponder()
	}

	override func layoutSubviews() {
		inputDelegate?.textWillChange(self)

		removeSublayersOutsideVisibleRect()
		addMissingWordGroupSublayersAtBegin()
		addMissingWordGroupSublayersAtEnd()

		super.layoutSubviews()

		inputDelegate?.textDidChange(self)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func removeSublayers(filter: (EditorAtomicWordGroupLayer) -> Bool = { _ in true }) {
		if let sublayers = layer.sublayers {
			sublayers.filter { $0 is EditorAtomicWordGroupLayer && filter($0 as! EditorAtomicWordGroupLayer) } .forEach { $0.removeFromSuperlayer() }
		}
	}

	private func removeSublayersOutsideVisibleRect() {
		removeSublayers { !$0.frame.intersects(visibleRect) }
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
			let wordGroup = dataSource.atomicWordGroup(at: currentOffset) ?? (text: "", range: currentOffset..<(currentOffset + 1))// TODO: Make return type a struct with member function `size`, so wordGroup.range.count can be replaced with wordGroup.size

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

			if offset < dataSource!.totalWordCount, origin.y < visibleRect.maxY {
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
			_ = becomeFirstResponder()
		}
	}

	private func rectForAtomicWordGroup(at offset: Int) -> CGRect? {
		guard let dataSource = dataSource, let sublayers = layer.sublayers else {
			return nil
		}

		if let wordGroup = dataSource.atomicWordGroup(at: offset), let sublayer = sublayers.first(where: { ($0 as? EditorAtomicWordGroupLayer)?.wordOffset == wordGroup.range.startIndex }) {
			return sublayer.frame
		} else {
			return estimatedFrame(for: offset)
		}
	}

	private func rectsForAtomicWordGroups(in range: Range<Int>) -> [CGRect] {
		// First rect
		let firstRect: CGRect?

		let offsetAtStartOfFirstRect = range.startIndex
		let offsetAtEndOfFirstLine = ((offsetAtStartOfFirstRect / wordsPerLine) + 1) * wordsPerLine - 1 // Last offset still included in line
		let offsetAtEndOfFirstRect = min(offsetAtEndOfFirstLine, range.endIndex - 1)

		if let rectAtStartOfFirstRect = rectForAtomicWordGroup(at: offsetAtStartOfFirstRect), let rectAtEndOfFirstRect = rectForAtomicWordGroup(at: offsetAtEndOfFirstRect) {
			firstRect = rectAtStartOfFirstRect.union(rectAtEndOfFirstRect)
		} else {
			firstRect = nil
		}

		// Last rect
		let lastRect: CGRect?

		let offsetAtEndOfLastRect = range.endIndex - 1
		if offsetAtEndOfLastRect > offsetAtEndOfFirstRect {
			let offsetAtStartOfLastRect = (offsetAtEndOfLastRect / wordsPerLine) * wordsPerLine

			if let rectAtStartOfLastRect = rectForAtomicWordGroup(at: offsetAtStartOfLastRect), let rectAtEndOfLastRect = rectForAtomicWordGroup(at: offsetAtEndOfLastRect) {
				lastRect = rectAtStartOfLastRect.union(rectAtEndOfLastRect)
			} else {
				lastRect = nil
			}
		} else {
		   lastRect = nil
		}

		// Middle rect
		let middleRect: CGRect?

		if let firstRect = firstRect, let lastRect = lastRect, lastRect.maxY > firstRect.maxY {
			middleRect = CGRect(x: lastRect.minX, y: firstRect.maxY, width: firstRect.maxX - lastRect.minX, height: lastRect.minY - firstRect.maxY)
		} else {
			middleRect = nil
		}

		return [firstRect, middleRect, lastRect].compactMap { $0 }
	}

	var offsetRangeOfVisibleWordGroups: Range<Int> {
		guard let sublayers = layer.sublayers else {
			return 0..<0
		}

		let offsets = sublayers.compactMap { ($0 as? EditorAtomicWordGroupLayer)?.wordOffset }
		return (offsets.min() ?? 0)..<(offsets.max() ?? 0)
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
		guard let selection = selection else {
			return
		}

		let insertedWordGroups = delegate?.editorView(superview as! EditorView, didInsert: text, at: selection.lowerBound) ?? 0
		self.selection = (selection.startIndex + insertedWordGroups)..<(selection.endIndex + insertedWordGroups)
	}

	func deleteBackward() {
		guard let selection = selection, selection.startIndex > 0 else {
			return
		}

		delegate?.editorView(superview as! EditorView, didDeleteAt: selection.startIndex - 1)
		self.selection = (selection.startIndex - 1)..<(selection.startIndex - 1)
	}

	var isSecureTextEntry: Bool {
		get {
			false
		}
		set {

		}
	}

	var autocorrectionType: UITextAutocorrectionType {
		get {
			.no
		}
		set {

		}
	}
}

extension EditorContentView: UITextInput {
	class Tokenizer: NSObject, UITextInputTokenizer {
		weak var contentView: EditorContentView?

		func rangeEnclosingPosition(_ position: UITextPosition, with granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextRange? {
			guard let contentView = contentView, let position = position as? TextPosition else {
				return nil
			}

			switch granularity {
			case .character:
				return TextRange(position.index..<position.index + 1)
			case .paragraph:
				fallthrough
			case .line:
				return TextRange(((position.index / contentView.wordsPerLine) * contentView.wordsPerLine)..<position.index)
			case .document:
				return TextRange(0..<(contentView.dataSource?.totalWordCount ?? 0))
			default:
				return nil
			}
		}

		func isPosition(_ position: UITextPosition, atBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
			guard let contentView = contentView, let position = position as? TextPosition else {
				return false
			}

			switch granularity {
			case .character:
				return true
			case .paragraph:
				fallthrough
			case .line:
				if direction == .storage(.forward) || direction == .layout(.right) || direction == .layout(.down) {
					return (position.index + 1).isMultiple(of: contentView.wordsPerLine)
				} else if direction == .storage(.backward) || direction == .layout(.left) || direction == .layout(.up) {
					return position.index.isMultiple(of: contentView.wordsPerLine)
				} else {
					preconditionFailure()
				}
			case .document:
				if direction == .storage(.forward) || direction == .layout(.right) || direction == .layout(.down) {
					return position.index == contentView.dataSource?.totalWordCount ?? 0
				} else if direction == .storage(.backward) || direction == .layout(.left) || direction == .layout(.up) {
					return position.index == 0
				} else {
					preconditionFailure()
				}
			default:
				return false
			}
		}

		func position(from position: UITextPosition, toBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextPosition? {
			guard let contentView = contentView, let position = position as? TextPosition else {
				return nil
			}

			switch granularity {
			case .character:
				return position
			case .paragraph:
				fallthrough
			case .line:
				if direction == .storage(.forward) || direction == .layout(.right) || direction == .layout(.down) {
					return TextPosition((position.index / contentView.wordsPerLine + 1) * contentView.wordsPerLine - 1)
				} else if direction == .storage(.backward) || direction == .layout(.left) || direction == .layout(.up) {
					return TextPosition((position.index / contentView.wordsPerLine) * contentView.wordsPerLine)
				} else {
					preconditionFailure()
				}
			case .document:
				if direction == .storage(.forward) || direction == .layout(.right) || direction == .layout(.down) {
					return TextPosition(contentView.dataSource?.totalWordCount ?? 0)
				} else if direction == .storage(.backward) || direction == .layout(.left) || direction == .layout(.up) {
					return TextPosition(0)
				} else {
					preconditionFailure()
				}
			default:
				return nil
			}
		}

		func isPosition(_ position: UITextPosition, withinTextUnit granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
			guard let contentView = contentView, let position = position as? TextPosition else {
				return false
			}

			switch granularity {
			case .character:
				return true
			case .paragraph:
				fallthrough
			case .line:
				if direction == .storage(.forward) || direction == .layout(.right) || direction == .layout(.down) {
					return true
				} else if direction == .storage(.backward) || direction == .layout(.left) || direction == .layout(.up) {
					return !position.index.isMultiple(of: contentView.wordsPerLine)
				} else {
					preconditionFailure()
				}
			case .document:
				return true
			default:
				return false
			}
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

		if fromPosition.index <= toPosition.index {
			return TextRange(fromPosition.index..<toPosition.index)
		} else {
			return TextRange(toPosition.index..<fromPosition.index)
		}
	}

	func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
		guard let position = position as? TextPosition, let dataSource = dataSource else {
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
		guard let position = position as? TextPosition else {
			return nil
		}

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
		guard let position = position as? TextPosition, let other = other as? TextPosition else {
			return .orderedSame
		}

		if position.index < other.index {
			return .orderedAscending
		} else if position.index > other.index {
			return .orderedDescending
		} else {
			return .orderedSame
		}
	}

	func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
		guard let from = from as? TextPosition, let toPosition = toPosition as? TextPosition else {
			return 0
		}

		// TODO: UTF-16 characters?!
		return toPosition.index - from.index
	}

	var tokenizer: UITextInputTokenizer {
		let tokenizer = Tokenizer()
		tokenizer.contentView = self
		return tokenizer
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
		guard let position = position as? TextPosition, let dataSource = dataSource else {
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

		return rectsForAtomicWordGroups(in: range.range).first ?? .zero
	}

	func caretRect(for position: UITextPosition) -> CGRect {
		let fallbackRect = CGRect(x: contentInsets.left, y: contentInsets.top, width: 2.0, height: estimatedLineHeight)

		guard let position = position as? TextPosition, let dataSource = dataSource else {
			return fallbackRect
		}

		assert(position.index <= dataSource.totalWordCount)
		if position.index < dataSource.totalWordCount {
			guard let rect = rectForAtomicWordGroup(at: position.index) else {
				return fallbackRect
			}

			return CGRect(x: rect.minX, y: rect.minY, width: 2.0, height: rect.height)
		} else {
			guard let rect = rectForAtomicWordGroup(at: dataSource.totalWordCount - 1) else {
				return fallbackRect
			}

			let offsetInLine = position.index % wordsPerLine
			let wordGroupSpacingRequired = offsetInLine.isMultiple(of: wordsPerWordSpacingGroup)

			return CGRect(x: rect.maxX + (wordGroupSpacingRequired ? wordGroupSpacingWidth : .zero), y: rect.minY, width: 2.0, height: rect.height)
		}
	}

	func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
		guard let range = range as? TextRange else {
			return []
		}

		let rects = rectsForAtomicWordGroups(in: range.range)
		
		return rects.enumerated().map { (index, rect) in
			let containsStart = index == rects.startIndex
			let containsEnd = index == rects.endIndex - 1

			return TextSelectionRect(rect: rect, containsStart: containsStart, containsEnd: containsEnd)
		}
	}

	func closestPosition(to point: CGPoint) -> UITextPosition? {
		// TODO: Hit test is insufficient
		let point = layer.convert(point, to: layer.superlayer)

		guard let wordGroupLayer = layer.hitTest(point) as? EditorAtomicWordGroupLayer else {
			return TextPosition(0)
		}

		return TextPosition(wordGroupLayer.wordOffset)
	}

	func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
		// TODO: Hit test is insufficient
		guard let closestPosition = closestPosition(to: point) as? TextPosition, let range = range as? TextRange else {
			return TextPosition(0)
		}

		if range.range.contains(closestPosition.index) {
			return closestPosition
		} else {
			return TextPosition(0)
		}
	}

	func characterRange(at point: CGPoint) -> UITextRange? {
		// TODO: Hit test is insufficient
		guard let closestPosition = closestPosition(to: point) as? TextPosition else {
			return TextRange(0..<0)
		}

		return TextRange(closestPosition.index..<(closestPosition.index + 1))
	}
}
