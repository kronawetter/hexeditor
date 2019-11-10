//
//  EditorView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-06.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

protocol EditorViewDataSource {

}

class EditorView: UIScrollView {
	var dataSource: EditorViewDataSource? = nil
	let contentView: EditorContentView

	override init(frame: CGRect) {
		contentView = EditorContentView()

		super.init(frame: frame)

		addSubview(contentView)
	}

	override func layoutSubviews() {
		contentSize = contentView.sizeThatFits(bounds.size)
		contentView.frame.size = contentSize
		contentView.visibleRect = CGRect(origin: contentOffset, size: bounds.size)

		super.layoutSubviews()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
