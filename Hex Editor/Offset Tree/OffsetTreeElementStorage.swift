//
//  OffsetTreeElementStorage.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-22.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol OffsetTreeElementStorage {
	associatedtype Element
	
	mutating func insert(_ element: Element, at offset: Int)
}
