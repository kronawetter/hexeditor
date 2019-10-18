//
//  AtomicWordGroup.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol AtomicWordGroup {
	associatedtype DataSource: WordCollection
	
	var value: String { get }
	var range: /*DataSource.Indices*/Range<DataSource.Index> { get } // TODO
	
	static func create(for rangeOfInterest: DataSource.Indices, in manager: inout AtomicWordGroupManager<Self>)
	static func update(for changedRange: DataSource.Indices, lengthDelta: DataSource.Index, in manager: inout AtomicWordGroupManager<Self>)
}
