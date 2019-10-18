//
//  WordCollection.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol WordCollection: Collection where Element == Word, Index == Int {
	associatedtype Word: UnsignedInteger, FixedWidthInteger
}

extension Array: WordCollection where Element: UnsignedInteger, Element: FixedWidthInteger {
	typealias Word = Element
}

extension UnsafeBufferPointer: WordCollection where Element: UnsignedInteger, Element: FixedWidthInteger {
	typealias Word = Element
}

import Foundation

extension ContiguousBytes {
	func copyWords<T>() -> UnsafeBufferPointer<T> where T: UnsignedInteger, T: FixedWidthInteger {
		withUnsafeBytes {
			return $0.bindMemory(to: T.self)
		}
	}
}
