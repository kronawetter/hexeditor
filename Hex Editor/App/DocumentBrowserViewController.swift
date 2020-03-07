//
//  DocumentBrowserViewController.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController {
	let documentViewController = DocumentViewController()

	func presentDocument(at documentURL: URL) {
		// URL must not be presented in any other scene
		let currentlyPresentedDocumentURLs = UIApplication.shared.connectedScenes.compactMap { ($0.delegate as? SceneDelegate)?.documentViewController?.presentedItemURL }
		guard !currentlyPresentedDocumentURLs.contains(documentURL) else {
			return
		}

		documentViewController.load(from: documentURL)

		let navigationController = UINavigationController(rootViewController: documentViewController)
		navigationController.modalPresentationStyle = .currentContext

		present(navigationController, animated: true)
	}

	func importDocument(at importURL: URL) -> URL? {
		func uniqueURLForFile(with fileName: String, extension fileExtension: String, in directoryURL: URL) -> URL {
			var iteration = 1
			while true {
				let fileNameWithSuffix = iteration > 1 ? "\(fileName) \(iteration)" : fileName
				let documentURL = directoryURL.appendingPathComponent(fileNameWithSuffix, isDirectory: false).appendingPathExtension(fileExtension)
				if (try? documentURL.checkPromisedItemIsReachable()) != true {
					return documentURL
				}
				iteration += 1
			}
		}

		guard let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return nil
		}

		let documentURL = uniqueURLForFile(with: importURL.deletingPathExtension().lastPathComponent, extension: importURL.pathExtension, in: documentDirectoryURL)
		var error: NSError? = nil
		var writeError: Error? = nil

		NSFileCoordinator().coordinate(writingItemAt: documentURL, error: &error) { url in
			do {
				try FileManager.default.moveItem(at: importURL, to: url)
			} catch {
				writeError = error
			}
		}

		guard error == nil, writeError == nil else {
			return nil
		}

		return documentURL
	}

	// MARK: View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		delegate = self
		shouldShowFileExtensions = true
		allowsPickingMultipleItems = false
	}
}

// MARK: Document Browser View Controller Delegate
extension DocumentBrowserViewController: UIDocumentBrowserViewControllerDelegate {
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
		let directoryURL = FileManager.default.temporaryDirectory
		let fileName = "New Document"
		let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)

		do {
			try Data().write(to: fileURL)
			importHandler(fileURL, .copy)
		} catch {
			importHandler(nil, .none)
		}
	}

	func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
		guard let documentURL = documentURLs.first else {
			return
		}

		presentDocument(at: documentURL)
	}

	func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
		presentDocument(at: destinationURL)
	}

	func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {

	}
}
 
