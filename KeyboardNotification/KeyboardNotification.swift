//
//  KeyboardNotification.swift
//  KeyboardNotification
//
//  Created by David M Reed on 8/29/17.
//  Copyright © 2017 David M Reed. All rights reserved.
//

import UIKit

public enum KeyboardTransition {
    case hideToShow
    case showToShowLarger
    case showToShowSmaller
    case showToHide
}

public enum KeyboardState {
    case unknown
    case shown
    case hidden
}

public protocol KeyboardNotificationProtocol: class {

    /// called when keyboard changes on screen
    ///
    /// - Parameters:
    ///   - state: KeyboardState enum
    ///   - transition: KeyboardTransition enum
    ///   - startFrame: startFrame for keyboard
    ///   - endFrame: endFrame for keyboard
    func keyboardChanging(state: KeyboardState, transition: KeyboardTransition, startFrame: CGRect, endFrame: CGRect)
}

final public class KeyboardNotification: NSObject {

    /// object to call its keyboardChangingMethod
    public weak var delegate: KeyboardNotificationProtocol?

    /// show is sometimes called twice (once for keyboard and second time for suggestion keyboard)
    /// set this to true to try to avoid keyboardChanging from being called twice when this happens
    public var coalesceShowCalls = true

    /// when coalesceShowCalls is true, this is how long to delay wait in case a second call comes in before calling keyboardChanging in case second call does not come in within that time frame
    public var coalesceDelay = 0.25

    public private(set) var keyboardState: KeyboardState = .unknown

    /// init - call from viewDidAppear (or alter so window is not nil)
    ///
    /// - Parameters:
    ///   - window: window of the view controller
    ///   - delegate: delegate to call when UIKeyboardWillChangeFrame is received
    init(delegate: KeyboardNotificationProtocol? = nil) {
        self.delegate = delegate
        super.init()
    }

    deinit {
        stopNotifications()
    }

    /// delegate will start receiving keyboardChanging(startFrame: CGRect, keyboardFrame: CGRect, state: KeyboardState) calls
    public func startNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrameNotification(notification:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHideNotification(notifcation:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHideNotification(notification:)), name: Notification.Name.UIKeyboardDidHide, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowNotification(notifcation:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShowNotification(notifcation:)), name: Notification.Name.UIKeyboardDidShow, object: nil)
    }

    /// delegate should stop receiving calls
    public func stopNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    //    @objc private func keyboardWillShowNotification(notifcation: Notification) {
    //    }
    //
    //    @objc private func keyboardDidShowNotification(notifcation: Notification) {
    //    }
    //
    //    @objc private func keyboardWillHideNotification(notifcation: Notification) {
    //        keyboardState = .hidden
    //    }
    //


    @objc private func keyboardDidHideNotification(notification: Notification) {
        guard let userInfo = notification.userInfo, let startFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue, let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        firstShowHappened = false
        keyboardState = .hidden
        delegate?.keyboardChanging(state: .hidden, transition: .showToHide, startFrame: startFrame, endFrame: endFrame)
    }

    @objc private func keyboardWillChangeFrameNotification(notification: Notification) {

        // in case this is the second call as a result of show, invalidate the timer that calls the delegate's keyboardChanging so it is not called twice
        timer?.invalidate()
        timer = nil

        guard let userInfo = notification.userInfo, let startFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue, let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        if (startFrame.height == 0.0 && endFrame.height > 0.0) ||
            ((keyboardState == .unknown || keyboardState == .hidden) && endFrame.height > 0.0) {
            // keyboard was hidden and now showing
            keyboardShowing(transition: .hideToShow, startFrame: startFrame, endFrame: endFrame)
        } else if startFrame.height > 0.0 && endFrame.height > startFrame.height {
            // keyboard already shown and getting taller
            keyboardShowing(transition: .showToShowLarger, startFrame: startFrame, endFrame: endFrame)
        } else if startFrame.height > 0.0 && endFrame.height > 0.0 && endFrame.height < startFrame.height {
            // keyboard already shown and getting shorter
            keyboardShowing(transition: .showToShowSmaller, startFrame: startFrame, endFrame: endFrame)
        }
        // note: sometimes hiding keyboard just moves origin offscreen so need to use keyboardDidHideNotification instead of checking for it here
    }

    private func keyboardShowing(transition: KeyboardTransition, startFrame: CGRect, endFrame: CGRect) {

        // if this is the first call to show when keyboard is hidden and we're trying to coalesce show calls
        if transition == .hideToShow && !firstShowHappened && coalesceShowCalls {
            timer = Timer.scheduledTimer(withTimeInterval: coalesceDelay, repeats: false) { [weak self] t in
                let state = KeyboardState.shown
                self?.keyboardState = .shown
                self?.delegate?.keyboardChanging(state: state, transition: transition, startFrame: startFrame, endFrame: endFrame)
            }
        } else {
            keyboardState = .shown
            delegate?.keyboardChanging(state: keyboardState, transition: transition, startFrame: startFrame, endFrame: endFrame)
        }
        firstShowHappened = true
    }

    private weak var timer: Timer? = nil
    private var firstShowHappened = false
}

class KeyboardNotificationViewController: UIViewController, KeyboardNotificationProtocol, UITextFieldDelegate {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        kbn = KeyboardNotification(delegate: self)
        kbn.startNotifications()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        kbn.stopNotifications()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // resign responder and return true so Return/Enter key on keyboard hides keyboard
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // keep track of which textfield we are editing so we can use it in keyboardWillChangeFrameNotification
        currentField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // not editing a textfield
        currentField = nil
    }

    func keyboardChanging(state: KeyboardState, transition: KeyboardTransition, startFrame: CGRect, endFrame: CGRect) {
        if let field = currentField {
            let fieldFrame = field.frame
            // adjusted (based on current viewOffset) bottom of field + 25 to leave some space above the keyboard
            let fieldBottom = fieldFrame.origin.y + fieldFrame.height + 25 - viewOffset

            if state == .hidden {
                if view.frame.origin.y < 0.0 {
                    UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                        self.view.frame.origin.y = 0
                    })
                    viewOffset = 0.0
                }
            } else if fieldBottom > endFrame.origin.y {
                // if keyboard hides frame, move view up
                let offset = fieldBottom - endFrame.origin.y
                viewOffset += offset
                UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                    self.view.frame.origin.y -= offset
                })
            } else if viewOffset > 0 {
                // if we've already moved view up and this textfield is far enough above, move view down
                if fieldBottom + 30 < endFrame.origin.y  {
                    let offset = min(40, viewOffset)
                    viewOffset -= offset
                    UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                        self.view.frame.origin.y += offset
                    })
                }
            }
        } else {
            // not editing any textfield so move back to original location
            if view.frame.origin.y < 0.0 {
                UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                    self.view.frame.origin.y = 0
                })
                viewOffset = 0.0
            }
        }
    }

    var kbn: KeyboardNotification!
    var currentField: UITextField? = nil
    private var viewOffset: CGFloat = 0.0
}

