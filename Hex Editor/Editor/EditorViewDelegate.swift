//
//  EditorViewDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-15.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

protocol EditorViewDelegate {
	func editorView(_ editorView: EditorView, didInsert text: String, at offset: Int) -> Int // returns number of inserted word groups
	func editorView(_ editorView: EditorView, didDeleteAt offset: Int)
}
