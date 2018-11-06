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
        for co in delegate.activeCoordinates {
            let myOffense = evaluator.evaluate(for: player, at: co)
            let opOffense = evaluator.evaluate(for: player.next(), at: co)
            
            // If I can win right now, do it without hesitation!
            if myOffense > Evaluator.win {
                return (co, myOffense)
            }
            let score = max(myOffense, opOffense) // 敌人的要点也是我方的要点
            moves.append((co, score))
        }
        if delegate.strategy.randomizedSelection {
            moves = differentiate(moves, maxWeight: 10)
        }
        return moves.sorted{$0.score > $1.score}[0]
    }
}
