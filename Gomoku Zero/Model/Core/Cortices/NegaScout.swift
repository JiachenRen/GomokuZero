//
//  NegaScout.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// Implementation of PVS (Principal Variation Search)
/// As of now, it is not working.
class NegaScoutCortex: MinimaxCortex {
    
    override func getMove() -> Move {
        let alpha = Move(co: (0,0), score: Int.min / 2)
        let beta = Move(co: (0,0), score: Int.max / 2)
        return pvs(depth, alpha, beta, player: identity)
    }
    
    
    //     function pvs(node, depth, α, β, color) is
    //        if depth = 0 or node is a terminal node then
    //            return color × the heuristic value of node
    //        for each child of node do
    //            if child is first child then
    //                score := −pvs(child, depth − 1, −β, −α, −color)
    //            else
    //                score := −pvs(child, depth − 1, −α − 1, −α, −color) (* search with a null window *)
    //                if α < score < β then
    //                    score := −pvs(child, depth − 1, −β, −score, −color) (* if it failed high, do a full re-search *)
    //            α := max(α, score)
    //            if α ≥ β then
    //                break (* beta cut-off *)
    //        return α
    func pvs(_ depth: Int, _ alpha: Move, _ beta: Move, player: Piece) -> Move {
        var alpha = alpha, beta = beta, depth = depth
        let score = getHeuristicValue()
        
        if score >= Threat.win || score <= -Threat.win || depth == 0 {
            return Move(co: (0,0), score: score)
        }
        
        var mv: Move!
        let moves = getSortedMoves(num: breadth)
        for (idx, move) in moves.sorted(by: {$0.score > $1.score}).enumerated() {
            delegate.put(at: move.co)
            if idx == 0 {
                var tmpBeta = beta
                tmpBeta.co = move.co
                tmpBeta.score *= -1
                var tmpAlpha = alpha
                tmpAlpha.co = move.co
                tmpAlpha.score *= -1
                mv = pvs(depth - 1, tmpBeta, tmpAlpha, player: player.next())
                mv.co = move.co
                mv.score = -mv.score
            } else {
                var tmpAlpha1 = alpha
                tmpAlpha1.score = tmpAlpha1.score * -1 - 1
                var tmpAlpha = alpha
                tmpAlpha.score *= -1
                mv = pvs(depth - 1, tmpAlpha1, tmpAlpha, player: player.next())
                mv.co = move.co
                mv.score = -mv.score
                if alpha.score < mv.score && mv.score < beta.score {
                    var tmpBeta = beta
                    tmpBeta.score *= -1
                    var tmpMv = mv!
                    tmpMv.score *= -1
                    mv = pvs(depth - 1, tmpBeta, tmpMv, player: player.next())
                    mv.co = move.co
                    mv.score = -mv.score
                }
            }
            delegate.revert()
            alpha = alpha.score > mv.score ? alpha : mv
            if alpha.score >= beta.score {
                break
            }
        }
        return alpha
    }
    
    
}
