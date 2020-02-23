//
//  File.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

struct File {
	var fileCache = Data()

	struct FileSegment: OffsetTreeElement {
		typealias Value = Data

		let fileContents: FileContents
		var rangeInFile: Range<Int>

		var size: Int {
			rangeInFile.count
		}

		func value(for range: Range<Int>) -> Value? { // range relative to rangeInFile.startIndex (kinda)
			precondition(range.endIndex <= rangeInFile.count)
			return fileContents[range + rangeInFile.startIndex]
		}

		func replace(in range: Range<Int>, with value: Value) -> Bool {
			false
		}

		mutating func split(at offset: Int) -> Self {
			precondition(offset < rangeInFile.count)

			let rangeInFileOfFirstSegment = rangeInFile.startIndex..<(rangeInFile.startIndex + offset)
			let rangeInFileOfSecondSegment = (rangeInFile.startIndex + offset)..<rangeInFile.endIndex

			rangeInFile = rangeInFileOfFirstSegment
			return Self(fileContents: fileContents, rangeInFile:rangeInFileOfSecondSegment)
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

	private(set) var size: Int
	private(set) var hasChanges: Bool
	private var contents = OffsetTree<Data>()
	private let fileContents: FileContents

	init(url: URL) throws {
		size = (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize!
		fileContents = try FileContents(for: url)
		hasChanges = false

		let segment = FileSegment(fileContents: fileContents, rangeInFile: 0..<size)
		contents.insert(segment, offset: 0)
	}

	mutating func insert(_ data: Data, at wordIndex: Int) {
		contents.split(at: wordIndex)
		let element = ChangeSegment(data: data)
		contents.insert(element, offset: wordIndex)

		size += data.count
		hasChanges = true
	}
	
	mutating func remove(in wordIndexRange: Range<Int>) {
		contents.split(at: wordIndexRange.startIndex)
		contents.split(at: wordIndexRange.endIndex)

		var removedBytes = 0
		while removedBytes < wordIndexRange.count {
			removedBytes += contents.remove(at: wordIndexRange.startIndex)!
		}

		assert(removedBytes == wordIndexRange.count)
		size -= removedBytes
		hasChanges = true
	}

	mutating func write() {
		guard hasChanges else {
			return
		}

		try! fileContents.fileHandle.truncate(atOffset: UInt64(totalWordCount))

		var endIndex = totalWordCount
		while endIndex > 0 {
			let (node, pairIndex, _) = contents.find(offset: endIndex - 1)!
			let rangeInNode = node.pairs[pairIndex].range
			let rangeDelta = endIndex - rangeInNode.endIndex
			let range = (rangeInNode.startIndex + rangeDelta)..<(rangeInNode.endIndex + rangeDelta)
			let element = node.pairs[pairIndex].element

			let writeChunkSize = 1024 * 1024 * 128
			var remainingBytes = range.count
			while remainingBytes > 0 {
				let bytesToRead = min(remainingBytes, writeChunkSize)

				let rangeInElement = (remainingBytes - bytesToRead)..<remainingBytes
				let data = element.value(for: rangeInElement)!

				try! fileContents.fileHandle.seek(toOffset: UInt64(range.startIndex + rangeInElement.startIndex))

				// TODO: Figure out how to use non-deprecated API instead of deprecated API
				// Calling write(contentsOf:) results in signal SIGABRT
				fileContents.fileHandle.write(data)
				//try! fileContents.fileHandle.write(contentsOf: data)
				
				remainingBytes -= bytesToRead
			}

			endIndex = range.startIndex
		}

		try! fileContents.fileHandle.synchronize()

		fileContents.invalidateCache()

		contents.clear()
		let segment = FileSegment(fileContents: fileContents, rangeInFile: 0..<size)
		contents.insert(segment, offset: 0)
		hasChanges = false
	}
}

extension File: EditorViewDataSource {
	var totalWordCount: Int {
		return size
	}

	func atomicWordGroup(at wordIndex: Int) -> EditorViewDataSource.AtomicWordGroup? {
		guard let byte = contents[wordIndex] else {
			return nil
		}
		
		return (text: String(format: "%02X", byte), range: wordIndex..<(wordIndex + 1))
	}

	func value(for text: String, at wordIndex: Int, selectionMoved: Bool) -> (data: Data, moveSelectionBy: Int)? {
		guard let value = UInt8(text, radix: 16), (0..<16).contains(value) else {
			return nil
		}

		if selectionMoved {
			return (data: Data([value]), moveSelectionBy: 0)
		} else {
			let existingValue = contents[wordIndex]!
			guard (0..<16).contains(existingValue) else {
				assertionFailure()
				return nil
			}

			let newValue = (existingValue << 4) | value
			return (data: Data([newValue]), moveSelectionBy: 1)
		}
	}
}

extension File: FileAccessor {
	func iterator<ReturnedElement>(for offset: Self.Index) -> AnyIterator<ReturnedElement> where ReturnedElement : FixedWidthInteger {
		// TODO: Only supports UInt8 as ReturnedElement
		AnyIterator(contents.iterator(startingAt: offset)) as! AnyIterator<ReturnedElement>
	}
}
