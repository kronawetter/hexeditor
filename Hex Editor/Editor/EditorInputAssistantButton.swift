//
//  EditorInputAssistantButton.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-16.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import UIKit

class EditorInputAssistantButton: UIControl {
	let text: String

	// TODO: Make this generate valueChanged events

	required init(text: String, accessibilityLabel: String? = nil) {
		self.text = text
		super.init(frame: .zero)
		self.accessibilityLabel = accessibilityLabel
		isAccessibilityElement = true
		isOpaque = false
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		let textRect = attributedString.boundingRect(with: CGSize(width: size.width - textInsets.left - textInsets.right, height: size.height - textInsets.top - textInsets.bottom), options: [], context: nil)
		return CGSize(width: textRect.width + textInsets.left + textInsets.right, height: textRect.height + textInsets.top + textInsets.bottom)
	}

	private var attributedString: NSAttributedString {
		NSAttributedString(string: text, attributes: [.font : UIFont.systemFont(ofSize: 17.0, weight: .medium), .foregroundColor : UIColor.label])
	}

	private let textInsets = UIEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)

	private let cornerRadius: CGFloat = 5.0

	override var frame: CGRect {
		didSet {
			setNeedsDisplay()
		}
	}

	override func draw(_ rect: CGRect) {
		let textRect = attributedString.boundingRect(with: rect.size, options: [], context: nil)

		let rectSize = CGSize(width: textRect.width + textInsets.left + textInsets.right, height: textRect.height + textInsets.top + textInsets.bottom)
		let rectOrigin = CGPoint(x: .zero, y: (rect.height - rectSize.height) / 2.0)

		if isSelected {
			UIColor.label.setFill()

			let backgroundPath = UIBezierPath(roundedRect: CGRect(origin: rectOrigin, size: rectSize), cornerRadius: cornerRadius)
			backgroundPath.fill()

			UIGraphicsGetCurrentContext()?.setBlendMode(.destinationOut)
		}
		
		attributedString.draw(at: CGPoint(x: rectOrigin.x + textInsets.left, y: rectOrigin.y + textInsets.top))
	}
}
