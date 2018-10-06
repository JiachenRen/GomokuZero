//
//  Notification.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

let saveNotif = Notification.Name("save-notif")

func post(_ notif: Notification.Name, _ object: Any?) {
    NotificationCenter.default.post(name: notif, object: object)
}

func post(_ notif: Notification.Name) {
    post(notif, nil)
}
