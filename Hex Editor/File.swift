//
//  File.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-20.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import Foundation

struct File {
	let url: URL
	var size: Int
	var data = OffsetTree<DataOffsetTreeElementStorage>()

	init(url: URL) throws {
		self.url = url

		let dataFromURL = try Data(contentsOf: url)
		data.insert(dataFromURL, offset: 0)
		size = dataFromURL.count
	}
}

extension File: EditorDataSource {
	var totalWordCount: Int {
		return size
	}

	func atomicWordGroup(at wordIndex: Int) -> EditorDataSource.AtomicWordGroup {
		return (text: String(format: "%02X", data[wordIndex]!), range: wordIndex..<(wordIndex + 1))
	}
}
