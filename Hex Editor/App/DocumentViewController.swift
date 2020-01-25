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

				//atomicWordGroupManager = AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.BigEndian, OffsetTree<DataOffsetTreeElementStorage>>>(dataSource: file!.data)
				//atomicWordGroupManager!.create(for: 0..<1000)//file!.size)

				editorView.hexDataSource = file
				editorView.textDataSource = file//atomicWordGroupManager
			}
		}
	}

	deinit {
		if let documentURL = documentURL {
			documentURL.stopAccessingSecurityScopedResource()
		}
	}

	private var file: File?

	//private var atomicWordGroupManager: AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.BigEndian, OffsetTree<DataOffsetTreeElementStorage>>>?

	private var editorView = EditorView()

	private var keyboardObservers: [Any] = []

	// MARK: View Lifecycle

	override func loadView() {
		super.loadView()

		view.addSubview(editorView)
		editorView.translatesAutoresizingMaskIntoConstraints = false
		editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		editorView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Files", style: .plain, target: self, action: #selector(close))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		keyboardObservers = [NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(_:)), name: UIResponder.keyboardWillShowNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)]
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
		keyboardObservers = []
	}

	// MARK: Button Actions

	@objc func close() {
		dismiss(animated: true, completion: nil)
	}

	// MARK: Keyboard Events

	@objc private func keyboardChange(_ notication: Notification) {
		guard let keyboardFrame = (notication.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return
		}

		editorView.contentInset.bottom = keyboardFrame.height
		editorView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
	}
}
