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
    
    // The arrangement of pieces on the board. A 2D array.
    var pieces: [[Piece]]
    var delegate: BoardDelegate?
    
    static var sharedInstance = {
       return Board(dimension: 19)
    }()
    
    init(dimension: Int) {
        self.dimension = dimension
        pieces = [[Piece]](repeating: Array(repeatElement(Piece.none, count: dimension)), count: dimension)
    }
    
    public func spawnPseudoPieces() {
        pieces = [[Piece]](repeating: Array(repeatElement(Piece.none, count: dimension)), count: dimension)
        for row in 0..<dimension {
            for col in 0..<dimension {
                pieces[row][col] = Piece.random()
            }
        }
        delegate?.boardDidUpdate(pieces: pieces)
    }
}

protocol BoardDelegate {
    func boardDidUpdate(pieces: [[Piece]])
}


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
