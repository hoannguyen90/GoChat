//
//  ChatViewController.swift
//  GoChat
//
//  Created by Nguyen Hoan on 11/28/18.
//  Copyright © 2018 vn.com.hoan. All rights reserved.
//

import UIKit
import MobileCoreServices

class ChatViewController: JSQMessagesViewController {

    
    var message = [Message]()
    var avatas = [String:String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.senderId = "2"
        self.senderDisplayName = "Guest"
        if let user = Auth.auth().currentUser{
            self.senderId = user.uid
            self.senderDisplayName = user.displayName ?? ""
        }
        self.automaticallyScrollsToMostRecentMessage = true
        self.observerMessages()
        
        let button = UIButton(type: .roundedRect)
        button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
        button.setTitle("Crash", for: [])
        button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    @IBAction func crashButtonTapped(_ sender: AnyObject) {
        //        Analytics.setUserProperty("nofood", forName: "Pattern_Colla")
        
        Analytics.logEvent(AnalyticsEventAddToWishlist, parameters: [
            AnalyticsParameterItemID: "event id",
            AnalyticsParameterItemName: "event name",
            AnalyticsParameterContentType: "cont"
            ])
        
        Analytics.logEvent("test_event", parameters: [
            "name": "test event name" as NSObject,
            "full_text": "test event description" as NSObject
            ])
        
        //        Crashlytics.sharedInstance().crash()
    }

    
    
    func observerUser(userId:String){
        Helper.helper.userRef.child(userId).observe(.value) { (snapshot) in
            if let dic = snapshot.value as? [String:AnyObject]{
                if let avata  = dic["avata"] as? String{
                    self.avatas[userId] = avata
                }
            }
        }
    }

    func observerMessages()  {
        Database.database().reference().child("messages").observe(.childAdded) { (snapshot) in
            if let _ = self.message.index(where: {$0.messageId == snapshot.key}){
                return
            }
            if let dic = snapshot.value as? [String:AnyObject]{
                if let senId = dic["senderId"] as? String, let displayName = dic["senderName"] as? String, let mediaType = dic["MediaType"] as? String{
                    self.observerUser(userId: senId)
                    if let text = dic["text"] as? String, mediaType == "TEXT"{
                        let recieveMessage = Message(id: snapshot.key, senderId: senId, displayName: displayName, text: text)
                        self.message.append(recieveMessage)
                    }else if mediaType == "PHOTO" {
                        if let fileURL = dic["fileUrl"] as? String, let url = URL(string: fileURL){
                            let photo = JSQPhotoMediaItem(image: nil)!
                            let downloader = SDWebImageDownloader.shared()
                            downloader.downloadImage(with: url, options: [], progress: nil, completed: { (image, data, error, finished) in
                                DispatchQueue.main.async(execute: {
                                    photo.image = image
                                    self.finishSendingMessage(animated: false)
                                })
                            })
                            let newMessage = Message(id: snapshot.key,senderId: senId, displayName: displayName, media: photo)
                            self.message.append(newMessage)
                            
                            if self.senderId == senId {
                                photo.appliesMediaViewMaskAsOutgoing = true
                            } else {
                                photo.appliesMediaViewMaskAsOutgoing = false
                            }
                        }
                    }else if mediaType == "VIDEO"{
                        if let fileUrl = dic["fileUrl"] as? String, let video  = URL(string: fileUrl){
                            let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)!
                            self.message.append(Message(id: snapshot.key,senderId: senId, displayName: displayName, media: videoItem))
                            if self.senderId == senId {
                                videoItem.appliesMediaViewMaskAsOutgoing = true
                            } else {
                                videoItem.appliesMediaViewMaskAsOutgoing = false
                            }
                        }
                        
                    }
                }
            }
            self.finishSendingMessage(animated: true)
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
       self.sendMessage(text: text, media: nil)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let alert = UIAlertController(title: "Chooose Media", message: "Please select a media", preferredStyle: .actionSheet)
        let photoAction = UIAlertAction(title: "Photo", style: .default) { (action) in
            self.getMediaWithType(sourceType: .photoLibrary, mediaType: kUTTypeImage)
        }
        alert.addAction(photoAction)
        let videoAction = UIAlertAction(title: "Video", style: .default) { (action) in
            self.getMediaWithType(sourceType: .photoLibrary, mediaType: kUTTypeMovie)
        }
        alert.addAction(videoAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = UIApplication.topViewController()?.view
        

        self.present(alert, animated: true, completion: nil)
    }
    
    func  getMediaWithType(sourceType:UIImagePickerControllerSourceType, mediaType:CFString) {
        let picker  = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = [mediaType as String]
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return message.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let message = self.message[indexPath.item]
        return message
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.message[indexPath.row]
        if message.senderId == self.senderId{
            return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.black)
        }else{
            return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.blue)
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = self.message[indexPath.row]
        let avataItem = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "profileImage"), diameter: 30)
        if let avata = self.avatas[message.senderId], avata != ""{
            if let image = SDImageCache.shared().imageFromMemoryCache(forKey: avata) {
                return JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
            }else{
                if let url = URL(string: avata){
                    let downloader = SDWebImageDownloader.shared()
                    downloader.downloadImage(with: url, options: [], progress: nil, completed: { (image, data, error, finished) in
                        DispatchQueue.main.async(execute: {
                            avataItem?.avatarImage = image
                            SDImageCache.shared().store(image, forKey: avata, completion: nil)
                            self.collectionView.reloadItems(at: [indexPath])
                        })
                    })
                }
            }
        }
        return avataItem
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = self.message[indexPath.row]
        if message.isMediaMessage{
            Helper.helper.playMovie(message: message)
        }
    }
    

    @IBAction func logoutTapped(_ sender: Any) {
        Helper.helper.logout()
    }
}

