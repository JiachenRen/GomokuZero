//
//  NSObject.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/4/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

typealias __ = Notification.Name

func post(name: NSNotification.Name, object: Any?) {
    NotificationCenter.default.post(name: name, object: object, userInfo: nil)
}

func post(name: NSNotification.Name, object: Any?, userInfo: [AnyHashable : Any]?) {
    NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
}

extension NSObject {
    internal func observe(_ name: Notification.Name, _ selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
}
