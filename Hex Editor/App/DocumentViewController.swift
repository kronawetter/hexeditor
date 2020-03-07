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
		lastModificationDate = file.modificationDate(with: self)
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
		lastModificationDate = nil
	}

	private(set) var documentURL: URL? {
		didSet {
			if let documentURL = documentURL {
				print(documentURL.path)
				navigationItem.title = documentURL.lastPathComponent
				view.window?.windowScene?.title = documentURL.lastPathComponent
			} else {
				navigationItem.title = nil
				view.window?.windowScene?.title = ""
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

	private var lastModificationDate: Date? = nil

	override var keyCommands: [UIKeyCommand] {
		[UIKeyCommand(title: "Modify Selection", action: #selector(modifySelection), input: "l", modifierFlags: .command), UIKeyCommand(title: "Go to Documents", action: #selector(close), input: "o", modifierFlags: .command)]
	}

	private func disableForSaving() {
		navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = false }
		navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
		editorView.disableEditing()
		editorView.isUserInteractionEnabled = false
	}

	private func enableAfterSaving() {
		navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = true }
		navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
		editorView.enableEditing()
		editorView.isUserInteractionEnabled = true
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

		navigationItem.leftBarButtonItem = documentsButton
		navigationItem.rightBarButtonItems = [changeBytesPerLineButton, modifySelectionButton]
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		keyboardObservers = [NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil), NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)]

		NSFileCoordinator.addFilePresenter(self)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		view.window?.windowScene?.title = documentURL?.lastPathComponent ?? ""
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		view.window?.windowScene?.title = ""
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
		keyboardObservers = []

		self.unload()

		NSFileCoordinator.removeFilePresenter(self)
	}

	// MARK: Button Actions

	@objc func close() {
		disableForSaving()

		file?.write(with: self) { error in
			self.enableAfterSaving()

			if let error = error {
				let alert = UIAlertController(title: "Failed to Save Document", message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(.init(title: "Close Document", style: .destructive) { _ in
					self.dismiss(animated: true)
				})
				self.present(alert, animated: true)
				return
			} else {
				self.dismiss(animated: true)
			}
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
		viewController.popoverPresentationController?.barButtonItem = modifySelectionButton
		present(viewController, animated: true)
	}

	@objc func changeBytesPerLine() {
		let alertController = UIAlertController(title: "Change Bytes Per Line", message: nil, preferredStyle: .alert)
		alertController.addTextField { textField in
			textField.placeholder = "Byte Groups Per Line"
			textField.autocorrectionType = .no
			textField.autocapitalizationType = .none
		}
		alertController.addTextField { textField in
			textField.placeholder = "Bytes Per Byte Group"
			textField.autocorrectionType = .no
			textField.autocapitalizationType = .none
		}
		alertController.addAction(.init(title: "Done", style: .default) { _ in
			let byteGroupsPerLineText = alertController.textFields?[0].text
			let bytesPerByteGroupText = alertController.textFields?[1].text

			if let byteGroupsPerLineText = byteGroupsPerLineText, let bytesPerByteGroupText = bytesPerByteGroupText, let byteGroupsPerLine = Int.from(prefixedOctalDecimalOrHexadecimal: byteGroupsPerLineText), let bytesPerByteGroup = Int.from(prefixedOctalDecimalOrHexadecimal: bytesPerByteGroupText), byteGroupsPerLine > 0, bytesPerByteGroup > 0 {
				self.editorView.byteSpacingGroupsPerLine = byteGroupsPerLine
				self.editorView.bytesPerByteSpacingGroup = bytesPerByteGroup
			}
		})
		alertController.addAction(.init(title: "Cancel", style: .cancel))
		present(alertController, animated: true)
	}

	// MARK: Keyboard Events

	@objc private func keyboardWillShow(_ notification: Notification) {
		// Source: https://gist.github.com/douglashill/41ea84f0ba59feecd3be51f21f73d501

		guard let endFrameInScreenCoords = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return
		}

		let endFrameInSelfCoords = view.convert(endFrameInScreenCoords, from: nil)

		// Need to clear the additionalSafeAreaInsets in order to be able to read the unaltered safeAreaInsets. We’ll set it again just below.
		additionalSafeAreaInsets = .zero
		let safeBounds = view.bounds.inset(by: view.safeAreaInsets)

		let isDocked = endFrameInSelfCoords.maxY >= safeBounds.maxY
		let keyboardOverlapWithViewFromBottom = isDocked ? max(0, safeBounds.maxY - endFrameInSelfCoords.minY) : 0

		additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardOverlapWithViewFromBottom, right: 0)
	}

	@objc private func keyboardWillChangeFrame(_ notification: Notification) {
		keyboardWillShow(notification)
	}

	@objc private func keyboardWillHide(_ notification: Notification) {
		additionalSafeAreaInsets = .zero
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
		disableForSaving()

		reader {
			self.enableAfterSaving()
		}
	}

	func relinquishPresentedItem(toWriter writer: @escaping ((() -> Void)?) -> Void) {
		disableForSaving()

		writer {
			self.enableAfterSaving()
		}
	}

	func savePresentedItemChanges(completionHandler: @escaping (Error?) -> Void) {
		disableForSaving()

		file?.write(with: self) { error in
			self.enableAfterSaving()
			completionHandler(error)
		}
	}

	func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
		dismiss(animated: true) {
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

		guard let modificationDate = file?.modificationDate(with: self) else {
			// Always reload when modification date is not available
			load(from: documentURL)
			return
		}

		if lastModificationDate != modificationDate {
			// Reload when modification date is different from modification date when file was last loaded
			load(from: documentURL)
		}
	}
}
