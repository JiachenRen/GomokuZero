//
//  ThreatType.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/7/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

enum ThreatType: Int, CustomStringConvertible {
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
    
    case five = 100000
    
    case straightFour = 10000
    case straightThree = 1000
    case straightTwo = 100
    
    case blockedFour = 500
    case blockedThree = 50
    case blockedTwo = 10
    
    case straightPokedFour = 5000
    case straightPokedThree = 900
    case straightPokedTwo = 99
    
    case blockedPokedFour = 499
    case blockedPokedThree = 49
    case blockedPokedTwo = 9
    
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
    
    func toThreatType(head: Head) -> ThreatType {
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
