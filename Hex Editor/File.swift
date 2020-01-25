//
//  File.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

struct File {
	struct Segment: OffsetTreeElement {
		typealias Value = Data

		let fileHandle: FileHandle
		var rangeInFile: Range<Int>

		var size: Int {
			rangeInFile.count
		}

		func value(for range: Range<Int>) -> Value? { // range relative to rangeInFile.startIndex (kinda)
			precondition(range.endIndex < rangeInFile.count)
			let offset = UInt64(rangeInFile.startIndex + range.startIndex)

			do {
				try fileHandle.seek(toOffset: offset)
			} catch _ {
				return nil
			}

			return fileHandle.readData(ofLength: range.count)
		}

		mutating func replace(in range: Range<Int>, with value: Value) -> Bool {
			false
		}

		mutating func split(at offset: Int) -> Self {
			precondition(offset < rangeInFile.count)

			let rangeInFileOfFirstSegment = rangeInFile.startIndex..<(rangeInFile.startIndex + offset)
			let rangeInFileOfSecondSegment = (rangeInFile.startIndex + offset)..<rangeInFile.endIndex

			rangeInFile = rangeInFileOfFirstSegment
			return Segment(fileHandle: fileHandle, rangeInFile:rangeInFileOfSecondSegment)
		}
	}

	let url: URL
	var size: Int
	var contents = OffsetTree<Segment>()
	let fileHandle: FileHandle

	init(url: URL) throws {
		self.url = url

		size = (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize!
		fileHandle = try FileHandle(forUpdating: url)

		let segment = Segment(fileHandle: fileHandle, rangeInFile: 0..<size)
		contents.insert(segment, offset: 0)
	}
}

extension File: EditorDataSource {
	var totalWordCount: Int {
		return size
	}

	func atomicWordGroup(at wordIndex: Int) -> EditorDataSource.AtomicWordGroup {
		return (text: String(format: "%02X", contents[wordIndex]!.first!), range: wordIndex..<(wordIndex + 1))
	}
}
