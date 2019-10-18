//
//  ExtendedUnicodeCodec.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol ExtendedUnicodeCodec: UnicodeCodec {
	static var codeUnitSize: Int { get }
	
	static var maximumNumberOfCodePointsPerScalar: Int { get }

	static func width(_ x: Unicode.Scalar) -> Int
}

extension ExtendedUnicodeCodec {
	static var codeUnitSize: Int {
		assert(CodeUnit.bitWidth.isMultiple(of: 8))
		return CodeUnit.bitWidth / 8
	}
}

extension UTF8: ExtendedUnicodeCodec {
	static var maximumNumberOfCodePointsPerScalar: Int {
		return 4
	}
}

extension UTF16: ExtendedUnicodeCodec {
	static var maximumNumberOfCodePointsPerScalar: Int {
		return 2
	}
}

extension UTF32: ExtendedUnicodeCodec {
	static var maximumNumberOfCodePointsPerScalar: Int {
		return 1
	}
	
	static func width(_ x: Unicode.Scalar) -> Int {
		return 1
	}
}
