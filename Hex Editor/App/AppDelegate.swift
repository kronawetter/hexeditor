//
//  AppDelegate.swift
//  Hex Editor
//
//  Created by Philip Kronawetter on 2019-10-14.
//  Copyright © 2019 Philip Kronawetter. All rights reserved.
//

import UIKit

class View<T: AtomicWordGroup>: UIView {
	var manager: AtomicWordGroupManager<T>
	
	init(frame: CGRect, dataSource: T.DataSource) {
		manager = AtomicWordGroupManager<T>(dataSource: dataSource)
		
		super.init(frame: frame)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var view = UIView()
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		var tree = OffsetTree<ContigiousOffsetTreeNodePayload<UInt8>>()
		tree.insert(10, at: 10, size: 2)
		tree.insert(8, at: 8, size: 2)
		tree.insert(12, at: 12, size: 2)
		tree.insert(7, at: 7, size: 1)
		tree.insert(0, at: 0, size: 2)

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
