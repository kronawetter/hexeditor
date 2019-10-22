//
//  LinearOffsetTreeElementStorage.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol Sizeable {
	var size: Int { get }
}

struct LinearOffsetTreeElementStorage<Element: Sizeable>: OffsetTreeElementStorage {
	var elements: [Element] = []
	
	mutating func insert(_ element: Element, at offset: Int) {
		var currentOffset = 0
		for index in elements.indices {
			precondition(offset <= currentOffset)
			if offset == currentOffset {
				elements.insert(element, at: index)
			}
			currentOffset += elements[index].size
		}
		elements.append(element)
	}
}
