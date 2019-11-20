//
//  DataOffsetTreeElementStorage.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-19.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

struct DataOffsetTreeElementStorage: OffsetTreeElementStorage {
	typealias Element = Data.Element
	typealias Elements = Data

	var data: Elements

	init(initialElement: Element) {
		data = Data(repeating: initialElement, count: 1)
	}

	init(initialElements: Elements) {
		data = initialElements
	}

	subscript(_ offset: Int) -> Element? {
		return data[offset]
	}

	mutating func insert(_ element: Element, at offset: Int) -> Bool {
		data.insert(element, at: offset)
		return true
	}
}
