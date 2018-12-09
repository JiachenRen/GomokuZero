//
//  CGContext.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 11/25/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

extension CGContext {
    static func point(at point: CGPoint, strokeWeight: CGFloat) {
        let circle = UIBezierPath(ovalIn: CGRect(center: point, size: CGSize(width: strokeWeight, height: strokeWeight)))
        circle.fill()
    }
    static func fillCircle(center: CGPoint, radius: CGFloat) {
        let circle = UIBezierPath(ovalIn: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        circle.fill()
    }
}
