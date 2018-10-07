//
//  Evaluator.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class Evaluator {
    
    func evaluate(for player: Piece, at co: Coordinate, pieces: [[Piece]]) -> Int {
        let row = co.row, col = co.col, dim = pieces.count
        let opponent = player.next()
        
        func isValid(col: Int, row: Int) -> Bool {
            return col >= 0 && co.row >= 0 && row < dim && col < dim
        }
        
        func explore(x: Int, y: Int) -> [Piece] {
            var consecutiveNone = 0
            var seq = [Piece]()
            for i in 1...5  {
                let curRow = row + y * i, curCol = col + x * i
                if !isValid(col: curCol, row: curRow) {
                    seq.append(opponent) // It doesn't matter which color the player is, hitting the wall == an opposite piece
                    break
                }
                let piece = pieces[curRow][curCol]
                switch piece {
                case .none:
                    consecutiveNone += 1
                    seq.append(.none)
                    if consecutiveNone == 2 {
                        break
                    }
                default:
                    seq.append(piece)
                    consecutiveNone = 0
                    if piece == opponent {
                        break
                    }
                }
            }
            return seq
        }
        // Linearize the board for higher efficiency
        
        // Horizontal (from left to right)
        var hSeq: [Piece] = explore(x: -1, y: 0).reversed()
        hSeq.append(player)
        hSeq.append(contentsOf: explore(x: 1, y: 0))
        
        // Vertical (from up to down
        var vSeq: [Piece] = explore(x: 0, y: -1).reversed()
        vSeq.append(player)
        vSeq.append(contentsOf: explore(x: 0, y: 1))
        
        // Diagnally (from lower left to upper right)
        var d1Seq: [Piece] = explore(x: -1, y: 1).reversed()
        d1Seq.append(player)
        d1Seq.append(contentsOf: explore(x: 1, y: -1))
        
        // Diagnally (from upper left to lower right)
        var d2Seq: [Piece] = explore(x: -1, y: -1).reversed()
        d2Seq.append(player)
        d2Seq.append(contentsOf: explore(x: 1, y: -1))
        
        let sequences = [hSeq, vSeq, d1Seq, d2Seq]
        return sequences.map{analyzeSequence(seq: $0, for: player)} // Convert sequences to threat types
            .map{$0.rawValue} // Convert threat types to score
            .reduce(0){$0 + $1} // Sum it up
    }
    
    func analyzeSequence(seq: [Piece], for player: Piece) -> ThreatType {
        print(seq)
        return .blockedFour
    }
    
}
