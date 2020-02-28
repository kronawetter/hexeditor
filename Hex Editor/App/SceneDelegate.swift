//
//  SceneDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	var documentBrowserViewController: DocumentBrowserViewController? {
		window?.rootViewController as? DocumentBrowserViewController
	}

	var documentViewController: DocumentViewController? {
		documentBrowserViewController?.documentViewController
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = DocumentBrowserViewController()
		self.window = window
		window.makeKeyAndVisible()
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		if let documentViewController = documentViewController {
			NSFileCoordinator.addFilePresenter(documentViewController)
		}
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		if let documentViewController = documentViewController {
			NSFileCoordinator.removeFilePresenter(documentViewController)
		}
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let documentBrowserViewController = documentBrowserViewController, let URLContext = URLContexts.first else {
			return
		}

		if URLContext.options.openInPlace {
			documentBrowserViewController.presentDocument(at: URLContext.url)
		} else {
			guard let url = documentBrowserViewController.importDocument(at: URLContext.url) else {
				return
			}
			documentBrowserViewController.presentDocument(at: url)
		}
	}
}
