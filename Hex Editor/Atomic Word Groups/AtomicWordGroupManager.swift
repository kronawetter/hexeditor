//
//  AtomicWordGroupManager.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct AtomicWordGroupManager<T: AtomicWordGroup> {
	let dataSource: T.DataSource
	var groups = OffsetTree<LinearOffsetTreeElementStorage<T>>()
	
	mutating func insert(_ group: T) {
		groups.insert(group, offset: group.range.startIndex) // TODO: No need to save full range
	}
	
	mutating func create(for rangeOfInterest: Range<T.Index>) {
		T.create(for: rangeOfInterest, in: &self)
	}
	
	mutating func update(for changedRange: Range<T.Index>, lengthDelta: T.Index) {
		T.update(for: changedRange, lengthDelta: lengthDelta, in: &self)
	}
}
