//
//  NegaScout.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// Implementation of PVS (Principal Variation Search)
/// A very lightweight algorithm, kinda dumb though
class NegaScoutCortex: MinimaxCortex {
    
    var bestMove: Move?
    
    override func getMove() -> Move {
        print("best move: \(pvs(depth, Int.min + 1, Int.max - 1))")
        return bestMove!
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
    func pvs(_ depth: Int, _ alpha: Int, _ beta: Int) -> Int {
        var score = getHeuristicValue(for: delegate.curPlayer), alpha = alpha
        if delegate.strategy.randomizedSelection {
            score += Int.random(in: 0..<10)
        }
        
        if isTerminal(score: score) || depth == 0 {
            return score
        }
        
        let candidates = getCandidates()
        
        for (idx, cand) in candidates.enumerated() {
            delegate.put(at: cand.co)
            if idx == 0 { // First child
                score = -pvs(depth - 1, -beta, -alpha)
            } else  {
                score = -pvs(depth - 1, -alpha - 1, -alpha)
                if alpha < score && score < beta {
                    score = -pvs(depth - 1, -beta, -score)
                }
            }
            delegate.revert()
            if score > alpha {
                alpha = score
                if depth == self.depth {
                    bestMove = (co: cand.co, score: alpha)
                }
            }
            if alpha > beta {
                break
            }
        }
        return alpha
    }
    
    override var description: String {
        return "NegaScout(depth: \(depth), breadth: \(breadth))"
    }
}
