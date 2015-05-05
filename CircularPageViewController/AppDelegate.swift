//
//  AppDelegate.swift
//  CircularPageViewController
//
//  Created by John Estropia on 2015/05/05.
//  Copyright (c) 2015年 John Rommel Estropia. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pageController:CircularPageViewController? = nil

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        let pageController = CircularPageViewController(viewControllers: [])
        pageController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "reload", style: .Plain, target: self, action: "rightBarButtonItemTapped:")
        
        let window = UIWindow()
        window.frame = UIScreen.mainScreen().bounds
        pageController.view.frame = window.frame;
        window.addSubview(pageController.view)
        window.rootViewController = UINavigationController(rootViewController: pageController)
        window.makeKeyAndVisible()
        
        self.window = window
        self.pageController = pageController
        return true
    }

    dynamic func rightBarButtonItemTapped(sender: AnyObject) {
        
        let storyboad = UIStoryboard(name: "Main", bundle: nil)
        
        var viewControllers = [UIViewController]()
        let randomCount = Int(arc4random_uniform(10))
        for var index = 0; index < randomCount; ++index {
            
            let viewController = storyboad.instantiateInitialViewController() as! ViewController
            viewController.index = index
            viewController.navigationItem.title = "Page \(index)"
            viewController.view.backgroundColor = UIColor(
                red: CGFloat(arc4random_uniform(256)) / 256.0,
                green: CGFloat(arc4random_uniform(256)) / 256.0,
                blue: CGFloat(arc4random_uniform(256)) / 256.0,
                alpha: 1.0
            )
            viewControllers.append(viewController)
        }
        self.pageController?.viewControllers = viewControllers
        self.pageController?.navigationItem.title = "\(viewControllers.count) page(s)"
    }
}

