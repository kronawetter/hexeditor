//
//  ByteOrder.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-15.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

protocol _ByteOrder {
	static func convert<T>(_ integer: T) -> T where T: FixedWidthInteger
}

enum ByteOrder {
	enum BigEndian: _ByteOrder {
		static func convert<T>(_ integer: T) -> T where T: FixedWidthInteger {
			return T(bigEndian: integer)
		}
	}

	enum LittleEndian: _ByteOrder {
		static func convert<T>(_ integer: T) -> T where T: FixedWidthInteger {
			return T(littleEndian: integer)
		}
	}
}
