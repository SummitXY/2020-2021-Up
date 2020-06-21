//
//  ViewController.swift
//  Runloop
//
//  Created by quxiangyu on 2020/6/21.
//  Copyright © 2020 quxiangyu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (Timer) in
//
//
//        }
        
//        perform(#selector(performBlock), with: nil, afterDelay: 3)
//
//        let displayLink = CADisplayLink(target: self, selector: #selector(performBlock))
//        displayLink.add(to: .current, forMode: .common)
        
        let deadLine = DispatchTime.now() + .seconds(3)
        DispatchQueue.main.asyncAfter(deadline: deadLine) {
            print("dispatch.main")
            
        }
    }
    
    @objc func performBlock() {
       let displayLink = CADisplayLink(target: self, selector: #selector(self.displayBlock))
       displayLink.add(to: .current, forMode: .common)
        
    }
    
    @objc func displayBlock() {
        print("displayLink")
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
    }
}

