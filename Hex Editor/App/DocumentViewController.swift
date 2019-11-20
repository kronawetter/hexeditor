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

				file = try! File(url: documentURL)
				navigationItem.title = documentURL.lastPathComponent

				atomicWordGroupManager = AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.BigEndian, OffsetTree<DataOffsetTreeElementStorage>>>(dataSource: file!.data)
				atomicWordGroupManager!.create(for: 0..<file!.size)

				editorView.hexDataSource = file
				editorView.textDataSource = atomicWordGroupManager
			}
		}
	}

	deinit {
		if let documentURL = documentURL {
			documentURL.stopAccessingSecurityScopedResource()
		}
	}

	private var file: File?

	private var atomicWordGroupManager: AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.BigEndian, OffsetTree<DataOffsetTreeElementStorage>>>?

	private var editorView = EditorView()

	// MARK: View Lifecycle

	override func loadView() {
		super.loadView()

		view.addSubview(editorView)
		editorView.translatesAutoresizingMaskIntoConstraints = false
		editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		editorView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
		editorView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Files", style: .plain, target: self, action: #selector(close))
	}

	// MARK: Button Actions

	@objc func close() {
		dismiss(animated: true, completion: nil)
	}
}
