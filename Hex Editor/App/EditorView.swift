//
//  EditorView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-06.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

protocol EditorDataSource {
	var totalWordCount: Int { get }
	func atomicWordGroups(for wordRange: Range<Int>) -> [(text: String, size: Int)]
	func atomicWordGroup(at wordIndex: Int) -> (text: String, size: Int)
}

class EditorView: UIScrollView {
	var dataSource: EditorDataSource? = nil {
		didSet {
			contentView.dataSource = dataSource
		}
	}

	let contentView: EditorContentView

	override init(frame: CGRect) {
		contentView = EditorContentView()

		super.init(frame: frame)

		addSubview(contentView)
	}

	override func layoutSubviews() {
		let desiredContentViewSize = CGSize(width: bounds.width / 2.0, height: .infinity)

		let contentViewSize = contentView.sizeThatFits(desiredContentViewSize)
		let contentViewOrigin = CGPoint(x: (bounds.width - contentViewSize.width) / 2.0, y: 0.0)

		contentView.frame = CGRect(origin: contentViewOrigin, size: contentViewSize)
		contentView.visibleRect = CGRect(origin: contentOffset, size: bounds.size)
		
		contentSize = contentViewSize

		super.layoutSubviews()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
