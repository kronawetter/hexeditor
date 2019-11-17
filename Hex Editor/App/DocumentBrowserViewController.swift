//
//  DocumentBrowserViewController.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		
		delegate = self
		
		allowsDocumentCreation = false
		allowsPickingMultipleItems = false
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
		
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
		guard let documentURL = documentURLs.first else {
			return
		}

		presentDocument(at: documentURL)
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
		
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
		
	}
		
	func presentDocument(at documentURL: URL) {
		let viewController = DocumentViewController()
		viewController.documentURL = documentURL

		let navigationController = UINavigationController(rootViewController: viewController)
		navigationController.modalPresentationStyle = .currentContext
		
		present(navigationController, animated: true, completion: nil)
	}
}
 
