//
//  Helper.swift
//  GoChat
//
//  Created by Nguyen Hoan on 12/5/18.
//  Copyright © 2018 vn.com.hoan. All rights reserved.
//

import UIKit
import AVKit

class Helper: NSObject {

    static let helper = Helper()
    
    let messageRef : DatabaseReference = Database.database().reference().child("messages")
    let userRef = Database.database().reference().child("Users")
    let photoRef = Storage.storage().reference().child("Photo")
    let videoRef = Storage.storage().reference().child("Video")
    
    
    func logout()  {
        do{
            GIDSignIn.sharedInstance().signOut()
            try Auth.auth().signOut()
        }catch let error{
            print(error)
        }
        let loginScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.window?.rootViewController = loginScreen
    }
    
    func playMovie(message:JSQMessage) {
        if message.isMediaMessage{
            if let videoItem = message .media as? JSQVideoMediaItem{
                let player = AVPlayer(url: videoItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                player.play()
                UIApplication.topViewController()?.present(playerViewController, animated: true, completion: nil)
            }
        }
    }
    
    func uploadMedia(picture:UIImage?, video:URL?, finish:((_ url:String?)->())?) {
        let path = "\(Auth.auth().currentUser!.uid)/\(NSDate.timeIntervalSinceReferenceDate)"
        let metaData = StorageMetadata()
        var ref:StorageReference!
        var data:Data!
        if let img = picture, let dataTem = UIImageJPEGRepresentation(img, 1){
            metaData.contentType = "image/jpg"
            ref = self.photoRef.child(path)
            data = dataTem
        }else if let videoUrl = video{
            metaData.contentType = "video/mp4"
            ref = self.videoRef.child(path)
            do{
                let dataTem = try Data(contentsOf: videoUrl)
                data = dataTem
            }catch{
                finish?(nil)
                return
            }
        }
        ref.putData(data, metadata: metaData) { (mData, error) in
            if error == nil{
                ref.downloadURL(completion: { (url, error) in
                    if error == nil{
                        finish?(url?.absoluteString)
                        return
                    }
                })
            }
            finish?(nil)
        }
    }
    
    
    

    
}

extension UIView{
    func showLoading() {
        let bgView = UIView(frame: self.bounds)
        bgView.backgroundColor = UIColor.init(white: 0, alpha: 0.6)
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        indicator.center = bgView.center
        indicator.startAnimating()
        bgView.addSubview(indicator)
        bgView.tag = 2009
        self.addSubview(bgView)
    }
    func hideLoading() {
        self.subviews.forEach { (subView) in
            if subView.tag == 2009{
                subView.removeFromSuperview()
            }
        }
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
