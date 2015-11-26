//
//  AppDelegate.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/11/15.
//
//

import UIKit
import Fabric
import Crashlytics
import FBSDKCoreKit
import ParseFacebookUtilsV4

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private func presentLoginForm() {
        
    }
    
    private func applyStyle() {
        let tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barStyle = UIBarStyle.BlackOpaque
        UINavigationBar.appearance().translucent = true
        UINavigationBar.appearance().barTintColor = UIColor.burgerOrangeColor()
        UINavigationBar.appearance().tintColor = tintColor
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: tintColor]
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        applyStyle()
        Fabric.with([Crashlytics.self()])
        Parse.setApplicationId("WbmdjdsBxAOdx88qvbv4dVEAZE2QcZSWyZ1QGShW", clientKey:"LDEZkdvLAdoSJhuC6L9YfECDfPmiHyR5CwUXYWQi")
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let container = ContainerViewController.sharedInstance
        window?.rootViewController = container
        window?.makeKeyAndVisible()
        
        if PFUser.currentUser() == nil {
            presentLoginForm()
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }


}

