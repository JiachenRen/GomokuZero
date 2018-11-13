//
//  Stat.swift
//  GZeroCommandLine
//
//  Created by Jiachen Ren on 11/10/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

public struct Stat: CustomStringConvertible {
    var total = 0
    var traineeWin = 0
    var trainerWin = 0
    let simulations = 10
    
    var ratio: Double {
        return Double(traineeWin) / Double(trainerWin)
    }
    
    mutating func update(_ winner: Piece) {
        total += 1
        if winner == board.zeroPlus.identity {
            trainerWin += 1
        } else if winner == board.zeroPlus2!.identity {
            traineeWin += 1
        }
    }
    
    public var description: String {
        return "total: \(total)\ntrainee: \(traineeWin)\ntrainer: \(trainerWin)\nratio: \(ratio)"
    }
}
