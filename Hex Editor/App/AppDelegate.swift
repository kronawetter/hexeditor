//
//  AppDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

/*struct Test: Sizeable {
	let value: Int
	let size: Int
}*/

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var view = UIView()
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		/*var tree = OffsetTree<LinearOffsetTreeElementStorage<Test>>()
		tree.insert(Test(value: 100, size: 2), offset: 100)
		tree.insert(Test(value: 102, size: 4), offset: 102)
		tree.insert(Test(value: 200, size: 1), offset: 200)
		tree.insert(Test(value: 300, size: 1), offset: 300)
		tree.insert(Test(value: 250, size: 1), offset: 250)
		tree.insert(Test(value: 220, size: 1), offset: 220)
		tree.insert(Test(value: 210, size: 1), offset: 210)
		tree.insert(Test(value: 230, size: 1), offset: 230)*/
		/*tree.insert(Test(value: 100, size: 1), offset: 100)
		tree.insert(Test(value: 200, size: 1), offset: 200)
		tree.insert(Test(value: 300, size: 1), offset: 300)
		tree.insert(Test(value: 50, size: 1), offset: 50)
		tree.insert(Test(value: 150, size: 1), offset: 150)*/
		
		// Override point for customization after application launch.
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}
}
