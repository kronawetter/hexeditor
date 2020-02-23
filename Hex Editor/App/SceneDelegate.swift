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
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		let window = UIWindow(windowScene: windowScene)
		guard let documentBrowserViewController = window.rootViewController as? DocumentBrowserViewController else {
			return
		}
		if let currentDocumentViewController = documentBrowserViewController.currentDocumentViewController {
			NSFileCoordinator.addFilePresenter(currentDocumentViewController)
		}
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		let window = UIWindow(windowScene: windowScene)
		guard let documentBrowserViewController = window.rootViewController as? DocumentBrowserViewController else {
			return
		}
		
		if let currentDocumentViewController = documentBrowserViewController.currentDocumentViewController {
			NSFileCoordinator.removeFilePresenter(currentDocumentViewController)
		}
	}
}
