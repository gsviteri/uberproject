/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import UIKit
import Parse

@available(iOS 8.0, *)
class ViewController: UIViewController, UITextFieldDelegate {
    
    var signUpState = true
    
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var `switch`: UISwitch!
    @IBOutlet var riderLabel: UILabel!
    @IBOutlet var driverLabel: UILabel!
    
    func displayAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func signUp(sender: AnyObject) {
        if username.text == "" || password.text == "" {
            displayAlert("Missing Field(s)", message: "Username and Password are required")
        } else {
            
            
            
            if signUpState == true {
                
                let user = PFUser()
                user.username = username.text
                user.password = password.text
                user["isDriver"] = `switch`.on
                
                user.signUpInBackgroundWithBlock {
                    (succeeded, error) -> Void in
                    if let error = error {
                        if let errorString = error.userInfo["error"] as? String {
                            self.displayAlert("Sign up Failed", message: errorString)
                        }
                    } else {
                        if self.`switch`.on == true {
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                        } else {
                            self.performSegueWithIdentifier("loginRider", sender: self)
                        }
                    }
                }
            } else {
                PFUser.logInWithUsernameInBackground(username.text!, password:password.text!) {
                    (user: PFUser?, error: NSError?) -> Void in
                    if let user = user  { // --> Unwrap user if we can.....
                        if  user["isDriver"]! as! Bool == true { // down cast to boolenas
                            self.performSegueWithIdentifier("loginDriver", sender: self)
                        } else {
                            self.performSegueWithIdentifier("loginRider", sender: self)
                        }
                    } else {
                        if let errorString = error?.userInfo["error"] as? String {
                            self.displayAlert("Login Failed", message: errorString)
                        }
                    }
                }
            }
        }
    }
    
    @IBOutlet var signUpButton: UIButton!
    
    @IBAction func toggleSignUpButton(sender: AnyObject) {
        
        if signUpState == true {
            
            signUpButton.setTitle("Log In", forState: UIControlState.Normal)
            
            toggleSignUpButton.setTitle("Switch to Sign Up", forState: UIControlState.Normal)
            
            signUpState = false
            
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            `switch`.alpha = 0
            
            
        } else {
            
            signUpButton.setTitle("Sing Up", forState: UIControlState.Normal)
            
            toggleSignUpButton.setTitle("Switch to Login", forState: UIControlState.Normal)
            
            signUpState = true
            
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            `switch`.alpha = 1
            
            
        }
    }
    
    @IBOutlet var toggleSignUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.username.delegate = self
        self.password.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    override func viewDidAppear(animated: Bool) {
        if(PFUser.currentUser()?.username != nil) {
            if  PFUser.currentUser()?["isDriver"]! as! Bool == true { // down cast to boolenas
                self.performSegueWithIdentifier("loginDriver", sender: self)
            } else {
                self.performSegueWithIdentifier("loginRider", sender: self)
            }
        }
    }
}
