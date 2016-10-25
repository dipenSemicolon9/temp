//
//  ViewController.swift
//  NativeWsCall
//
//  Created by tasol on 10/25/16.
//  Copyright © 2016 tasol. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

//        ApiCall.sharedAPICall.callApi("https://api.wish-qatar.org/summit/agenda?sid=AR3XJ0BG0NJ3LG10005451AG2QJ9QH4OI9ZW", withParameter: NSMutableDictionary(), withLoader: true, successBlock: { (responceData) in
//                print(responceData)
//            },FailurBlock: { (failurData) in
//            
//            })
        
        
        let param:NSMutableDictionary = NSMutableDictionary()
            param.setValue("Asd", forKey: "userName")
        
        ApiCall.sharedAPICall.callApiImageUpload("http://localhost/webalizer/index.php", withParameter: param, withLoader: true, img: UIImage(named: "avatar_03.png")!, imgTagName: "file1", successBlock: { (responceData) in
                print(responceData)
            },FailurBlock: { (failurData) in
                
            })
        
        
        }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
}

