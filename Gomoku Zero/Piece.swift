//
//  Piece.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

enum Piece {
    case black, white, none
    
    public static func random() -> Piece {
        switch Int(CGFloat.random(min: 0, max: 3)) {
        case 0: return Piece.black
        case 1: return Piece.white
        case 2: return Piece.none
        default: assert(false)
        }
    }
}
