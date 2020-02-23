//
//  EditorViewDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-15.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import Foundation

protocol EditorViewDelegate {
	func editorView(_ editorView: EditorView, didInsert data: Data, at offset: Int, in contentView: EditorView.ContentView)
	func editorView(_ editorView: EditorView, didDeleteIn range: Range<Int>, in contentView: EditorView.ContentView)
	func editorView(_ editorView: EditorView, didChangeVisibleWordGroupTo range: Range<Int>)
}
