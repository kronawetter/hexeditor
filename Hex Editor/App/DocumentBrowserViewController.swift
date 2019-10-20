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
		print(documentURLs)
		
		guard let documentURL = documentURLs.first else {
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
		let dataSource: UnsafeBufferPointer<CurrentEncoding.CodeUnit> = data[0..<50].copyWords()
		var test = AtomicWordGroupManager<UnicodeAtomicWordGroup<CurrentEncoding, ByteOrder.LittleEndian, UnsafeBufferPointer>>(dataSource: dataSource)
		test.create(for: dataSource.startIndex..<dataSource.endIndex)
		
		documentURL.stopAccessingSecurityScopedResource()
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
		
	}
	
	func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
		
	}
		
	func presentDocument(at documentURL: URL) {
		
	}
}
 
