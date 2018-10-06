//
//  BoardWindowController.swift
//  Gomoku Zero
//
//  Created by Jiachen Ren on 10/6/18.
//  Copyright © 2018 Jiachen Ren. All rights reserved.
//

import Cocoa

class BoardWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        // Subscribe to notifications
        observe(saveNotif, #selector(save))
    }
    
    @objc func save() {
        print("Saving...")
        
    }

}
