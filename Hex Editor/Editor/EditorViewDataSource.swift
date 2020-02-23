//
//  EditorViewDataSource.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-17.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

protocol EditorViewDataSource {
	typealias AtomicWordGroup = (text: String, range: Range<Int>)

	var totalWordCount: Int { get }
	func atomicWordGroup(at wordIndex: Int) -> AtomicWordGroup?

	func value(for text: String, at wordIndex: Int, selectionMoved: Bool) -> (data: Data, moveSelectionBy: Int)?
}
