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

	var documentViewController: DocumentViewController? {
		(window?.rootViewController as? DocumentBrowserViewController)?.documentViewController
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
}
