//
//  AtomicWordGroupManager.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct AtomicWordGroupManager<T: AtomicWordGroup> {
	let dataSource: T.DataSource
	//var groups = OffsetTree<ContigiousOffsetTreeElementStorage<T>>()
	
	mutating func insert(_ group: T) {
		
	}
	
	mutating func create(for rangeOfInterest: T.DataSource.Indices) {
		T.create(for: rangeOfInterest, in: &self)
	}
	
	mutating func update(for changedRange: T.DataSource.Indices, lengthDelta: T.DataSource.Index) {
		T.update(for: changedRange, lengthDelta: lengthDelta, in: &self)
	}
}
