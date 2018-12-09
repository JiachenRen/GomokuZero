//
//  Weights.swift
//  GZeroCommandLine
//
//  Created by Jiachen Ren on 11/10/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

typealias Weights = [Threat: Int]()

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
        [.blockedFour, .blockedPokedFour, .straightPokedFour],
        [.straightThree, .straightPokedThree],
        [.blockedThree, .blockedPokedThree],
        [.straightTwo, .straightPokedTwo],
        [.blockedTwo, .blockedPokedTwo]
        ]
    groups.forEach {threats in
        var mutated = Int(Double(w1[threats[0]]!) * (1 + Double.random(in: -variance...variance)))
        if mutated < 0 {
            mutated = 0
        }
        threats.forEach {weights[$0] = mutated}
    }
    return weights
}
