//
//  ViewController.swift
//  AKScanCodeViewController-Swift
//
//  Created by 张良 on 15/11/18.
//  Copyright © 2015年 Aston. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var lbResult: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func actionGoScan(sender: AnyObject) {
        let scanVC = AKScanViewController()
        scanVC.blockWithScanResult = {
            txt in
            if let result = txt {
                self.lbResult.text = result
            }else{
                print("result is has nothing")
            }
        }
        
        self.navigationController?.pushViewController(scanVC, animated: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

