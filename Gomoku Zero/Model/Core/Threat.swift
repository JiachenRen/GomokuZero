//
//  ThreatType.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/7/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

enum Threat: Int, CustomStringConvertible {
    
    static let win = 1_000_000_000_000_000
    static let interesting = Threat.straightPokedThree.rawValue - 1
    
    var description: String {
        switch self {
        case .five: return "5"
        case .straightFour: return "s-4"
        case .straightThree: return "s-3"
        case .straightTwo: return "s-2"
        case .blockedFour: return "b-4"
        case .blockedThree: return "b-3"
        case .blockedTwo: return "b-2"
        case .straightPokedFour: return "s-p-4"
        case .straightPokedThree: return "s-p-3"
        case .straightPokedTwo: return "s-p-2"
        case .blockedPokedFour: return "b-p-4"
        case .blockedPokedThree: return "b-p-3"
        case .blockedPokedTwo: return "b-p-2"
        case .none: return "none"
        }
    }
    
    case five = 10_000_000_000_000_000 // Just a large number that nullifies the influence of the rest
    
    case straightFour =  100_000
    case straightPokedFour = 6000
    case blockedFour =   5000
    case blockedPokedFour = 4989
    
    case straightThree = 4000
    case straightPokedThree = 3989
    case blockedThree =  1000
    case blockedPokedThree = 989
    
    case straightTwo = 100
    case straightPokedTwo = 90
    case blockedTwo = 80
    case blockedPokedTwo = 70
    
    case none = 0
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
