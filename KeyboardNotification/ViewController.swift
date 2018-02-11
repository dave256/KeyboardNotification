//
//  ViewController.swift
//  KeyboardNotification
//
//  Created by David M Reed on 8/29/17.
//  Copyright © 2017 David M Reed. All rights reserved.
//

import UIKit

class ViewController: KeyboardNotificationViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        topTextField.delegate = self
        bottomTextField.delegate = self
    }

    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
}

