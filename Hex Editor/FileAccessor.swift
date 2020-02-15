//
//  FileAccessor.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-28.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol FileAccessor {
	typealias Index = Int

	var size: Int { get }
	func iterator<ReturnedElement: FixedWidthInteger>(for offset: Index) -> AnyIterator<ReturnedElement>
}
