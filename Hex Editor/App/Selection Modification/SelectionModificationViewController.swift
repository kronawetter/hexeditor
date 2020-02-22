//
//  SelectionModificationViewController.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-22.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import UIKit
import SwiftUI

class SelectionModificationViewController: UIHostingController<SelectionModificationView> {
	var delegate: SelectionModificationViewControllerDelegate? = nil

	override var keyCommands: [UIKeyCommand]? {
		[UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(close))]
	}

	init(originalSelection: Range<Int>, validRange: Range<Int>) {
		super.init(rootView: SelectionModificationView(originalSelection: originalSelection, validRange: validRange))

		rootView.dismiss = { newSelection in
			if let newSelection = newSelection {
				self.delegate?.selectionModificationViewController(self, didChange: newSelection)
			}
			self.dismiss(animated: true)
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		func textFields(in view: UIView) -> [UITextField] {
			var result = view.subviews.flatMap { textFields(in: $0) }

			if let textField = view as? UITextField {
				result.append(textField)
			}

			return result
		}

		let allTextFields = textFields(in: view)
		let firstTextField = allTextFields.min { $0.convert($0.frame, to: view).minY < $1.convert($1.frame, to: view).minY }
		firstTextField?.becomeFirstResponder()
	}

	@objc func close() {
		dismiss(animated: true)
	}

	@objc required dynamic init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
