//
//  OffsetTreeElement.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

protocol OffsetTreeElement {
	associatedtype Value: Collection

	var size: Int { get }
	func value(for range: Range<Int>) -> Value? // range relative to offset of node
	mutating func replace(in range: Range<Int>, with value: Value) -> Bool
	mutating func split(at offset: Int) -> Self
}

class AnyOffsetTreeElement<Value: Collection>: OffsetTreeElement {
	static func make<Element: OffsetTreeElement>(_ element: Element) -> AnyOffsetTreeElement<Element.Value> where Element.Value == Value {
		AnyOffsetTreeElementImpl(element)
	}

	var size: Int {
		preconditionFailure()
	}

	func value(for range: Range<Int>) -> Value? {
		preconditionFailure()
	}

	func replace(in range: Range<Int>, with value: Value) -> Bool {
		preconditionFailure()
	}

	func split(at offset: Int) -> Self {
		preconditionFailure()
	}
}

fileprivate class AnyOffsetTreeElementImpl<Element: OffsetTreeElement>: AnyOffsetTreeElement<Element.Value> {
	var wrapped: Element

	required init(_ element: Element) {
		wrapped = element
	}

	override var size: Int {
		wrapped.size
	}

	override func value(for range: Range<Int>) -> Value? {
		wrapped.value(for: range)
	}

	override func replace(in range: Range<Int>, with value: Value) -> Bool {
		wrapped.replace(in: range, with: value)
	}

	override func split(at offset: Int) -> Self {
		.init(wrapped.split(at: offset))
	}
}
