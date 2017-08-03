//
//  WindowController.swift
//  CW File Viewer for Mac
//
//  Created by David Chen on 7/27/17.
//  Copyright © 2017 David Chen. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    @IBAction func openDocument(_ sender: AnyObject?) {
        
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles = false
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        openPanel.beginSheetModal(for: window!) { response in
            guard response == NSFileHandlingPanelOKButton else {
                return
            }
            self.contentViewController?.representedObject = openPanel.url
        }
    }
    
    var subview: WindowController?
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        let story = self.storyboard
        let windowVC = story?.instantiateInitialController() as! WindowController
        self.window?.addTabbedWindow(windowVC.window!, ordered: NSWindowOrderingMode.above)
        self.subview = windowVC
        windowVC.window?.orderFront(self)
        windowVC.window?.makeKey()
        
    }
    
    
}
