//
//  File.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

class FileContents {
	let fileHandle: FileHandle
	var cache = Data()
	var rangeInCache = 0..<0

	init(for url: URL) throws {
		fileHandle = try FileHandle(forUpdating: url)
	}

	deinit {
		try! fileHandle.close()
	}

	func invalidateCache() {
		cache = Data()
		rangeInCache = 0..<0
	}

	subscript(_ range: Range<Int>) -> Data {
		get {
			if range.lowerBound < rangeInCache.lowerBound || range.upperBound > rangeInCache.upperBound {
				let offset = max(0, range.lowerBound - 10000)
				try! fileHandle.seek(toOffset: UInt64(offset))

				cache = try! fileHandle.read(upToCount: range.upperBound + 10000)!
				rangeInCache = offset..<(offset + cache.count)
			}

			return cache[range - rangeInCache.lowerBound]
		}
	}
}

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

	let url: URL
	var size: Int
	var contents = OffsetTree<Data>()
	let fileContents: FileContents

	init(url: URL) throws {
		self.url = url

		size = (try url.resourceValues(forKeys: [.fileSizeKey])).fileSize!
		fileContents = try FileContents(for: url)

		let segment = FileSegment(fileContents: fileContents, rangeInFile: 0..<size)
		contents.insert(segment, offset: 0)
	}

	mutating func insert(_ data: Data, at wordIndex: Int) {
		contents.split(at: wordIndex)
		let element = ChangeSegment(data: data)
		contents.insert(element, offset: wordIndex)

		size += data.count
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
	}

	mutating func write() {
		try! fileContents.fileHandle.truncate(atOffset: UInt64(totalWordCount))

		var endIndex = totalWordCount
		while endIndex > 0 {
			let (node, pairIndex, _) = contents.find(offset: endIndex - 1)!
			let rangeInNode = node.pairs[pairIndex].range
			let rangeDelta = endIndex - rangeInNode.endIndex
			let range = (rangeInNode.startIndex + rangeDelta)..<(rangeInNode.endIndex + rangeDelta)
			let element = node.pairs[pairIndex].element

			let writeChunkSize = 1024 * 1024 * 128
			var indexInElement = 0
			while indexInElement < range.count {
				let bytesToRead = min(writeChunkSize, (range.count - indexInElement))

				let data = element.value(for: indexInElement..<(indexInElement + bytesToRead))!
				try! fileContents.fileHandle.seek(toOffset: UInt64(indexInElement))
				try! fileContents.fileHandle.write(contentsOf: data)
				
				indexInElement += bytesToRead
			}

			endIndex = range.startIndex
		}
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
