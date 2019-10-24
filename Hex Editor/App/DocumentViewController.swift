//
//  DocumentViewController.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-24.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
	var documentURL: URL
	var offsetTextField = UITextField()
	var applyOffsetButton = UIButton()
	var unicodeTextView = UITextView()

	init(documentURL: URL) {
		self.documentURL = documentURL
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		super.loadView()

		view.addSubview(unicodeTextView)
		view.addSubview(offsetTextField)
		view.addSubview(applyOffsetButton)

		view.backgroundColor = .systemBackground

		navigationItem.title = documentURL.lastPathComponent
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Files", style: .plain, target: self, action: #selector(close))

		unicodeTextView.translatesAutoresizingMaskIntoConstraints = false
		unicodeTextView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
		unicodeTextView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true
		unicodeTextView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		unicodeTextView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		unicodeTextView.font = .monospacedSystemFont(ofSize: 12.0, weight: .regular)

		offsetTextField.translatesAutoresizingMaskIntoConstraints = false
		offsetTextField.leadingAnchor.constraint(equalTo: unicodeTextView.leadingAnchor).isActive = true
		offsetTextField.bottomAnchor.constraint(equalTo: unicodeTextView.topAnchor, constant: -10.0).isActive = true
		offsetTextField.borderStyle = .roundedRect
		offsetTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		offsetTextField.placeholder = "Offset"
		offsetTextField.delegate = self

		applyOffsetButton.translatesAutoresizingMaskIntoConstraints = false
		applyOffsetButton.leadingAnchor.constraint(equalTo: offsetTextField.trailingAnchor, constant: 10.0).isActive = true
		applyOffsetButton.trailingAnchor.constraint(equalTo: unicodeTextView.trailingAnchor, constant: 10.0).isActive = true
		applyOffsetButton.topAnchor.constraint(equalTo: offsetTextField.topAnchor).isActive = true
		applyOffsetButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		applyOffsetButton.setTitle("Apply", for: .normal)
		applyOffsetButton.addTarget(self, action: #selector(applyOffset), for: .touchUpInside)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }

	@objc func applyOffset() {
		guard let offsetString = offsetTextField.text, let offset = Int(offsetString) else {
			return
		}

		guard documentURL.startAccessingSecurityScopedResource() else {
			return
		}

		guard let data = try? Data(contentsOf: documentURL) else {
			documentURL.stopAccessingSecurityScopedResource()
			return
		}

		let range = offset..<(offset + 10000)

		typealias CurrentEncoding = UTF8
		let croppedData = data[range]
		let dataSource: UnsafeBufferPointer<CurrentEncoding.CodeUnit> = croppedData.copyWords()
		var manager = AtomicWordGroupManager<UnicodeAtomicWordGroup<CurrentEncoding, ByteOrder.LittleEndian, UnsafeBufferPointer>>(dataSource: dataSource)
		manager.create(for: dataSource.startIndex..<dataSource.endIndex)

		documentURL.stopAccessingSecurityScopedResource()

		var string = ""
		for index in dataSource.startIndex..<dataSource.endIndex {
			if let group = manager.groups[index] {
				let value = group.value.prefix(group.size)
				let missingCharacters = group.size - value.count

				string += value
				for _ in 0..<missingCharacters {
					string += " "
				}
			}
		}
		unicodeTextView.textContainer.lineBreakMode = .byCharWrapping
		unicodeTextView.text = string
	}

	@objc func close() {
		dismiss(animated: true, completion: nil)
	}
}

extension DocumentViewController: UITextFieldDelegate {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let digits = (0x30...0x39).map { Character(UnicodeScalar($0)) }
		return string.first { !digits.contains($0) } == nil
	}
}
