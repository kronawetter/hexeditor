//
//  AtomicWordGroupLayerImageCache.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-04.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

struct AtomicWordGroupLayerData: Hashable {
	let text: String
	let size: Int
}

struct AtomicWordGroupLayerImageCache {
	private var cache: [AtomicWordGroupLayerData: CGImage] = [:]
	private static let textAttributes: [NSAttributedString.Key : NSObject] = [.foregroundColor : UIColor.label, .font : UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)]

	mutating func image(for data: AtomicWordGroupLayerData) -> CGImage {
		if let image = cache[data] {
			return image
		}

		let image = generateImage(for: data)
		cache[data] = image

		return image
	}

	private func generateImage(for data: AtomicWordGroupLayerData) -> CGImage {
		let attributedString = NSAttributedString(string: data.text, attributes: Self.textAttributes)
		let line = CTLineCreateWithAttributedString(attributedString)
		let bounds = CTLineGetBoundsWithOptions(line, [])

		let width = bounds.width
		let height = bounds.height

		let scale = UIScreen.main.scale
		let context = CGContext(data: nil, width: Int(width * scale), height: Int(height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
		context.scaleBy(x: scale, y: scale)

		context.setFillColor(UIColor.systemBackground.cgColor)
		context.fill(CGRect(x: .zero, y: .zero, width: width, height: height))

		CTLineDraw(line, context)

		return context.makeImage()!

	}
}
