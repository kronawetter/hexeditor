//
//  DocumentViewController.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-24.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit
import SwiftUI

class DocumentViewController: UIViewController {
	func load(from url: URL) {
		documentURL?.stopAccessingSecurityScopedResource()

		guard url.startAccessingSecurityScopedResource(), let file = try? File(url: url) else {
			unload()
			return
		}

		atomicWordGroupManager = AtomicWordGroupManager(dataSource: file)
		currentAtomicWordGroupManagerRange = editorView.offsetRangeOfVisibleWordGroups
		atomicWordGroupManager?.create(for: currentAtomicWordGroupManagerRange)

		editorView.hexDataSource = file
		editorView.textDataSource = atomicWordGroupManager
		if editorView.selection.endIndex > file.size {
			editorView.selection = 0..<0
		}

		self.file = file
		documentURL = url
	}

	func unload() {
		documentURL?.stopAccessingSecurityScopedResource()

		editorView.hexDataSource = nil
		editorView.textDataSource = nil
		editorView.selection = 0..<0
		editorView.contentOffset = CGPoint(x: .zero, y: -editorView.safeAreaInsets.top)
		atomicWordGroupManager = nil
		file = nil
		documentURL = nil
	}

	private(set) var documentURL: URL? {
		didSet {
			if let documentURL = documentURL {
				print(documentURL.path)
				navigationItem.title = documentURL.lastPathComponent
			}
		}
	}

	deinit {
		documentURL?.stopAccessingSecurityScopedResource()
	}

	private var file: File?

	private var atomicWordGroupManager: AtomicWordGroupManager<UnicodeAtomicWordGroup<UTF8, ByteOrder.LittleEndian, File>>? = nil

	private var currentAtomicWordGroupManagerRange = 0..<0

	private var editorView = EditorView()

	private var keyboardObservers: [Any] = []

	private var documentsButton: UIBarButtonItem!
	private var modifySelectionButton: UIBarButtonItem!
	private var changeBytesPerLineButton: UIBarButtonItem!

	override var keyCommands: [UIKeyCommand] {
		[UIKeyCommand(title: "Modify Selection", action: #selector(modifySelection), input: "l", modifierFlags: .command), UIKeyCommand(title: "Go to Documents", action: #selector(close), input: "o", modifierFlags: .command)]
	}

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

		documentsButton = UIBarButtonItem(title: "Documents", style: .plain, target: self, action: #selector(close))
		modifySelectionButton = UIBarButtonItem(image: UIImage(systemName: "arrow.turn.down.right"), style: .plain, target: self, action: #selector(modifySelection))
		changeBytesPerLineButton = UIBarButtonItem(image: UIImage(systemName: "aspectratio"), style: .plain, target: self, action: #selector(changeBytesPerLine))

		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Documents", style: .plain, target: self, action: #selector(close))
		navigationItem.rightBarButtonItems = [changeBytesPerLineButton, modifySelectionButton]
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		keyboardObservers = [NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)]

		NSFileCoordinator.addFilePresenter(self)
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
		keyboardObservers = []

		NSFileCoordinator.removeFilePresenter(self)
	}

	// MARK: Button Actions

	@objc func close() {
		dismiss(animated: true) {
			self.unload()
		}
	}

	@objc func modifySelection() {
		guard let totalSize = editorView.hexDataSource?.totalWordCount else {
			return
		}
		
		let viewController = SelectionModificationViewController(originalSelection: editorView.selection, validRange: 0..<totalSize)
		viewController.delegate = self
		viewController.isModalInPresentation = true
		viewController.modalPresentationStyle = .popover
		viewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
		present(viewController, animated: true)
	}

	@objc func changeBytesPerLine() {
		let alertController = UIAlertController(title: "Change Bytes Per Line", message: nil, preferredStyle: .alert)
		alertController.addTextField { textField in
			textField.placeholder = "Byte Groups Per Line"
		}
		alertController.addTextField { textField in
			textField.placeholder = "Bytes Per Byte Group"
		}
		alertController.addAction(.init(title: "Done", style: .default) { _ in
			let byteGroupsPerLineText = alertController.textFields?[0].text
			let bytesPerByteGroupText = alertController.textFields?[1].text

			if let byteGroupsPerLineText = byteGroupsPerLineText, let bytesPerByteGroupText = bytesPerByteGroupText, let byteGroupsPerLine = Int(byteGroupsPerLineText), let bytesPerByteGroup = Int(bytesPerByteGroupText), byteGroupsPerLine > 0, bytesPerByteGroup > 0 {
				self.editorView.byteSpacingGroupsPerLine = byteGroupsPerLine
				self.editorView.bytesPerByteSpacingGroup = bytesPerByteGroup
			}
		})
		alertController.addAction(.init(title: "Cancel", style: .cancel))
		present(alertController, animated: true)
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
	func editorView(_ editorView: EditorView, didInsert data: Data, at offset: Int, in contentView: EditorView.ContentView) {
		file!.insert(data, at: offset)

		// TODO: Make editor data flow work better with copy-on-write behavior and remove these ugly workarounds
		atomicWordGroupManager = AtomicWordGroupManager(dataSource: file!)
		currentAtomicWordGroupManagerRange = editorView.offsetRangeOfVisibleWordGroups
		atomicWordGroupManager?.create(for: currentAtomicWordGroupManagerRange)
		editorView.hexDataSource = file
		editorView.textDataSource = atomicWordGroupManager
	}

	func editorView(_ editorView: EditorView, didDeleteIn range: Range<Int>, in contentView: EditorView.ContentView) {
		file!.remove(in: range)

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

extension DocumentViewController: SelectionModificationViewControllerDelegate {
	func selectionModificationViewController(_ selectionModificationViewController: SelectionModificationViewController, didChange selection: Range<Int>) {
		editorView.selection = selection
	}
}

extension DocumentViewController: NSFilePresenter {
	var presentedItemURL: URL? {
		documentURL
	}

	var presentedItemOperationQueue: OperationQueue {
		OperationQueue.main
	}

	func relinquishPresentedItem(toReader reader: @escaping ((() -> Void)?) -> Void) {
		editorView.disableEditing()

		reader {
			self.editorView.enableEditing()
		}
	}

	func relinquishPresentedItem(toWriter writer: @escaping ((() -> Void)?) -> Void) {
		editorView.disableEditing()

		writer {
			self.editorView.enableEditing()
		}
	}

	func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
		do {
			try file?.write()
			completionHandler(nil)
		} catch {
			completionHandler(error)
		}
	}

	func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
		dismiss(animated: true) {
			self.unload()
			completionHandler(nil)
		}
	}

	func presentedItemDidMove(to newURL: URL) {
		documentURL = newURL
	}

	func presentedItemDidChange() {
		guard let documentURL = documentURL else {
			unload()
			return
		}

		// TODO: Do not reload document on attribute change (https://developer.apple.com/documentation/foundation/nsfilepresenter/1416103-presenteditemdidchange)
		load(from: documentURL)
	}
}
