//
//  ContigiousOffsetTreeNodePayload.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct ContigiousOffsetTreeNodePayload<Value>: OffsetTreeNodePayload {
	struct Element {
		let value: Value
		let size: Offset
	}
	
	var size: Offset = 0
	var elements: [Element] = []
	
	init() {
		
	}
	
	mutating func insert(_ value: Value, at offset: Offset, size: Offset) -> Offset? {
		let element = Element(value: value, size: size)
		self.size += size
		
		var currentOffset = 0
		
		if offset == size * -1 {
			elements.insert(element, at: 0)
			return size * -1
		} else {
			for (index, existingElement) in elements.enumerated() {
				if currentOffset == offset {
					elements.insert(element, at: index)
					return 0
				}
				currentOffset += existingElement.size
			}
			precondition(currentOffset == offset)
			elements.append(element)
			return 0
		}
	}
	
	subscript(offset: Offset) -> Value {
		return elements[offset].value
	}
}
