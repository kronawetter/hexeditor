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

	private let hexContentView = EditorContentView()
	private let textContentView = EditorContentView()
	private let separatorViews = [UIView(), UIView(), UIView()]
	private let backgroundView = UIView()

	private var contentViews: [EditorContentView] {
		return [hexContentView, textContentView]
	}

	var hexDataSource: EditorViewDataSource? {
		get {
			return hexContentView.dataSource
		}
		set {
			hexContentView.dataSource = newValue
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

	var editorDelegate: EditorViewDelegate? = nil

	var bytesPerLine = 16 {
		didSet {
			setNeedsLayout()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = .secondarySystemBackground

		backgroundView.backgroundColor = .systemBackground
		addSubview(backgroundView)

		textContentView.wordsPerWordSpacingGroup = bytesPerLine
		contentViews.forEach { addSubview($0) }

		separatorViews.forEach { $0.backgroundColor = .separator }
		separatorViews.forEach { addSubview($0) }
	}

	private var contentViewLayoutFinishedCounter = 0

	override func layoutSubviews() {
		assert(separatorViews.count == contentViews.count + 1)

		let separatorViewSize = CGSize(width: 1.0 / UIScreen.main.scale, height: bounds.height)

		let totalContentWidth = contentViews.map { $0.size(for: bytesPerLine).width }.reduce(.zero) { $0 + $1 } + separatorViewSize.width * CGFloat(separatorViews.count)

		var origin = CGPoint(x: max((bounds.width - totalContentWidth) / 2.0, .zero), y: .zero)
		var separatorViewsIterator = separatorViews.makeIterator()

		backgroundView.frame.origin = CGPoint(x: origin.x, y: contentOffset.y)
		backgroundView.frame.size = CGSize(width: totalContentWidth, height: bounds.height)

		func layoutNextSeparator() {
			let separator = separatorViewsIterator.next()!

			separator.frame.origin = CGPoint(x: origin.x, y: contentOffset.y)
			separator.frame.size = separatorViewSize

			origin.x = separator.frame.maxX
		}

		for contentView in contentViews {
			layoutNextSeparator()

			contentView.frame.origin = origin
			contentView.frame.size = contentView.size(for: bytesPerLine)

			contentView.visibleRect = CGRect(x: .zero, y: contentOffset.y, width: contentView.bounds.width, height: bounds.height)

			origin.x = contentView.frame.maxX
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
			let range = (offsets.min() ?? 0)..<(offsets.max() ?? 0)

			if range.isEmpty {
				return nil
			} else {
				return range
			}
		}

		return (ranges.map { $0.lowerBound }.min() ?? 0)..<(ranges.map { $0.upperBound }.max() ?? 0)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
