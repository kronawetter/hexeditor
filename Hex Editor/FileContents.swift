//
//  FileContents.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-23.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import Foundation

class FileContents {
	let fileHandle: FileHandle

	private var cache = Data()
	private var rangeInCache = 0..<0

	init(for url: URL) throws {
		fileHandle = try FileHandle(forUpdating: url)
	}

	deinit {
		try! fileHandle.close()
	}

	func synchronize() throws {
		try fileHandle.synchronize()
	}

	func truncate(at offset: Int) throws {
		try fileHandle.truncate(atOffset: UInt64(offset))
	}

	func write(_ data: Data, to range: Range<Int>) throws {
		assert(data.count == range.count)
		
		try fileHandle.seek(toOffset: UInt64(range.startIndex))

		// TODO: Figure out how to use non-deprecated API instead of deprecated API
		// Calling write(contentsOf:) results in signal SIGABRT
		fileHandle.write(data)
		//try! fileContents.fileHandle.write(contentsOf: data)

		// Invalidate cache
		cache = Data()
		rangeInCache = 0..<0
	}

	subscript(_ range: Range<Int>) -> Data {
		get {
			if range.lowerBound < rangeInCache.lowerBound || range.upperBound > rangeInCache.upperBound {
				let offset = max(0, range.lowerBound - 10000)
				try! fileHandle.seek(toOffset: UInt64(offset))

				// TODO: Figure out how to use non-deprecated API instead of deprecated API
				// Calling read(upToCount:) results in signal SIGABRT
				cache = fileHandle.readData(ofLength: range.count + 10000)
				//cache = try! fileHandle.read(upToCount: range.count + 10000)!
				rangeInCache = offset..<(offset + cache.count)
			}

			return cache[range - rangeInCache.lowerBound]
		}
	}
}
