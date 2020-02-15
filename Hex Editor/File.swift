//
//  File.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

struct File {
	struct FileSegment: OffsetTreeElement {
		typealias Value = Data

		let fileHandle: FileHandle
		var rangeInFile: Range<Int>

		var size: Int {
			rangeInFile.count
		}

		func value(for range: Range<Int>) -> Value? { // range relative to rangeInFile.startIndex (kinda)
			precondition(range.endIndex <= rangeInFile.count)
			let offset = UInt64(rangeInFile.startIndex + range.startIndex)

			do {
				try fileHandle.seek(toOffset: offset)
			} catch _ {
				return nil
			}

			return fileHandle.readData(ofLength: range.count)
		}

		func replace(in range: Range<Int>, with value: Value) -> Bool {
			false
		}

		mutating func split(at offset: Int) -> Self {
			precondition(offset < rangeInFile.count)

			let rangeInFileOfFirstSegment = rangeInFile.startIndex..<(rangeInFile.startIndex + offset)
			let rangeInFileOfSecondSegment = (rangeInFile.startIndex + offset)..<rangeInFile.endIndex

			rangeInFile = rangeInFileOfFirstSegment
			return Self(fileHandle: fileHandle, rangeInFile:rangeInFileOfSecondSegment)
		}
	}

	struct ChangeSegment: OffsetTreeElement {
		typealias Value = Data
		var data = Data()

		var size: Int {
			data.count
		}

		func value(for range: Range<Int>) -> Self.Value? {
			return data[range]
		}

		mutating func replace(in range: Range<Int>, with value: Self.Value) -> Bool {
			data.replaceSubrange(range, with: value)
			return true
		}

		mutating func split(at offset: Int) -> File.ChangeSegment {
			let new = data.dropFirst(offset)
			data.removeLast(data.count - offset)
			return Self(data: Data(new))
		}
	}

	let url: URL
	var size: Int
	var contents = OffsetTree<Data>()
	let fileHandle: FileHandle

	init(url: URL) throws {
		self.url = url

		size = (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize!
		fileHandle = try FileHandle(forUpdating: url)

		let segment = FileSegment(fileHandle: fileHandle, rangeInFile: 0..<size)
		contents.insert(segment, offset: 0)
	}

	mutating func insert(_ data: Data, at wordIndex: Int) {
		contents.split(at: wordIndex)
		let element = ChangeSegment(data: data)
		contents.insert(element, offset: wordIndex)

		size += data.count
	}

	mutating func remove(at wordIndex: Int) {
		contents.split(at: wordIndex)
		contents.split(at: wordIndex + 1)
		contents.remove(at: wordIndex)

		size -= 1
	}
}

extension File: EditorViewDataSource {
	var totalWordCount: Int {
		return size
	}

	func atomicWordGroup(at wordIndex: Int) -> EditorViewDataSource.AtomicWordGroup {
		return (text: String(format: "%02X", contents[wordIndex]!), range: wordIndex..<(wordIndex + 1))
	}
}

extension File: FileAccessor {
	func iterator<ReturnedElement>(for offset: Self.Index) -> AnyIterator<ReturnedElement> where ReturnedElement : FixedWidthInteger {
		// TODO: Only supports UInt8 as ReturnedElement
		AnyIterator(contents.iterator(startingAt: offset)) as! AnyIterator<ReturnedElement>
	}
}
