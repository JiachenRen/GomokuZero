//
//  Piece.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

enum Piece: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "-"
        case .black: return "*"
        case .white: return "o"
        }
    }
    
    case black, white, none
    
    static func random() -> Piece {
        switch Int(CGFloat.random(min: 0, max: 3)) {
        case 0: return Piece.black
        case 1: return Piece.white
        case 2: return Piece.none
        default: assert(false)
        }
    }
    
    func next() -> Piece {
        assert(self != .none)
        return self == .black ? .white : .black
    }
}
