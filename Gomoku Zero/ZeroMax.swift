//
//  ZeroMax.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/21/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

/// A variant of minimax that attempts to address the horizon effect
class ZeroMax: MinimaxCortex {

    var basicCortex: BasicCortex
    
    /// An Int b/w 0 and 100 that denotes the probability in which a simulation should be performed.
    var rolloutPr: Int
    
    /// Defaults to Threat.interesting. Denotes the threshold beyond which a simulation might be performed.
    var threshold: Int
    
    /// Simulation deph during rollout.
    var simDepth: Int
    
    /**
     - Parameter rollout: an integer b/w 0 and 100 that denotes the probability of simulation at leaf nodes.
     - Parameter threshold: defaults to Threat.interesting. Denotes the threshold beyond which a simulation might be performed.
     - Parameter simDepth: depth of rollouts to be carried. Defaults to 10.
     */
    init(_ delegate: CortexDelegate, depth: Int, breadth: Int, rollout: Int, threshold: Int = Threat.interesting, simDepth: Int = 10) {
        self.basicCortex = BasicCortex(delegate)
        self.rolloutPr = rollout
        self.threshold  = threshold
        self.simDepth = simDepth
        super.init(delegate, depth: depth, breadth: breadth)
    }
    
    override func getMove() -> Move {
        let move = super.getMove()
        if verbose {
            print("rollout probability: \(rolloutPr)")
        }
        return move
    }
    
    
    
    /**
     A variant of minimax algorithm that attempts to address the horizon effect.
     The main difference is that instead of returning the heuristic value of the node,
     a simulation (rollout) is performed, and the heuristic value of the game state
     at the end of the simulation is used instead.
     
     - Returns: the best move for the current player in the given delegate.
     */
    override func minimax(depth: Int, breadth: Int, player: Piece,  alpha: Int, beta: Int) -> Move {
        var alpha = alpha, beta = beta, depth = depth // Make alpha beta mutable
        let score = getHeuristicValue()
        
        if isTerminal(score: score) {
            return Move(co: (0,0), score: score)
        } else if depth == 0 {
            var move = Move(co: (0,0), score: score)
            // Overcome horizon effect by looking further into interesting nodes
            let shouldRollout = rolloutPr != 0 && Int.random(in: 0...(100 - rolloutPr)) == 0
            if abs(score) > threshold && shouldRollout {
                let rolloutScore = rollout(depth: simDepth, policy: basicCortex)
                move.score = rolloutScore
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
