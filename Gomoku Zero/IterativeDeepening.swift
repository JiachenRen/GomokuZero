//
//  IterativeDeepening.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class IterativeDeepeningCortex: CortexProtocol {
    var delegate: CortexDelegate
    
    var heuristicEvaluator = HeuristicEvaluator()
    var iterativeDeepeningCompleted = false
    var depth: Int
    var breadth: Int
    var setup: (ZeroPlus, Int) -> ()
    
    init(_ delegate: CortexDelegate, depth: Int, breadth: Int, _ setup: @escaping (ZeroPlus, Int) -> ()) {
        self.depth = depth
        self.breadth = breadth
        self.delegate = delegate
        self.setup = setup
    }
    
    func getMove() -> Move {
        return iterativeDeepening(depth: depth, breadth: breadth)
    }
    
    private func iterativeDeepening(depth: Int, breadth: Int) -> Move {
        iterativeDeepeningCompleted = false
        var bestMove: Move?
        var workItems = [DispatchWorkItem]()
        var maxDepth = 0
        let group = DispatchGroup()
        
        for d in 1...depth {
            let workItem = DispatchWorkItem {
                let zero = ZeroPlus()
                let zero2 = self.delegate as! ZeroPlus
                zero.delegate = zero2.delegate
                zero.zobrist = Zobrist(zobrist: zero2.zobrist)
                zero.genActiveCoMap()
                zero.activeMapDiffStack = [[Coordinate]]()
                zero.curPlayer = zero2.curPlayer
                zero.identity = zero2.identity
                zero.startTime = zero2.startTime
                zero.maxThinkingTime = zero2.maxThinkingTime
                zero.visDelegate = zero2.visDelegate
                self.setup(zero, d)
                let bestForDepth = zero.cortex!.getMove()
                let cancelled = (zero.cortex as! TimeLimitedSearchProtocol).searchCancelledInProgress
                if d > maxDepth && !cancelled {
                    // The deepter the depth, the more reliable the generated move.
                    bestMove = bestForDepth
                    maxDepth = d
                }
                zero.visDelegate?.activeMapUpdated(activeMap: nil)
                print("deepening finished at depth = \(d), move = \(bestForDepth), cancelled = \(cancelled)")
            }
            delegate.asyncedQueue.async(group: group, execute: workItem)
            workItems.append(workItem)
        }
        
        group.notify(queue: DispatchQueue.global()) {
            self.iterativeDeepeningCompleted = true
        }
        
        
        while true {
            let timeElapsed = Date().timeIntervalSince1970 - delegate.startTime
            let timeExceeded = timeElapsed > delegate.maxThinkingTime
            if iterativeDeepeningCompleted || (timeExceeded && bestMove != nil) {
                workItems.forEach{$0.cancel()}
                break
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        return bestMove!
    }
    
    
}
