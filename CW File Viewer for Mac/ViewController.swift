//
//  ViewController.swift
//  CW File Viewer for Mac
//
//  Created by David Chen on 7/26/17.
//  Copyright © 2017 David Chen. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSPathControlDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var tbFiles: NSTableView!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var btnForward: NSButton!
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet var tvMain: NSTextView!
    @IBOutlet weak var tfFileName: NSTextField!
    
    // MARK: Vars & Lets
    
    let fileManager: FileManager = FileManager()
    
    var curPath: String = "/Users/david/Desktop", historyPaths: [String] = [];
    var historyIndex: Int = 0
    
    let sizeFormatter = ByteCountFormatter()
    var directory: Directory?
    var directoryItems: [Metadata] = []
    var sortOrder = Directory.FileOrder.Name
    var sortAscending = true
    
    // MARK: Functions
    
    func tvInit () {
        tvMain.font = NSFont.systemFont(ofSize: 18)
        
    }
    
    func reloadFileList(backorForward: Bool) {
        curPath = (directory?.url.path)!
        pathControl.url = directory?.url
        directoryItems = (directory?.contentsOrderedBy(sortOrder, ascending: sortAscending))!
        tbFiles.reloadData()
        if (historyPaths.count > 0 && !backorForward) {
            if (curPath != historyPaths[historyIndex]) {
                historyIndex += 1
                if (historyIndex >= historyPaths.count) {
                    historyPaths.append(curPath)
                }
                historyPaths[historyIndex] = curPath
            }
        }
        
        if (historyIndex > 0) {
            btnBack.isEnabled = true
        } else {
            btnBack.isEnabled = false
        }
        if (historyIndex < historyPaths.count - 1) {
            btnForward.isEnabled = true
        } else {
            btnForward.isEnabled = false
        }
    }
    
    func loadTextFile (fileurl: URL) {
        if (fileManager.isReadableFile(atPath: fileurl.path)) {
            //var str: String = "\(NSData(contentsOfFile: path))"
            let str = try! String(contentsOf: fileurl, encoding: String.Encoding.utf8)
            tvMain.string = str
            
            tfFileName.stringValue = fileurl.lastPathComponent
        }
    }
    
    // MARK: Startups
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tbFiles.delegate = self
        tbFiles.dataSource = self
        
        tbFiles.doubleAction = #selector(tableViewDoubleClick(_:))
        
        historyPaths.append(curPath)
        directory = Directory(folderURL: URL(string: curPath)!)
        reloadFileList(backorForward: false)
        
        btnBack.isEnabled = false
        btnForward.isEnabled = false
        
        tvInit()
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    // MARK: Button Actions
    
    @IBAction func btnBack_Clicked(_ sender: Any) {
        if (historyIndex > 0) {
            historyIndex -= 1
            directory = Directory(folderURL: URL(fileURLWithPath: historyPaths[historyIndex]))
            print(curPath)
            print(historyIndex)
            
            reloadFileList(backorForward: true)
            btnForward.isEnabled = true
        } else {
            btnBack.isEnabled = false
        }
    }
    
    @IBAction func btnForward_Clicked(_ sender: Any) {
        if (historyIndex < historyPaths.count - 1) {
            historyIndex += 1
            directory = Directory(folderURL: URL(fileURLWithPath: historyPaths[historyIndex]))
            print(curPath)
            print(historyIndex)
            
            reloadFileList(backorForward: true)
            btnBack.isEnabled = true
        } else {
            btnForward.isEnabled = false
        }
    }
    
    // MARK: TableView DataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return directoryItems.count
    }

    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var image: NSImage?
        var text: String = ""
        
        // 1
        let item = directoryItems[row]
        image = item.icon
        text = item.name
        // 3
        let cell = tableView.make(withIdentifier: "NameCellID", owner: nil) as? NSTableCellView
        cell?.textField?.stringValue = text
        cell?.imageView?.image = image ?? nil
        return cell
    }
    
    func tableViewDoubleClick(_ sender:AnyObject) {
        if (tbFiles.selectedRow >= 0) {
            let item = directoryItems[tbFiles.selectedRow]
            if (item.isFolder) {
                directory = Directory(folderURL: item.url)
                reloadFileList(backorForward: false)
            } else {
                NSWorkspace.shared().open(item.url as URL)
            }
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if (tbFiles.selectedRow >= 0) {
            let item = directoryItems[tbFiles.selectedRow]
            if (item.isFolder) {
                directory = Directory(folderURL: item.url)
                reloadFileList(backorForward: false)
            } else {
                if (item.url.pathExtension.lowercased() == "txt") {
                    loadTextFile(fileurl: item.url)
                } else {
                    NSWorkspace.shared().open(item.url as URL)
                }
            }
        }
    }
    
    // MARK: PathControl Delegate
    
    func pathControl(_ pathControl: NSPathControl, willPopUp menu: NSMenu) {
        print ("will pop up")
    }
    
    @IBAction func pathControl_Clicked(_ sender: Any) {
        if ((pathControl.clickedPathItem?.url) != nil) {
            let path: String = (pathControl.clickedPathItem?.url)!.path
            if (fileManager.fileExists(atPath: path)) {
                directory = Directory(folderURL: (self.pathControl.clickedPathItem?.url)!)
                reloadFileList(backorForward: false)
            }
        }
    }
    
}
