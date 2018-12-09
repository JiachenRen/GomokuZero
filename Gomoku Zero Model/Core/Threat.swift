//
//  ThreatType.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/7/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//
//  swiftlint:disable cyclomatic_complexity

import Foundation

enum Threat: String {
    case five = "5"
    
    case straightFour = "s-4"
    case straightPokedFour = "s-p-4"
    case blockedFour = "b-4"
    case blockedPokedFour = "b-p-4"
    
    case straightThree = "s-3"
    case straightPokedThree = "s-p-3"
    case blockedThree = "b-3"
    case blockedPokedThree = "b-p-3"
    
    case straightTwo = "s-2"
    case straightPokedTwo = "s-p-2"
    case blockedTwo = "b-2"
    case blockedPokedTwo = "b-p-2"
    
    case none
}

protocol EvaluatorDataSource {
    var pieces: [[Piece]] {get}
}

enum Head {
    case blocked
    case straight
}

enum Sequence {
    case five, four, three, two
    case pokedFour, pokedThree, pokedTwo
    case none
    
    static func resolve(same: Int, gap: Int, gapIdx: Int) -> Sequence {
        if gap > 1 {return .none}
        if gap == 1 {
            switch same {
            case 2: return .pokedTwo
            case 3: return .pokedThree
            case 4: return .pokedFour
            default:
                if same > 5 {
                    if gapIdx == 5 || same - gapIdx == 5 {
                        return .five
                    }
                }
                return .none
            }
        } else { // gap == 0
            switch same {
            case 2: return .two
            case 3: return .three
            case 4: return .four
            case 5: return .five
            default: return .none
            }
        }
    }
    
    func toThreatType(head: Head) -> Threat {
        switch head {
        case .blocked:
            switch self {
            case .five: return .five
            case .four: return .blockedFour
            case .three: return .blockedThree
            case .two: return .blockedTwo
            case .pokedFour: return .blockedPokedFour
            case .pokedThree: return .blockedPokedThree
            case .pokedTwo: return .blockedPokedTwo
            case .none: return .none
            }
        case .straight:
            switch self {
            case .five: return .five
            case .four: return .straightFour
            case .three: return .straightThree
            case .two: return .straightTwo
            case .pokedFour: return .straightPokedFour
            case .pokedThree: return .straightPokedThree
            case .pokedTwo: return .straightPokedTwo
            case .none: return .none
            }
        }
    }
}
