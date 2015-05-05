//
//  ViewController.swift
//  CircularPageViewController
//
//  Created by John Estropia on 2015/05/05.
//  Copyright (c) 2015年 John Rommel Estropia. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    var index: Int = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        println("viewDidLoad: \(self.index)")
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        println("viewWillAppear: \(self.index)")
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        println("viewDidAppear: \(self.index)")
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(animated)
        println("viewWillDisappear: \(self.index)")
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        super.viewDidDisappear(animated)
        println("viewDidDisappear: \(self.index)")
    }
}

