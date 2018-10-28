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
    
    static let openPanel: NSOpenPanel = {
        let panel = NSOpenPanel(contentRect: .zero, styleMask: .fullSizeContentView, backing: .buffered, defer: true)
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["gzero"]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        return panel
    }()
    
    var viewController: BoardViewController {
        return window!.contentViewController as! BoardViewController
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
    
    static func open(_ completion: (([BoardWindowController]) -> Void)? = nil) {
        var controllers = [BoardWindowController]()
        
        openPanel.begin() { response in
            switch response {
            case .OK:
                var curFrame = NSApplication.shared.mainWindow?.frame ?? CGRect.zero
                for url in openPanel.urls {
                    curFrame.origin = CGPoint(x: curFrame.minX + 10, y: curFrame.minY - 10)
                    let boardWindowController = NSStoryboard(name: "Main", bundle: nil)
                        .instantiateController(withIdentifier: "board-window") as! BoardWindowController
                    do {
                        let game = try String(contentsOf: url, encoding: .utf8)
                        let fileName = url.lastPathComponent
                        let idx = fileName.firstIndex(of: ".")!
                        boardWindowController.fileName = String(fileName[..<idx]) // Update the name of the window
                        boardWindowController.board.load(game)
                        boardWindowController.showWindow(self)
                        if curFrame.size == .zero {
                            curFrame = boardWindowController.window!.frame
                        } else {
                            boardWindowController.window?.setFrame(curFrame, display: true, animate: true)
                        }
                        controllers.append(boardWindowController)
                    } catch let err {
                        print(err)
                    }
                }
                completion?(controllers)
            default: break
            }
        }
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

extension BoardWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        board.gameHasEnded = true
    }
}
