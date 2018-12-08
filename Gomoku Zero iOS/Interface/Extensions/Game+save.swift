//
//  Game+save.swift
//  Gomoku Zero iOS
//
//  Created by Jiachen Ren on 12/7/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Foundation

extension Game {
    static func save(_ board: Board, name: String? = nil) {
        let ctx = AppDelegate.sharedInstance.persistentContainer.viewContext
        let game = Game(context: ctx)
        game.data = board.serialize()
        game.name = name
        do {
            try ctx.save()
        } catch let e {
            print(e)
        }
    }
}