extension ChatViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let newMessage =  Helper.helper.messageRef.childByAutoId()
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            let photoItem = JSQPhotoMediaItem(image: image)!
            let message = Message(id: newMessage.key!, senderId: self.senderId, displayName: self.senderDisplayName, media: photoItem)
            self.message.append(message)
            self.sendMessage(text: nil, media: photoItem)
        }else if let video = info[UIImagePickerControllerMediaURL] as? URL{
            let videoItem = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)!
            let message = Message(id: newMessage.key!, senderId: self.senderId, displayName: self.senderDisplayName, media: videoItem)
            self.message.append(message)
            self.sendMessage(text: nil, media: videoItem)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func sendMessage(text:String?, media:JSQMediaItem?) {
        let newMessage =  Helper.helper.messageRef.childByAutoId()
        var message:Message!
        self.avatas[self.senderId] = Auth.auth().currentUser?.photoURL?.absoluteString
        if let mediaItem = media{
            message = Message(id: newMessage.key!, senderId: senderId, displayName: senderDisplayName, media: mediaItem)
            self.message.append(message)
            if let photoItem = mediaItem as? JSQPhotoMediaItem{
                Helper.helper.uploadMedia(picture: photoItem.image, video: nil) { (photoUrl) in
                    if let url = photoUrl{
                        message.fileUrl = url
                        newMessage.setValue(message.toDicData())
                    }
                }
            }else if let video = mediaItem as? JSQVideoMediaItem{
                Helper.helper.uploadMedia(picture: nil, video: video.fileURL) { (videoUrl) in
                    if let url = videoUrl{
                        message.fileUrl = url
                        newMessage.setValue(message.toDicData())
                    }
                }
            }
        }else{
           message = Message(id: newMessage.key!, senderId: senderId, displayName: senderDisplayName, text: text)
            self.message.append(message)
            newMessage.setValue(message.toDicData())
        }
        self.finishSendingMessage(animated: true)
    }
}
