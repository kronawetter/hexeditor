//
//  EditorDataSource.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-17.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol EditorDataSource {
	var totalWordCount: Int { get }
	func atomicWordGroup(at wordIndex: Int) -> (text: String, size: Int)
}
