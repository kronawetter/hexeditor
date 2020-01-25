//
//  OffsetTreeElement.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol OffsetTreeElement {
	associatedtype Value

	var size: Int { get }
	func value(for range: Range<Int>) -> Value? // range relative to offset of node
	mutating func replace(in range: Range<Int>, with value: Value) -> Bool
	mutating func split(at offset: Int) -> Self
}
