//
//  Board.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Board {
    var dimension: Int
    var pieces: [[Piece]]
    
    static var sharedInstance = {
       return Board(dimension: 19)
    }()
    
    init(dimension: Int) {
        self.dimension = dimension
        pieces = [[Piece]](repeating: Array(repeatElement(Piece.none, count: dimension)), count: dimension)
    }
}
