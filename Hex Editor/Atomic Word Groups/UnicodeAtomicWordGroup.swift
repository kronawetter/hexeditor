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
			switch parser.parseScalar(from: &iterator) {
			case .emptyInput:
				break loop
				
			case .error(length: let length):
				if rangeOfInterest.contains(currentIndex) {
					let group = UnicodeAtomicWordGroup(range: currentIndex..<(currentIndex + length), value: "�")
					manager.insert(group)
					//print("Error (\(length))")
				} else {
					//print("Error: (\(length), Ignored)")
				}
				
				currentIndex += length
				
			case .valid(let result):
				let scalar = Codec.decode(result)
				let length = Codec.width(scalar)

				let value: String
				if scalar.properties.isWhitespace {
					value = ""
				} else {
					value = String(scalar)
				}

				let group = UnicodeAtomicWordGroup(range: currentIndex..<(currentIndex + length), value: value)
				manager.insert(group)
				//print("\(scalar): \(length)")
								
				currentIndex += length
			}
		}
	}
	
	static func update(for changedRange: DataSource.Indices, lengthDelta: DataSource.Index, in manager: inout AtomicWordGroupManager<UnicodeAtomicWordGroup<Codec, Endianness, DataSource>>) {
		
	}
}
