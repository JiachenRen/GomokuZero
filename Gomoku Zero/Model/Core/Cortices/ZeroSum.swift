//
//  ZeroSum.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/28/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation
/// A simple heuristic based on the principle of zero-sum games
class ZeroSumCortex: BasicCortex {
    override func getMove(for player: Piece) -> Move {
        var moves = [Move]()
        for (i, row) in delegate.activeMap.enumerated() {
            for (q, isActive) in row.enumerated() {
                if isActive {
                    let co = (col: q, row: i)
                    let myOffense = ThreatEvaluator.evaluate(for: player, at: co, pieces: pieces)
                    let opOffense = ThreatEvaluator.evaluate(for: player.next(), at: co, pieces: pieces)
                    let score = myOffense + opOffense // 敌人的要点也是我方的要点
                    moves.append((co, score))
                }
            }
        }
        if delegate.randomizedSelection {
            moves = differentiate(moves, maxWeight: 10)
        }
        return moves.sorted{$0.score > $1.score}[0]
    }
}
