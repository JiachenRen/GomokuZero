//
//  ZeroPlus.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/**
 Zero Plus - Jiachen's fifth attemp at making an unbeatable Gomoku AI
 */
class ZeroPlus {
    var delegate: ZeroPlusDelegate!
    
    func getMove(for player: Piece) {
        Thread.sleep(forTimeInterval: 1)
        delegate?.bestMoveExtrapolated(co: random()) // Placeholder for now
    }
    
    private func random() -> Coordinate {
        let row = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        let col = CGFloat.random(min: 0, max: CGFloat(delegate.pieces.count))
        return (col: Int(col), row: Int(row))
    }
}

protocol ZeroPlusDelegate {
    var pieces: [[Piece]] {get}
    func bestMoveExtrapolated(co: Coordinate)
}
