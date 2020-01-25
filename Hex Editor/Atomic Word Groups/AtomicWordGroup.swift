//
//  AtomicWordGroup.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol AtomicWordGroup {
	associatedtype DataSource: FileAccessor
	typealias Index = DataSource.Index

	var value: String { get }
	var range: Range<Index> { get }
	
	static func create(for rangeOfInterest: Range<Index>, in manager: inout AtomicWordGroupManager<Self>)
	static func update(for changedRange: Range<Index>, lengthDelta: Index, in manager: inout AtomicWordGroupManager<Self>)
}

extension AtomicWordGroup {
	var size: Int {
		return range.count
	}
}
