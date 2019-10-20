//
//  UnicodeAtomicWordGroup.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct UnicodeAtomicWordGroup<Codec: ExtendedUnicodeCodec, Endianness: _ByteOrder, DataSource: WordCollection>: AtomicWordGroup where Codec.CodeUnit == DataSource.Element {
	let range: Range<DataSource.Index>
	let value: String
	
	static func create(for rangeOfInterest: DataSource.Indices, in manager: inout AtomicWordGroupManager<UnicodeAtomicWordGroup<Codec, Endianness, DataSource>>) {
		let unclampedStartIndex = rangeOfInterest.startIndex - (Codec.maximumNumberOfCodePointsPerScalar - 1)
		let unclampedEndIndex = rangeOfInterest.endIndex + (Codec.maximumNumberOfCodePointsPerScalar - 1)
		let unclampedRange = unclampedStartIndex..<unclampedEndIndex
		
		let maximumRange = manager.dataSource.startIndex..<manager.dataSource.endIndex
		let clampedRange = unclampedRange.clamped(to: maximumRange)
		
		let data = manager.dataSource[clampedRange].lazy.map { Endianness.convert($0) }
		var iterator = data.makeIterator()
		var parser = Codec.ForwardParser()
		var currentIndex = clampedRange.startIndex
		
		loop: while true {
			//print("Index: \(currentIndex)")
			switch parser.parseScalar(from: &iterator) {
			case .emptyInput:
				break loop
				
			case .error(length: let length):
				if (currentIndex >= rangeOfInterest.startIndex) {
					let group = UnicodeAtomicWordGroup(range: currentIndex..<(currentIndex + length), value: "Invalid")
					manager.groups.insert(group, at: currentIndex, size: length)
					
					//print("→ Invalid, not ignored (length \(length))")
				} else {
					//print("→ Invalid, ignored (length \(length))")
				}
				
				currentIndex += length
				
			case .valid(let result):
				let scalar = Codec.decode(result)
				let length = Codec.width(scalar)
				
				let group = UnicodeAtomicWordGroup(range: currentIndex..<(currentIndex + length), value: String(scalar))
				manager.groups.insert(group, at: currentIndex, size: length)
				
				//print("→ \(scalar) (length \(length))")
				
				currentIndex += length
			}
		}
	}
	
	static func update(for changedRange: DataSource.Indices, lengthDelta: DataSource.Index, in manager: inout AtomicWordGroupManager<UnicodeAtomicWordGroup<Codec, Endianness, DataSource>>) {
		
	}
}
