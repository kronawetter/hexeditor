//
//  OffsetTreeNodePayload.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol OffsetTreeNodePayload {
	associatedtype Value
	typealias Offset = Int

	var size: Offset { get }
	
	init()
	
	// Offset: Relative within node
	// Returns offset delta if successful, nil otherwise
	mutating func insert(_ value: Value, at offset: Offset, size: Offset) -> Offset?
	
	subscript(offset: Offset) -> Value { get }
}
