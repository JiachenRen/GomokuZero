//
//  Gomoku_ZeroTests.swift
//  Gomoku ZeroTests
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import XCTest
@testable import Gomoku_Zero

class Gomoku_ZeroTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    typealias Weights = Dictionary<Threat, Int>
    func genRandomWeights(max: Int) -> Weights {
        var weights = Evaluator().weights
        weights.keys.forEach {key in
            weights[key] = Int.random(in: 0...max)
        }
        weights[.five] = 10_000_000_000_000_000
        weights[.none] = 0
        return weights
    }
    
    func hybridWeights(_ w1: Weights, pr1: Double, _ w2: Weights, pr2: Double) -> Weights {
        var weights = Evaluator().weights
        weights.keys.forEach {key in
            let hybrid = Int(Double(w1[key]!) * pr1 + Double(w2[key]!) * pr2)
            weights[key] = hybrid
        }
        weights[.five] = 10_000_000_000_000_000
        weights[.none] = 0
        return weights
    }
    
    func mutateWeights(_ w1: Weights, variance: Double) -> Weights {
        var weights = Evaluator().weights
        let groups: [[Threat]] = [ // Mutate by category
            [.straightFour],
            [.straightPokedFour],
            [.blockedFour, .blockedPokedFour],
            [.straightThree, .straightPokedThree],
            [.blockedThree, .blockedPokedThree],
            [.straightTwo, .straightPokedTwo],
            [.blockedTwo, .blockedPokedTwo],
        ]
        groups.forEach {threats in
            var mutated = Int(Double(w1[threats[0]]!) * (1 + Double.random(in: -variance...variance)))
            if mutated < 0 {
                mutated = 0
            }
            threats.forEach{weights[$0] = mutated}
        }
        return weights
    }
    
    func testWeights() {
        
        let initialWeights = Evaluator().weights
        
        let board = Board(dimension: 15)
        board.zeroXzero = true
        board.looped = true
        
        let zp1 = ZeroPlus()
        zp1.personality = .heuristic
        zp1.identity = .black
        zp1.verbose = false
        zp1.strategy.weights = initialWeights
        
        let zp2 = ZeroPlus()
        zp2.identity = .white
        zp2.personality = .heuristic
        zp2.verbose = false
        zp2.strategy.weights = mutateWeights(initialWeights, variance: 0.2)
        
        board.zeroPlus = zp1
        board.zeroPlus2 = zp2
        
        board.requestZeroBrainStorm()
        board.restartDelay = 0
        
        var count = 0
        var zp1Win = 0
        var zp2Win = 0
        var draw = 0
        var trailCompleted = false
        board.gameCompletionHandler = {[unowned self] winner in
            if winner == zp1.identity {
                zp1Win += 1
            } else if winner == .none {
                draw += 1
            } else {
                zp2Win += 1
            }
            zp1.identity = zp1.identity.next() // Black is now white, vice versa
            zp2.identity = zp2.identity.next()
            count += 1
            if count >= 10 {
                trailCompleted = !trailCompleted
                // Using stats principles, we can find optimal weight assignments from random game plays over many, many battles
                // Create hybrid weights from previous game results
                let totalWin = count - draw
                let zp1WinRatio = Double(zp1Win) / Double(totalWin)
                let zp2WinRatio = Double(zp2Win) / Double(totalWin)
                print("zp1 win: \(zp1Win) - \(zp1WinRatio)")
                print("zp2 win: \(zp2Win) - \(zp2WinRatio)")
                let hybridWeights = self.hybridWeights(zp1.strategy.weights!, pr1: zp1WinRatio, zp2.strategy.weights!, pr2: zp2WinRatio)
                let mutatedWeights = self.mutateWeights(hybridWeights, variance: 0.2)
                
                // Update weights of both AI
                zp1.strategy.weights = hybridWeights
                zp2.strategy.weights = mutatedWeights
                
                // 10 seconds form me to look over the results!
                
                print("hybrid weights:")
                hybridWeights.sorted{$0.value > $1.value}.forEach{print($0)}
                print("rand weights:")
                mutatedWeights.sorted{$0.value > $1.value}.forEach{print($0)}
                Thread.sleep(forTimeInterval: 2)
                
                // Clear counters
                count = 0
                zp1Win = 0
                zp2Win = 0
                draw = 0
            }
        }
        
        Thread.sleep(forTimeInterval: 1000)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
