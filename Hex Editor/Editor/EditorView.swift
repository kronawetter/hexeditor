//
//  EditorView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-06.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class EditorView: UIScrollView {
	enum ContentView {
		case hex
		case text
	}

	private let lineNumberContentView = EditorContentView()
	private let hexContentView = EditorContentView()
	private let textContentView = EditorContentView()
	private let separatorViews = [UIView(), UIView(), UIView()]
	private let backgroundView = UIView()

	private var contentViews: [EditorContentView] {
		return [lineNumberContentView, hexContentView, textContentView]
	}

	var hexDataSource: EditorViewDataSource? {
		get {
			return hexContentView.dataSource
		}
		set {
			hexContentView.dataSource = newValue
			lineNumberDataSource.totalWordCount = newValue?.totalWordCount ?? 0
			lineNumberContentView.dataSource = lineNumberDataSource
			setNeedsLayout()
		}
	}

	var textDataSource: EditorViewDataSource? {
		get {
			return textContentView.dataSource
		}
		set {
			textContentView.dataSource = newValue
			setNeedsLayout()
		}
	}

	private var lineNumberDataSource = LineNumberDataSource(totalWordCount: 0, wordsPerLine: 16)

	var editorDelegate: EditorViewDelegate? = nil

	var bytesPerLine = 16 {
		didSet {
			lineNumberDataSource.wordsPerLine = bytesPerLine
			lineNumberContentView.dataSource = lineNumberDataSource
			setNeedsLayout()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = .secondarySystemBackground

		backgroundView.backgroundColor = .systemBackground
		addSubview(backgroundView)

		lineNumberContentView.editable = false
		lineNumberContentView.wordsPerWordSpacingGroup = bytesPerLine
		lineNumberContentView.textColor = .secondaryLabel
		lineNumberContentView.backgroundColor = .secondarySystemBackground

		textContentView.wordsPerWordSpacingGroup = bytesPerLine

		contentViews.forEach { addSubview($0) }

		separatorViews.forEach { $0.backgroundColor = .separator }
		separatorViews.forEach { addSubview($0) }
	}

	private var contentViewLayoutFinishedCounter = 0

	override func layoutSubviews() {
		assert(separatorViews.count == contentViews.count)

		let separatorViewSize = CGSize(width: 1.0 / UIScreen.main.scale, height: bounds.height)
		var separatorViewsIterator = separatorViews.makeIterator()

		let totalContentWidth = contentViews.map { $0.size(for: bytesPerLine).width }.reduce(.zero) { $0 + $1 } + separatorViewSize.width * CGFloat(separatorViews.count)

		let firstContentViewWidth = contentViews.first?.size(for: bytesPerLine).width ?? .zero
		let backgroundWidth = totalContentWidth - firstContentViewWidth

		var contentOrigin = CGPoint(x: max(((bounds.width - backgroundWidth) / 2.0) - firstContentViewWidth, .zero), y: .zero)
		let backgroundOrigin = CGPoint(x: contentOrigin.x + firstContentViewWidth, y: contentOrigin.y)

		backgroundView.frame.origin = CGPoint(x: backgroundOrigin.x, y: contentOffset.y)
		backgroundView.frame.size = CGSize(width: backgroundWidth, height: bounds.height)

		func layoutNextSeparator() {
			let separator = separatorViewsIterator.next()!

			separator.frame.origin = CGPoint(x: contentOrigin.x, y: contentOffset.y)
			separator.frame.size = separatorViewSize

			contentOrigin.x = separator.frame.maxX
		}

		for (index, contentView) in contentViews.enumerated() {
			if index != contentViews.startIndex {
				layoutNextSeparator()
			}

			contentView.frame.origin = contentOrigin
			contentView.frame.size = contentView.size(for: bytesPerLine)

			contentView.visibleRect = CGRect(x: .zero, y: contentOffset.y, width: contentView.bounds.width, height: bounds.height)

			contentOrigin.x = contentView.frame.maxX
		}

		layoutNextSeparator()
		
		contentSize = CGSize(width: max(bounds.width, totalContentWidth), height: contentViews.map { $0.frame.height }.max() ?? .zero)

		contentViewLayoutFinishedCounter = 0
		super.layoutSubviews()
	}

	func insert(text: String, at offset: Int, in contentView: EditorContentView) -> Int {
		editorDelegate?.editorView(self, didInsert: text, at: offset, in: contentViewEnumValue(for: contentView)) ?? 0
	}

	func delete(at offset: Int, in contentView: EditorContentView) {
		editorDelegate?.editorView(self, didDeleteAt: offset, in: contentViewEnumValue(for: contentView))
	}

	func contentViewDidLayout(_ contentView: EditorContentView) {
		contentViewLayoutFinishedCounter += 1
		if contentViewLayoutFinishedCounter == contentViews.count {
			// Not needed for now as Emojis have same height as regular characters
			// alignVisibleWordGroupsInContentViews()
			editorDelegate?.editorView(self, didChangeVisibleWordGroupTo: offsetRangeOfVisibleWordGroups)
		}
	}

	func alignVisibleWordGroupsInContentViews() {
		hexContentView.alignVisibleAtomicWordGroup(to: textContentView.rectsOfVisibleAtomicWordGroups)
	}

	func contentViewEnumValue(for contentView: EditorContentView) -> ContentView {
		if contentView === hexContentView {
			return .hex
		} else if contentView === textContentView {
			return .text
		} else {
			preconditionFailure()
		}
	}

	var offsetRangeOfVisibleWordGroups: Range<Int> {
		let ranges = contentViews.compactMap { view -> Range<Int>? in
			let offsets = view.rectsOfVisibleAtomicWordGroups.keys
			if let min = offsets.min(), let max = offsets.max() {
				let range = min..<(max + 1)
				if !range.isEmpty {
					return range
				}
			}
			return nil
		}

		return (ranges.map { $0.lowerBound }.min() ?? 0)..<(ranges.map { $0.upperBound }.max() ?? 0)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
