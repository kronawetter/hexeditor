//
//  AtomicWordGroupLayerImageCache.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-04.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

struct AtomicWordGroupLayerImageCache {
	private struct LayerMeta: Hashable {
		let text: String
		let size: Int
	}

	private var cache: [LayerMeta: CGImage] = [:]
	private static let textAttributes: [NSAttributedString.Key : NSObject] = [.foregroundColor : UIColor.label, .font : UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)]

	mutating func image(text: String, size: Int) -> CGImage {
		let meta = LayerMeta(text: text, size: size)
		return image(for: meta)
	}

	private mutating func image(for meta: LayerMeta) -> CGImage {
		if let image = cache[meta] {
			return image
		}

		let image = generateImage(for: meta)
		cache[meta] = image

		return image
	}

	private func generateImage(for meta: LayerMeta) -> CGImage {
		let attributedString = NSAttributedString(string: meta.text, attributes: Self.textAttributes)
		let line = CTLineCreateWithAttributedString(attributedString)
		let bounds = CTLineGetBoundsWithOptions(line, [])

		let width = max(bounds.width, 1.0)
		let height = max(bounds.height, 1.0)

		let scale = UIScreen.main.scale
		let context = CGContext(data: nil, width: Int(width * scale), height: Int(height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
		context.scaleBy(x: scale, y: scale)

		context.setFillColor(UIColor.systemBackground.cgColor)
		context.fill(CGRect(x: .zero, y: .zero, width: width, height: height))

		CTLineDraw(line, context)

		return context.makeImage()!

	}
}
