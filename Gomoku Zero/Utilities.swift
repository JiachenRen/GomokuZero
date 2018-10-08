//
//  Utilities.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
import CoreGraphics
import Cocoa

extension CGFloat {
    static func random() -> CGFloat {
        let dividingConst: UInt32 = 4294967295
        return CGFloat(arc4random()) / CGFloat(dividingConst)
    }
    
    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        var min = min, max = max
        if (max < min) {swap(&min, &max)}
        return min + random() * (max - min)
    }
    
    private static func swap(_ a: inout CGFloat, _ b: inout CGFloat){
        let temp = a
        a = b
        b = temp
    }
}

extension CGContext {
    static func point(at point: CGPoint, strokeWeight: CGFloat){
        let circle = NSBezierPath(ovalIn: CGRect(center: point, size: CGSize(width: strokeWeight, height: strokeWeight)))
        circle.fill()
    }
    static func fillCircle(center: CGPoint, radius: CGFloat) {
        let circle = NSBezierPath(ovalIn: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        circle.fill()
    }
}

extension CGRect {
    init(center: CGPoint, size: CGSize){
        self.init(
            origin: CGPoint(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2
            ),
            size: size
        )
    }
    static func fillCircle(center: CGPoint, radius: CGFloat) {
        let circle = NSBezierPath(ovalIn: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        circle.fill()
    }
}

extension NSObject {
    internal func observe(_ name: Notification.Name, _ selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
}

func dialogue(msg: String, infoTxt: String) -> Bool {
    let alert: NSAlert = NSAlert()
    alert.messageText = msg
    alert.informativeText = infoTxt
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    let res = alert.runModal()
    if res == .alertFirstButtonReturn {
        return true
    }
    return false
}

extension Date {
    public var millisecondsSince1970: Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}
