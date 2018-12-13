//
//  Message.swift
//  GoChat
//
//  Created by Nguyen Hoan on 12/5/18.
//  Copyright © 2018 vn.com.hoan. All rights reserved.
//

import UIKit

class Message: JSQMessage {

    var messageId:String = ""
    var fileUrl:String?
    convenience init(id:String, senderId: String!, displayName: String!, text: String!) {
        self.init(senderId: senderId, displayName: displayName, text: text)
        self.messageId = id
    }
    
    convenience init(id:String, senderId: String!, displayName: String!, media: JSQMediaItem) {
        self.init(senderId: senderId, displayName: displayName, media: media)
        self.messageId = id
    }
    
    func  toDicData() -> [String:String] {
        if let fileurl = self.fileUrl, self.isMediaMessage{
            if let _ = self.media as? JSQPhotoMediaItem{
                return ["fileUrl": fileurl, "senderId":self.senderId, "senderName": self.senderDisplayName, "MediaType":"PHOTO"]
            }else{
                return ["fileUrl": fileurl, "senderId":self.senderId, "senderName": self.senderDisplayName, "MediaType":"VIDEO"]
            }
            
        }else{
            return ["text":self.text, "senderId":self.senderId, "senderName": self.senderDisplayName, "MediaType":"TEXT"]
        }
    }
}
