//
//  CGPoint.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 11/25/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
import UIKit

extension CGPoint {
    
    static prefix func - (point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
    
    func translate(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        return translating(by: .init(x: x, y: y))
    }
    
    mutating func translate(by point: CGPoint) {
        x += point.x
        y += point.y
    }
    
    func translating(by point: CGPoint) -> CGPoint {
        return .init(x: point.x + x, y: point.y + y)
    }
    
    static func midpoint(from p1: CGPoint, to p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p2.x+p1.x)/2, y: (p2.y+p1.y)/2)
    }
    
    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return lhs + -rhs
    }
}
