//
//  LinearOffsetTreeElementStorage.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct LinearOffsetTreeElementStorage<Element: Sizeable>: OffsetTreeElementStorage {
	var elements: [Element] = []
	
	init(initialElement: Element) {
		elements = [initialElement]
	}
	
	mutating func insert(_ element: Element, at offset: Int) -> Bool {
		guard elements.count < 100 else {
			return false
		}
		
		var currentOffset = 0
		
		for index in elements.indices {
			if offset == currentOffset {
				elements.insert(element, at: index)
				return true
			}
			currentOffset += elements[index].size
		}
		
		precondition(currentOffset == offset)
		elements.append(element)
		return true
	}
}
