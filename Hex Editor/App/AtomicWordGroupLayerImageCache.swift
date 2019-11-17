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
	private static let textAttributes: [NSAttributedString.Key : NSObject] = [.foregroundColor : UIColor.white, .font : UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)]

	mutating func image(for data: AtomicWordGroupLayerData) -> CGImage {
		if let image = cache[data] {
			return image
		}

		let image = generateImage(for: data)
		cache[data] = image

		return image
	}

	private func generateImage(for data: AtomicWordGroupLayerData) -> CGImage {
		// TODO: Consider using CATextLayer
		let layer = CALayer()
		layer.bounds = CGRect(x: 0.0, y: 0.0, width: 14.0 * CGFloat(data.size) * 2.0, height: 14.0)
		layer.backgroundColor = UIColor.white.cgColor

		let scale = UIScreen.main.scale
		let context = CGContext(data: nil, width: Int(layer.bounds.size.width * scale), height: Int(layer.bounds.size.height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
		context.scaleBy(x: scale, y: scale)

		let attributedString = NSAttributedString(string: data.text, attributes: Self.textAttributes)

		let line = CTLineCreateWithAttributedString(attributedString)
		CTLineDraw(line, context)

		return context.makeImage()!

	}
}
