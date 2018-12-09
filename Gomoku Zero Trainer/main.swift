//
//  main.swift
//  GZeroCommandLine
//
//  Created by Jiachen Ren on 11/10/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

// Figure out the proper weights that should be assigned to each threat pattern through self-play!

let initialWeights = Evaluator().weights

let board = Board(dimension: 15)
board.zeroXzero = true
board.looped = true

let trainer = ZeroPlus()
trainer.personality = .minimax(depth: 2, breadth: 2)
trainer.identity = .black
trainer.verbose = false

let trainee = ZeroPlus()
trainee.identity = .white
trainee.personality = .heuristic
trainee.strategy.weights = initialWeights
trainee.verbose = false

board.zeroPlus = trainer
board.zeroPlus2 = trainee
board.restartDelay = 0

var stat = Stat()
var baseline: Double?
var bestWeights = trainee.strategy.weights!

func configure(winner: Piece) {
    stat.update(winner)
    if stat.total == stat.simulations {
        print(stat)
        if baseline == nil {
            baseline = stat.ratio
            trainee.strategy.weights = mutateWeights(bestWeights, variance: 0.1)
            print("baseline established: \(baseline!)")
        } else if stat.ratio > baseline! && stat.ratio > 1 {
            print("mutation successful, current baseline \(stat.ratio)")
            print("previous baseline \(baseline!)")
            print("best weights: ")
            bestWeights.sorted {$0.value > $1.value}
                .map {($0.rawValue, $1)}
                .forEach {print($0)}
            
            // Update best weights, eventually it would converge with optimal weights
            bestWeights = trainee.strategy.weights!
            trainer.strategy.weights = bestWeights
            
            // Reset baseline
            baseline = nil
        } else {
            // Fall back to previous weights, attempt to get better through mutation
            trainee.strategy.weights = mutateWeights(bestWeights, variance: 0.5)
        }
        
        Thread.sleep(forTimeInterval: 5)
        
        stat = Stat() // Clear stats
    }
    
    // Switch color
    board.zeroPlus2!.identity = board.zeroPlus2!.identity.next()
    board.zeroPlus.identity = board.zeroPlus.identity.next()
}

board.gameCompletionHandler = configure
board.requestZeroBrainStorm() // Start training

Thread.sleep(forTimeInterval: 1000)
