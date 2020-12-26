//
//  AppDelegate.swift
//  nconvapp
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import UIKit

// swiftlint:disable implicitly_unwrapped_optional force_cast
protocol AppDelegateProtocol {
    var context: AppContext! { get }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppDelegateProtocol {

    var context: AppContext! = AppContext.context()
    static let shared: AppDelegateProtocol = UIApplication.shared.delegate as! AppDelegateProtocol
// swiftlint:enable implicitly_unwrapped_optional force_cast
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        context.applicationDelegateServices.forEach { _ = $0.registerApplication(application, didFinishLaunchingWithOptions: launchOptions) }

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
