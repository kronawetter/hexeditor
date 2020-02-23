//
//  AppDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}
}
