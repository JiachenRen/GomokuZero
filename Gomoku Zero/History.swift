//
//  History.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/5/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

class History {
    var stack: [Coordinate]
    var reverted: [Coordinate]
    
    init() {
        stack = [Coordinate]()
        reverted = [Coordinate]()
    }
    
    /**
     Push a move into the history stack
     */
    func push(_ co: Coordinate) {
        stack.append(co)
        reverted = [Coordinate]() // Clear the history that's been overwritten
    }
    
    /**
     Used for reverting a move
     Extract a move from the history stack
     */
    func revert() -> Coordinate? {
        if stack.count == 0 {return nil}
        let co = stack.removeLast()
        reverted.append(co)
        return co
    }
    
    /**
     Used for restoring a reverted move
     */
    func restore() -> Coordinate? {
        if reverted.count == 0 {return nil}
        let co = reverted.removeLast()
        stack.append(co)
        return co
    }
    
    
}
