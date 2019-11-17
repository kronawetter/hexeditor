//
//  DocumentViewController.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-24.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
	var documentURL: URL? {
		didSet {
			if let oldValue = oldValue {
				oldValue.stopAccessingSecurityScopedResource()
			}

			if let documentURL = documentURL {
				print(documentURL.path)

				let isPermitted = documentURL.startAccessingSecurityScopedResource()
				precondition(isPermitted)

				documentData = try! Data(contentsOf: documentURL)
				navigationItem.title = documentURL.lastPathComponent
			}
		}
	}

	deinit {
		if let documentURL = documentURL {
			documentURL.stopAccessingSecurityScopedResource()
		}
	}

	private var documentData: Data?

	private var editorView = EditorView()

	// MARK: View Lifecycle

	override func loadView() {
		super.loadView()

		view.addSubview(editorView)
		editorView.dataSource = self
		editorView.translatesAutoresizingMaskIntoConstraints = false
		editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		editorView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
		editorView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

		view.backgroundColor = .systemBackground
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Files", style: .plain, target: self, action: #selector(close))
	}

	// MARK: Button Actions

	@objc func close() {
		dismiss(animated: true, completion: nil)
	}
}

extension DocumentViewController: EditorDataSource {
	var totalWordCount: Int {
		guard let documentData = documentData else {
			return 0
		}

		return documentData.count
	}

	func atomicWordGroups(for wordRange: Range<Int>) -> [(text: String, size: Int)] {
		guard let documentData = documentData else {
			return []
		}
		
		return documentData[wordRange].map { (text: String(format: "%02X", $0), size: 1) }
	}

	func atomicWordGroup(at wordIndex: Int) -> (text: String, size: Int) {
		return (text: String(format: "%02X", documentData![wordIndex]), size: 1)
	}
}


	/*@objc func applyOffset() {
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

		typealias CurrentEncoding = UTF8

		var fileTree = OffsetTree<LinearOffsetTreeElementStorage<UInt8>>()
		for (index, byte) in data.enumerated() {
			fileTree.insert(byte, offset: index)
		}

		var manager = AtomicWordGroupManager<UnicodeAtomicWordGroup<CurrentEncoding, ByteOrder.BigEndian, OffsetTree<LinearOffsetTreeElementStorage<UInt8>>>>(dataSource: fileTree)
		manager.create(for: offset..<(offset + 1000))

		documentURL.stopAccessingSecurityScopedResource()

		/*var string = ""
		for group in manager.groups.iterator(for: offset) {
			print(group.range)
			let value = group.value.prefix(group.size)
			let missingCharacters = group.size - value.count

			string += value
			for _ in 0..<missingCharacters {
				string += " "
			}
		}
		unicodeTextView.text = string*/
	}*/
