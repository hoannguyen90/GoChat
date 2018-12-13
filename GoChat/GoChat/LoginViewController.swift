//
//  LoginViewController.swift
//  GoChat
//
//  Created by Nguyen Hoan on 11/28/18.
//  Copyright © 2018 vn.com.hoan. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,GIDSignInDelegate {

    @IBOutlet weak var btnAnonymous: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().delegate = self
        self.btnAnonymous.layer.cornerRadius = 4
        self.btnAnonymous.layer.borderWidth = 2
        self.btnAnonymous.layer.borderColor = UIColor.white.cgColor
        self.view.showLoading()
        Auth.auth().addStateDidChangeListener { (auth, user) in
            self.view.hideLoading()
            if user != nil{
                self.loginSuccess(user: user!)
            }else{
                print("not auth")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginAnonymouslyDIdTapped(_ sender: Any) {
        self.view.showLoading()
        Auth.auth().signInAnonymously { (result, error) in
            self.view.hideLoading()
            if error == nil{
                if let user = result?.user{
                    self.loginSuccess(user: user)
                }else{
                    print("Login error")
                }
            }else{
                print(error!.localizedDescription)
            }
        }
    }
    
    @IBAction func googleLoginDidTapped(_ sender: Any) {
        self.view.showLoading()
        GIDSignIn.sharedInstance().signIn()
    }
    //google sigin
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        self.view.hideLoading()
        if error == nil{
             let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken, accessToken: user.authentication.accessToken)
            Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
                if error == nil{
                    if let loginUser = result?.user{
                        self.loginSuccess(user: loginUser)
                    }else{
                        print("Login error")
                    }
                }else{
                    print(error!.localizedDescription)
                }
            }
        }else{
            print(error!.localizedDescription)
        }
    }
    
    
    private func loginSuccess(user:User){
        let ref = Helper.helper.userRef.child(user.uid)
        ref.setValue(["displayName":user.displayName ?? "Guest", "id":user.uid, "avata": user.photoURL?.absoluteString ?? ""])
        let chatScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NavigationVC")
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.window?.rootViewController = chatScreen
        
    }
    
    
}

