//
//  ViewController.swift
//  KeyboardNotification
//
//  Created by David M Reed on 8/29/17.
//  Copyright © 2017 David M Reed. All rights reserved.
//

import UIKit

class ViewController: UIViewController, KeyboardNotificationProtocol {

    func keyboardChanging(state: KeyboardState, transition: KeyboardTransition, startFrame: CGRect, endFrame: CGRect) {
        print(state, transition, startFrame, endFrame)
    }

    var kbn: KeyboardNotification!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        kbn = KeyboardNotification(delegate: self)
        kbn.startNotifications()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        kbn.stopNotifications()
    }
}

