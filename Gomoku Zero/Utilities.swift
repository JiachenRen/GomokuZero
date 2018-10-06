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
