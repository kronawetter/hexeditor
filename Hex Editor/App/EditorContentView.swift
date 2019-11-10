//
//  EditorContentView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-11-01.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class EditorContentView: UIView {
	var visibleRect = CGRect.zero {
		didSet {
			if visibleRect != oldValue {
				layer.setNeedsLayout()
			}
		}
	}

	var offsetOfFirstSublayer = 0
	var sublayers: [CALayer] = []
	let estimatedWordGroupHeight: CGFloat = 20.0
	let wordGroupWidth: CGFloat = 14.0 * 2.0
	let font = UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	override func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)

		let firstWordGroup = Int(max(visibleRect.minY, 0.0) / estimatedWordGroupHeight) * Int(visibleRect.width / wordGroupWidth)

		if firstWordGroup >= offsetOfFirstSublayer {
			let sublayersToRemove = min(firstWordGroup - offsetOfFirstSublayer, sublayers.count)

			sublayers[0..<sublayersToRemove].forEach { $0.removeFromSuperlayer() }
			sublayers.removeFirst(sublayersToRemove)
		} else {
			sublayers.forEach { $0.removeFromSuperlayer() }
			sublayers.removeAll()
		}

		offsetOfFirstSublayer = firstWordGroup

		var origin: CGPoint
		if let lastSublayer = sublayers.last {
			origin = CGPoint(x: lastSublayer.frame.maxX, y: lastSublayer.frame.minY)
		} else {
			origin = CGPoint(x: max(visibleRect.minX, 0.0), y: floor(max(visibleRect.minY, 0.0) / estimatedWordGroupHeight) * estimatedWordGroupHeight)
		}

		var index = (firstWordGroup + sublayers.count) % 256

		while origin.y < visibleRect.maxY, origin.y < bounds.maxY {
			let size = CGSize(width: wordGroupWidth, height: estimatedWordGroupHeight)
			var frame = CGRect(origin: origin, size: size)

			if frame.maxX > bounds.width {
				frame.origin.x = 0.0
				frame.origin.y += frame.height

				if frame.origin.y >= visibleRect.maxY || frame.origin.y >= bounds.maxY {
					break
				}
			}

			let textLayer = CATextLayer()
			textLayer.font = font
			textLayer.fontSize = 14.0
			textLayer.contentsScale = UIScreen.main.scale
			textLayer.string = String(format: "%02X", index)
			textLayer.frame = frame

			sublayers.append(textLayer)
			layer.addSublayer(textLayer)

			origin = frame.origin
			origin.x += frame.width

			index = (index + 1) % 256
		}
	}

	/*func addLayers() {
		var cache = AtomicWordGroupLayerImageCache()
		let scale = UIScreen.main.scale

		var origin = CGPoint.zero

		for i in 0..<500 {
			let image = cache.image(for: AtomicWordGroupLayerData(text: "\(i % 10)", size: (i % 3) + 1))

			let size = CGSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
			var frame = CGRect(origin: origin, size: size)

			if frame.maxX > 400.0 {
				frame.origin.x = 0.0
				frame.origin.y += frame.height
			}

			let sublayer = CALayer()
			sublayer.contents = image
			sublayer.isOpaque = true
			sublayer.frame = frame

			layer.addSublayer(sublayer)

			origin = frame.origin
			origin.x += frame.width
		}
	}*/

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		return CGSize(width: size.width, height: size.height * 100000.0)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
