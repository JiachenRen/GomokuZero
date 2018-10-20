//
//  Minimax.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class MinimaxCortex: CortexProtocol {
    var delegate: CortexDelegate
    
    var heuristicEvaluator = HeuristicEvaluator()
    var depth: Int
    var breadth: Int
    var searchCancelledInProgress = false
    var alphaCut = 0
    var betaCut = 0
    var cumCutDepth = 0
    var verbose = false
    
    init(_ delegate: CortexDelegate, depth: Int, breadth: Int) {
        self.depth = depth
        self.breadth = breadth
        self.delegate = delegate
        
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
    func minimax(depth: Int, breadth: Int, player: Piece,  alpha: Int, beta: Int) -> Move {
        var alpha = alpha, beta = beta, depth = depth // Make alpha beta mutable
        let score = getHeuristicValue()
        
        if score >= Threat.win || score <= -Threat.win { // Terminal state has reached
            return (co: (col: 0, row: 0), score: score)
        } else if depth == 0  {
            return Move(co: (0,0), score: score)
        }
        
        if player == identity {
            var bestMove = (co: (col: 0,row: 0), score: Int.min)
            let moves = [genSortedMoves(for: player, num: breadth), genSortedMoves(for: player.next(), num: breadth)].flatMap({$0})
            for move in moves.sorted(by: {$0.score > $1.score}) {
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
            let moves = [genSortedMoves(for: player, num: breadth), genSortedMoves(for: player.next(), num: breadth)].flatMap({$0})
            for move in moves.sorted(by: {$0.score > $1.score}) { // Should these be sorted?
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
