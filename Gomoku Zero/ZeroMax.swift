//
//  ZeroMax.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/21/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// A variant of minimax that attempts to address the horizon effect
class ZeroMax: CortexProtocol, TimeLimitedSearchProtocol {
    var delegate: CortexDelegate
    
    var heuristicEvaluator = HeuristicEvaluator()
    var depth: Int
    var breadth: Int
    var searchCancelledInProgress = false
    var alphaCut = 0
    var betaCut = 0
    var cumCutDepth = 0
    var verbose = false
    var basicCortex: BasicCortex
    
    init(_ delegate: CortexDelegate, depth: Int, breadth: Int) {
        self.depth = depth
        self.breadth = breadth
        self.delegate = delegate
        basicCortex = BasicCortex(delegate)
        heuristicEvaluator.delegate = self
    }
    
    func getMove() -> Move {
        let move = minimax(depth: depth, breadth: breadth, player: identity, alpha: Int.min, beta: Int.max)
        if verbose {
            let avgCutDepth = Double(cumCutDepth) / Double(alphaCut + betaCut)
            print("alpha cut: \(alphaCut)\t beta cut: \(betaCut)\t avg. cut depth: \(avgCutDepth))")
            print("recognized sequences: \(ThreatEvaluator.seqHashMap.count)")
            print("recognized sequence groups: \(ThreatEvaluator.seqGroupHashMap.count)")
            print("calc. duration (s): \(Date().timeIntervalSince1970 - delegate.startTime)")
        }
        return move
    }
    
    //    function minimax(node, depth, maximizingPlayer)
    //    02     if depth = 0 or node is a terminal node
    //    03         return the heuristic value of node
    //
    //    04     if maximizingPlayer
    //    05         bestValue := −∞
    //    06         for each child of node
    //    07             v := minimax(child, depth − 1, FALSE)
    //    08             bestValue := max(bestValue, v)
    //    09         return bestValue
    //
    //    10     else    (* minimizing player *)
    //    11         bestValue := +∞
    //    12         for each child of node
    //    13             v := minimax(child, depth − 1, TRUE)
    //    14             bestValue := min(bestValue, v)
    //    15         return bestValue
    
    func isTerminal(score: Int) -> Bool {
        return score >= Threat.win || score <= -Threat.win
    }
    
    func minimax(depth: Int, breadth: Int, player: Piece,  alpha: Int, beta: Int) -> Move {
        var alpha = alpha, beta = beta, depth = depth // Make alpha beta mutable
        let score = getHeuristicValue()
        
        if isTerminal(score: score) {
            return Move(co: (0,0), score: score)
        } else if depth == 0 {
            var move = Move(co: (0,0), score: score)
            // Overcome horizon effect by looking further into interesting nodes
            if abs(score) > Threat.interesting && Int.random(in: 0..<1) == 0 {
                let rolloutScore = rollout(depth: 10, policy: basicCortex)
//                if isTerminal(score: rolloutScore) {
                    move.score = rolloutScore
//                }
            }
            return move
        }
        
        if player == identity {
            var bestMove = (co: (col: 0, row: 0), score: Int.min)
            
            for move in getSortedMoves(num: breadth) {
                delegate.put(at: move.co)
                let score = minimax(depth: depth - 1, breadth: breadth, player: player.next(),alpha: alpha, beta: beta).score
                delegate.revert()
                if score > bestMove.score {
                    bestMove = move
                    bestMove.score = score
                    if score >= Threat.win {
                        return bestMove
                    }
                    
                    alpha = max(alpha, score)
                    if beta <= alpha {
                        bestMove.score = alpha
                        cumCutDepth += depth
                        alphaCut += 1
                        return bestMove
                    }
                }
                // Time limited threat space search
                if timeout() {
                    searchCancelledInProgress = true
                    return bestMove
                }
            }
            return bestMove
        } else {
            var bestMove = (co: (col: 0,row: 0), score: Int.max)
            
            for move in getSortedMoves(num: breadth) { // Should these be sorted?
                delegate.put(at: move.co)
                let score = minimax(depth: depth - 1, breadth: breadth, player: player.next(), alpha: alpha, beta: beta).score
                delegate.revert()
                if score < bestMove.score {
                    bestMove = move
                    bestMove.score = score
                    if score <= -Threat.win {
                        return bestMove
                    }
                    
                    beta = min(beta, score)
                    if beta <= alpha {
                        bestMove.score = beta
                        cumCutDepth += depth
                        betaCut += 1
                        return bestMove
                    }
                }
                if timeout() {
                    searchCancelledInProgress = true
                    return bestMove
                }
            }
            return bestMove
        }
    }
}
