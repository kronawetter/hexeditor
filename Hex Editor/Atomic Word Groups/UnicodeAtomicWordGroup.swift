//
//  UnicodeAtomicWordGroup.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

struct UnicodeAtomicWordGroup<Codec: ExtendedUnicodeCodec, Endianness: _ByteOrder, DataSource: FileAccessor>: AtomicWordGroup {
	let range: Range<DataSource.Index>
	let value: String

	static func create(for rangeOfInterest: Range<Index>, in manager: inout AtomicWordGroupManager<Self>) {
		let startIndex = max(rangeOfInterest.startIndex - (Codec.maximumNumberOfCodePointsPerScalar - 1), 0) // TODO: Replace 0 literal
		let dataSourceIterator: AnyIterator<Codec.CodeUnit> = manager.dataSource.iterator(for: startIndex)
		var iterator = dataSourceIterator.lazy.map { Endianness.convert($0) }.makeIterator()

		var parser = Codec.ForwardParser()
		var currentIndex = startIndex
		
		loop: while currentIndex < rangeOfInterest.upperBound {
			let group: Self?

			switch parser.parseScalar(from: &iterator) {
			case .emptyInput:
				break loop
				
			case .error(length: let length):
				if rangeOfInterest.contains(currentIndex) {
					group = UnicodeAtomicWordGroup(range: currentIndex..<(currentIndex + length), value: "�")
				} else {
					group = nil
				}

			case .valid(let result):
				let scalar = Codec.decode(result)
				let length = Codec.width(scalar)
				let string = scalar.properties.isWhitespace ? "" : String(scalar)

				group = UnicodeAtomicWordGroup(range: currentIndex..<(currentIndex + length), value: string)
			}

			if let group = group {
				manager.insert(group)
				currentIndex += group.size
			}
		}
	}
	
	static func update(for changedRange: Range<Index>, lengthDelta: Index, in manager: inout AtomicWordGroupManager<Self>) {
		
	}
}
