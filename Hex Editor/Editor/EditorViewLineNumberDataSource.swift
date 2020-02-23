//
//  EditorViewLineNumberDataSource.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-16.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import Foundation

extension EditorView {
	struct LineNumberDataSource: EditorViewDataSource {
		var totalWordCount: Int
		var wordsPerLine: Int

		func atomicWordGroup(at wordIndex: Int) -> Self.AtomicWordGroup? {
			let startIndex = (wordIndex / wordsPerLine) * wordsPerLine
			let endIndex = startIndex + wordsPerLine

			return (text: String(format: "%X", startIndex), range: startIndex..<endIndex)
		}

		func value(for text: String, at wordIndex: Int, selectionMoved: Bool) -> (data: Data, moveSelectionBy: Int)? {
			nil
		}
	}
}
