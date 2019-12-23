//
//  EditorView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-06.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class EditorView: UIScrollView {
	private let hexContentView = EditorContentView()
	private let textContentView = EditorContentView()
	private let separatorViews = [UIView(), UIView(), UIView()]
	private let backgroundView = UIView()

	private var contentViews: [EditorContentView] {
		return [hexContentView, textContentView]
	}

	var hexDataSource: EditorDataSource? {
		get {
			return hexContentView.dataSource
		}
		set {
			hexContentView.dataSource = newValue
			setNeedsLayout()
		}
	}

	var textDataSource: EditorDataSource? {
		get {
			return textContentView.dataSource
		}
		set {
			textContentView.dataSource = newValue
			setNeedsLayout()
		}
	}

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

		contentViews.forEach { addSubview($0) }

		separatorViews.forEach { $0.backgroundColor = .separator }
		separatorViews.forEach { addSubview($0) }
	}

	override func layoutSubviews() {
		assert(separatorViews.count == contentViews.count + 1)

		let separatorViewSize = CGSize(width: 1.0 / UIScreen.main.scale, height: bounds.height)

		let totalContentWidth = contentViews.map { $0.size(for: bytesPerLine).width }.reduce(.zero) { $0 + $1 } + separatorViewSize.width * CGFloat(separatorViews.count)

		var origin = CGPoint(x: (bounds.width - totalContentWidth) / 2.0, y: .zero)
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
		
		contentSize = CGSize(width: totalContentWidth, height: contentViews.map { $0.frame.height }.max() ?? .zero)

		super.layoutSubviews()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
