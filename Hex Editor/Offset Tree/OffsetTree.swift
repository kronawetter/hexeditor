//
//  OffsetTree.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct OffsetTree<Element> {
	var root: Node? = nil
	
	mutating func insert(_ element: Element, range: Range<Int>) {
		if let root = root {
			root.insert(element, range: range)
		} else {
			root = Node(initialElement: element, range: range)
		}
	}
}
