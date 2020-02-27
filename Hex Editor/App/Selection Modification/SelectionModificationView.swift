//
//  SelectionModificationView.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2020-02-22.
//  Copyright © 2020 Philip Kronawetter. All rights reserved.
//

import SwiftUI

struct SelectionModificationView: View {
	let originalSelection: Range<Int>
	let validRange: Range<Int>
	var dismiss: ((Range<Int>?) -> Void)? = nil

	@State private var relativeToExistingOffset = false
	@State private var offsetString = ""
	@State private var relativeToExistingCount = false
	@State private var countString = ""

	private var offset: Int? {
		Int.from(prefixedOctalDecimalOrHexadecimal: offsetString)
	}

	private var count: Int? {
		Int.from(prefixedOctalDecimalOrHexadecimal: countString)
	}

	private var modifiedSelection: Range<Int>? {
		guard let offset = offset, let count = count else {
			return nil
		}

		let modifiedOffset = offset + (relativeToExistingOffset ? originalSelection.lowerBound : 0)
		let modifiedCount = count + (relativeToExistingCount ? originalSelection.count : 0)
		guard modifiedCount >= 0 else {
			return nil
		}

		let modifiedRange = modifiedOffset..<(modifiedOffset + modifiedCount)
		guard modifiedRange.clamped(to: validRange) == modifiedRange else {
			return nil
		}

		return modifiedRange
	}

	private var inputValid: Bool {
		modifiedSelection != nil
	}

	private func cancel() {
		dismiss?(nil)
	}

	private func done() {
		guard inputValid else {
			return
		}
		dismiss?(modifiedSelection)
	}

    var body: some View {
		NavigationView {
			Form {
				Section(header: Text("OFFSET")) {
					Picker(selection: $relativeToExistingOffset, label: Text("test")) {
						Text("Jump to Offset")
							.tag(false)
						Text("Move Cursor")
							.tag(true)
					}
					.pickerStyle(SegmentedPickerStyle())
					TextField(relativeToExistingOffset ? "Number of Bytes to Move" : "Offset", text: $offsetString, onCommit: self.done)
						.autocapitalization(.none)
						.disableAutocorrection(true)
				}

				Section(header: Text("SELECTION")) {
					if !originalSelection.isEmpty {
						Toggle(isOn: $relativeToExistingCount) {
							Text("Extend Current Selection")
						}
					}
					TextField(relativeToExistingCount ? "Number of Additional Bytes to Select" : "Number of Bytes to Select", text: $countString, onCommit: self.done)
						.autocapitalization(.none)
						.disableAutocorrection(true)
				}
			}
			.navigationBarTitle("Modify Selection", displayMode: .inline)
			.navigationBarItems(leading: Button("Cancel", action: self.cancel), trailing: Button("Done", action: self.done).disabled(!inputValid))
		}
    }
}

struct SelectionModificationView_Previews: PreviewProvider {
    static var previews: some View {
		SelectionModificationView(originalSelection: 0..<0, validRange: 0..<0) { _ in }
		.frame(width: 320.0, height: 480.0, alignment: .center)
		.environment(\.horizontalSizeClass, .compact)
    }
}

extension Int {
	init?(_ description: String, prefix: String, radix: Int) {
		let minus = "-"
		let prefixWithMinus = minus + prefix

		if description.starts(with: prefixWithMinus) {
			self.init(minus + description.dropFirst(prefixWithMinus.count), radix: radix)
		} else if description.starts(with: prefix) {
			self.init(description.dropFirst(prefix.count), radix: radix)
		} else {
			return nil
		}
	}

	init?(prefixedOctal description: String) {
		self.init(description, prefix: "0", radix: 8)
	}

	init?(prefixedHexadecimal description: String) {
		self.init(description, prefix: "0x", radix: 16)
	}

	static func from(prefixedOctalDecimalOrHexadecimal description: String) -> Int? {
		// Octal conversion must be attempted before decimal conversion as decimal number strings with leading zeros also represent valid integers
		Self.init(prefixedOctal: description) ?? Self.init(prefixedHexadecimal: description) ?? Self.init(description)
	}
}
