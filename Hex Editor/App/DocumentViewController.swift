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
				atomicWordGroupManager = AtomicWordGroupManager(dataSource: file!)
				currentAtomicWordGroupManagerRange = editorView.offsetRangeOfVisibleWordGroups
				atomicWordGroupManager?.create(for: currentAtomicWordGroupManagerRange)
				navigationItem.title = documentURL.lastPathComponent

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

	private var atomicWordGroupManager: AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.LittleEndian, File>>? = nil

	private var currentAtomicWordGroupManagerRange = 0..<0

	private var editorView = EditorView()

	private var keyboardObservers: [Any] = []

	// MARK: View Lifecycle

	override func loadView() {
		super.loadView()

		view.addSubview(editorView)
		editorView.editorDelegate = self
		editorView.translatesAutoresizingMaskIntoConstraints = false
		editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
		editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
		editorView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Files", style: .plain, target: self, action: #selector(close))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		keyboardObservers = [NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)]
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

	@objc private func keyboardWillShow(_ notication: Notification) {
		guard let keyboardFrame = (notication.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return
		}

		editorView.contentInset.bottom = keyboardFrame.height - view.safeAreaInsets.bottom
		editorView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height - view.safeAreaInsets.bottom
	}

	@objc private func keyboardWillChangeFrame(_ notication: Notification) {
		keyboardWillShow(notication)
	}

	@objc private func keyboardWillHide(_ notication: Notification) {
		editorView.contentInset.bottom = .zero
		editorView.verticalScrollIndicatorInsets.bottom = .zero
	}
}

extension DocumentViewController: EditorViewDelegate {
	func editorView(_ editorView: EditorView, didInsert text: String, at offset: Int, in contentView: EditorView.ContentView) -> Int {
		let data = Data(text.utf8)
		file!.insert(data, at: offset)

		// TODO: Make editor data flow work better with copy-on-write behavior and remove these ugly workarounds
		atomicWordGroupManager = AtomicWordGroupManager(dataSource: file!)
		currentAtomicWordGroupManagerRange = editorView.offsetRangeOfVisibleWordGroups
		atomicWordGroupManager?.create(for: currentAtomicWordGroupManagerRange)
		editorView.hexDataSource = file
		editorView.textDataSource = atomicWordGroupManager

		return data.count
	}

	func editorView(_ editorView: EditorView, didDeleteAt offset: Int, in contentView: EditorView.ContentView) {
		file!.remove(at: offset)

		// TODO: Make editor data flow work better with copy-on-write behavior and remove these ugly workarounds
		atomicWordGroupManager = AtomicWordGroupManager(dataSource: file!)
		currentAtomicWordGroupManagerRange = editorView.offsetRangeOfVisibleWordGroups
		atomicWordGroupManager?.create(for: currentAtomicWordGroupManagerRange)
		editorView.hexDataSource = file
		editorView.textDataSource = atomicWordGroupManager
	}

	func editorView(_ editorView: EditorView, didChangeVisibleWordGroupTo range: Range<Int>) {
		let missingWordGroupsAtBegin = max(0, currentAtomicWordGroupManagerRange.lowerBound - range.lowerBound)
		let missingWordGroupsAtEnd = max(0, range.upperBound - currentAtomicWordGroupManagerRange.upperBound)

		if missingWordGroupsAtBegin > 0 || missingWordGroupsAtEnd > 0 {
			atomicWordGroupManager = AtomicWordGroupManager(dataSource: file!)
			atomicWordGroupManager!.create(for: range.lowerBound..<range.upperBound)
			currentAtomicWordGroupManagerRange = range.lowerBound..<range.upperBound
			editorView.textDataSource = atomicWordGroupManager
		}
	}
}
