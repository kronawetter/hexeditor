//
//  OffsetTreeElementStorage.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol Sizeable {
	var size: Int { get }
}

protocol OffsetTreeElementStorage {
	associatedtype Element: Sizeable
	
	init(initialElement: Element)

	subscript(_ offset: Int) -> Element? { get }
	
	mutating func insert(_ element: Element, at offset: Int) -> Bool
}
