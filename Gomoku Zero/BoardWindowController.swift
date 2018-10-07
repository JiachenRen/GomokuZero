//
//  BoardWindowController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class BoardWindowController: NSWindowController, NSOpenSavePanelDelegate, ViewControllerDelegate {
    
    var board: Board {
        return viewController.board
    }
    
    var viewController: ViewController {
        return window!.contentViewController as! ViewController
    }
    
    var fileName = "New Game" {
        didSet {
            let dim = board.dimension
            window?.title = "\(fileName)\t\(dim) x \(dim)"
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Establish communication with ViewController
        viewController.delegate = self
    }
    
    
    
    func save() {
        if board.history.stack.isEmpty {
            let _ = dialogue(msg: "Cannot save empty game.", infoTxt: "Give me some juice!")
            return
        }
        print("Saving...")
        let panel = NSSavePanel(contentRect: contentViewController!.view.bounds, styleMask: .fullSizeContentView, backing: .buffered, defer: true)
        panel.allowedFileTypes = ["gzero"]
        panel.delegate = self
        if let window = self.window {
            panel.nameFieldStringValue = fileName
            panel.beginSheetModal(for: window) {response in
                switch response {
                case .OK:
                    self.fileName = panel.nameFieldStringValue
                default: break
                }
            }
        }
    }

    func panel(_ sender: Any, validate url: URL) throws {
        do {
            print("Saving to \(url)")
            let game = board.serialize()
            try game.write(to: url, atomically: true, encoding: .utf8)
        } catch let err {
            print(err)
        }
    }
}
