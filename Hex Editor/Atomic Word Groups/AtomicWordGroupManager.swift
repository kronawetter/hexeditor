//
//  AtomicWordGroupManager.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct AtomicWordGroupManager<T: AtomicWordGroup> {
	let dataSource: T.DataSource
	var groups = OffsetTree<[T]>()

	struct Element: OffsetTreeElement {
		typealias Value = [T]

		let value: T

		var size: Int {
			value.size
		}

		func value(for range: Range<Int>) -> [T]? {
			[value]
		}

		func replace(in range: Range<Int>, with value: [T]) -> Bool {
			preconditionFailure()
		}

		func split(at offset: Int) -> AtomicWordGroupManager<T>.Element {
			preconditionFailure()
		}
	}
	
	mutating func insert(_ group: T) {
		let element = Element(value: group)
		if groups[group.range.startIndex] == nil {
			groups.insert(element, offset: group.range.startIndex)
		}
	}
	
	mutating func create(for rangeOfInterest: Range<T.Index>) {
		T.create(for: rangeOfInterest, in: &self)
	}
	
	/*mutating func update(for changedRange: Range<T.Index>, lengthDelta: T.Index) {
		T.update(for: changedRange, lengthDelta: lengthDelta, in: &self)
	}*/
}

extension AtomicWordGroupManager: EditorViewDataSource {
	var totalWordCount: Int {
		// TODO: This only works when word size is constantly 1 byte
		//       Ideally, AtomicWordGroupManager doesn't need to know how many words exist in the data source as this might be expensive to compute
		dataSource.size
	}

	func atomicWordGroup(at wordIndex: Int) -> EditorViewDataSource.AtomicWordGroup? {
		guard let data = groups[wordIndex] else {
			return nil
		}

		return (text: data.value, range: data.range)
	}
}
