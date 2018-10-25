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
     A modification to the minimax algorithm that attempts to address the horizon effect.
     It attempts to look beyond the horizon by playing out a full simulation
     of the current leaf node game state until a winner emerges.
     Otherwise, there is nothing beyond the horizon and the original heuristic value is returned.
     
     - Returns: modified heuristic value of the node.
     */
    override func beyondHorizon(of score: Int) -> Int {
        // Overcome horizon effect by looking further into interesting nodes
        let shouldRollout = rolloutPr != 0 && Int.random(in: 0...(100 - rolloutPr)) == 0
        if abs(score) > threshold && shouldRollout {
            let rolloutScore = rollout(depth: simDepth, policy: basicCortex)
            if isTerminal(score: rolloutScore) {
                return rolloutScore
            }
        }
        return score
    }
}
