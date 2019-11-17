//
//  EditorAtomicWordGroupLayer.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-17.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import QuartzCore

class EditorAtomicWordGroupLayer: CALayer {
	let wordOffset: Int

	init(wordOffset: Int) {
		self.wordOffset = wordOffset

		super.init()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
