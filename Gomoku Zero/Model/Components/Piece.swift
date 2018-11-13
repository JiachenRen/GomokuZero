//
//  Piece.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

public typealias Coordinate = (col: Int, row: Int)

enum Piece: String {
    case black = "*", white = "o", none = "-"
    
    static func random() -> Piece {
        let pieces: [Piece] = [.black, .white, .none]
        return pieces.randomElement()!
    }
    
    func next() -> Piece {
        assert(self != .none)
        return self == .black ? .white : .black
    }
}
