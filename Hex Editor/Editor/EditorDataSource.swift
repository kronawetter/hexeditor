//
//  EditorDataSource.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-17.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol EditorDataSource {
	typealias AtomicWordGroup = (text: String, range: Range<Int>)

	var totalWordCount: Int { get }
	func atomicWordGroup(at wordIndex: Int) -> AtomicWordGroup
	mutating func insert(_ text: String, at wordIndex: Int) -> Int // returns number of inserted word groups
}
