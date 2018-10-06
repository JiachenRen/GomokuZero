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

    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Subscribe to notifications
        observe(saveNotif, #selector(save))
        
        // Establish communication with ViewController
        viewController.delegate = self
    }
    
    
    
    @objc func save() {
        print("Saving...")
        let panel = NSSavePanel(contentRect: contentViewController!.view.bounds, styleMask: .fullSizeContentView, backing: .buffered, defer: true)
        panel.allowedFileTypes = ["gzero"]
        panel.delegate = self
        if let window = self.window {
            panel.beginSheetModal(for: window) { response in
                switch response {
                case .OK: window.title = "Zero + (Saved)"
                default: break
                }
            }
        }
    }

    func panel(_ sender: Any, validate url: URL) throws {
        print(url)
        let str = "Success!"
        do {
            try str.write(to: url, atomically: true, encoding: .utf8)
        } catch let err {
            print(err)
        }
    }
}
