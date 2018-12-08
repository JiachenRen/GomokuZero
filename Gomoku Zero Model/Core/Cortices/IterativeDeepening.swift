//
//  IterativeDeepening.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/20/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class IterativeDeepeningCortex: MinimaxCortex {
    var completed = false
    var setup: (ZeroPlus, Int) -> ()
    var layers: Layers
    
    init(_ delegate: CortexDelegate, depth: Int, breadth: Int, layers: Layers = .all, _ setup: @escaping (ZeroPlus, Int) -> ()) {
        self.layers = layers
        self.setup = setup
        super.init(delegate, depth: depth, breadth: breadth)
    }
    
    override func getMove() -> Move {
        if let move = iterativeDeepening(depth: depth, breadth: breadth) {
            return move
        } else {
            print("iterative deepening failed. Generating basic move...")
            return BasicCortex(delegate).getMove()
        }
    }
    
    private func getDeepeningLayers() -> StrideTo<Int> {
        switch layers {
        case .all: return stride(from: 1, to: depth + 1, by: 1)
        case .evens: return stride(from: 2, to: depth * 2 + 1, by: 2)
        case .odds: return stride(from: 1, to: depth * 2, by: 2)
        }
    }
    
    private func iterativeDeepening(depth: Int, breadth: Int) -> Move? {
        completed = false
        var bestMove: Move?
        var workItems = [DispatchWorkItem]()
        var maxDepth = 0
        let group = DispatchGroup()
        
        for d in getDeepeningLayers() {
            let workItem = DispatchWorkItem{ [unowned self] in
                let zero2 = self.delegate as! ZeroPlus
                let zero = ZeroPlus(zero2)
                self.setup(zero, d)
                let bestForDepth = zero.cortex.getMove()
                let cancelled = (zero.cortex as! TimeLimitedSearchProtocol).searchCancelledInProgress
                if d > maxDepth && (bestMove == nil || !cancelled) {
                    // The deepter the depth, the more reliable the generated move.
                    bestMove = bestForDepth
                    maxDepth = d
                }
                zero.visDelegate?.activeMapUpdated(activeMap: nil)
                if self.delegate.verbose {
                    print("depth = \(d), co = (\(bestForDepth.co.col), \(bestForDepth.co.row)), score = \(bestForDepth.score) cancelled = \(cancelled), time = \(self.delegate.duration)")
                }
            }
            delegate.asyncedQueue.async(group: group, execute: workItem)
            workItems.append(workItem)
        }
        
        group.notify(queue: DispatchQueue.global()) {
            self.completed = true
        }
        
        
        while true {
            if completed || (delegate.timeout && bestMove != nil) {
                workItems.forEach{$0.cancel()}
                break
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        return bestMove
    }
    
    enum Layers: String {
        case all, odds, evens
    }
    
    override var description: String {
        let tmpZP = ZeroPlus()
        setup(tmpZP, depth)
        return "IterativeDeepening(depth: \(depth), breadth: \(breadth), layers: \(layers)) <-> \(tmpZP.cortex)"
    }
    
}
