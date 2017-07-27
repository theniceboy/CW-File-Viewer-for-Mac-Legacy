//
//  ViewController.swift
//  CW File Viewer for Mac
//
//  Created by David Chen on 7/26/17.
//  Copyright © 2017 David Chen. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSPathControlDelegate, NSTextViewDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var tbFiles: NSTableView!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var btnForward: NSButton!
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet var tvMain: NSTextView!
    @IBOutlet weak var tfFileName: NSTextField!
    @IBOutlet weak var btnDelete: NSButton!
    
    // MARK: Vars & Lets
    
    let fileManager: FileManager = FileManager()
    
    var curFile: String = "", curTextFile: String = "", curPath: String = "/", historyPaths: [String] = []
    var curContent: String = ""
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
            historyIndex += 1
            if (historyIndex >= historyPaths.count) {
                historyPaths.append(curPath)
            }
            historyPaths[historyIndex] = curPath
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
            if (curContent != tvMain.string && curTextFile != "") {
                try! tvMain.string?.write(toFile: curTextFile, atomically: true, encoding: String.Encoding.utf8)
            }
            var str = ""
            do {
                str = try String(contentsOf: fileurl, encoding: String.Encoding.utf8)
                tvMain.string = str
                curTextFile = fileurl.path
                curContent = tvMain.string!
            } catch {
                let alert = NSAlert()
                alert.messageText = "文件编码不识别，请手动更改编码至UTF-8"
                alert.alertStyle = NSAlertStyle.critical
                alert.addButton(withTitle: "确定")
                alert.runModal()
                NSWorkspace.shared().open(fileurl)
            }
            tfFileName.stringValue = fileurl.lastPathComponent
        }
    }
    
    // MARK: Startups
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tbFiles.delegate = self
        tbFiles.dataSource = self
        
        tbFiles.doubleAction = #selector(tableViewDoubleClick(_:))
        
        curPath = fileManager.homeDirectoryForCurrentUser.path + "/Documents"
        historyPaths.append(curPath)
        directory = Directory(folderURL: URL(string: curPath)!)
        reloadFileList(backorForward: false)
        
        btnBack.isEnabled = false
        btnForward.isEnabled = false
        
        
        
        tvInit()
    }

    override var representedObject: Any? {
        didSet {
            directory = Directory(folderURL: representedObject as! URL)
            reloadFileList(backorForward: false)
        }
    }
    
    // MARK: Button Actions
    
    @IBAction func btnBack_Clicked(_ sender: Any) {
        if (historyIndex > 0) {
            historyIndex -= 1
            directory = Directory(folderURL: URL(fileURLWithPath: historyPaths[historyIndex]))
            
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
    
    @IBAction func btnRename_Clicked(_ sender: Any) {
        if (tfFileName.stringValue.trimmingCharacters(in: .whitespaces) == "") {
            let alert = NSAlert()
            alert.messageText = "文件名不得为空"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        let file = URL(string: curPath)?.appendingPathComponent(tfFileName.stringValue.trimmingCharacters(in: .whitespaces))
        if (fileManager.fileExists(atPath: (file?.path)!)) {
            let alert = NSAlert()
            alert.messageText = "同名文件已存在"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        try! fileManager.moveItem(atPath: curFile, toPath: (file?.path)!)
        curFile = (file?.path)!
        if (file?.pathExtension.lowercased() == "txt") {
            curTextFile = curFile
        }
        btnRefresh_Clicked(self)
    }
    
    @IBAction func btnNewFile_Clicked(_ sender: Any) {
        if (tfFileName.stringValue.trimmingCharacters(in: .whitespaces) == "") {
            let alert = NSAlert()
            alert.messageText = "文件名不得为空"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        let file = URL(string: curPath)?.appendingPathComponent(tfFileName.stringValue.trimmingCharacters(in: .whitespaces))
        if (fileManager.fileExists(atPath: (file?.path)!)) {
            let alert = NSAlert()
            alert.messageText = "同名文件已存在"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        //fileManager.createFile(atPath: (file?.path)!, contents: <#T##Data?#>, attributes: <#T##[String : Any]?#>)
        fileManager.createFile(atPath: (file?.path)!, contents: nil, attributes: nil)
        //let tmpStr = "123123"
        //ry! tmpStr.write(to: file!, atomically: true, encoding: .utf8)
        
        btnRefresh_Clicked(self)
        var index = 0
        for item in directoryItems {
            if (item.name == file?.lastPathComponent) {
                let indexset = NSIndexSet(index: index)
                tbFiles.selectRowIndexes(indexset as IndexSet, byExtendingSelection: false)
                return
            }
            index += 1
        }
    }
    
    @IBAction func AddTXTExt_Clicked(_ sender: Any) {
        tfFileName.stringValue.append(".txt")
    }
    
    @IBAction func btnRefresh_Clicked(_ sender: Any) {
        directory = Directory(folderURL: URL(string: curPath)!)
        reloadFileList(backorForward: false)
    }
    
    @IBAction func btnDelete_Clicked(_ sender: Any) {
        try!  fileManager.removeItem(atPath: curFile)
        btnRefresh_Clicked(self)
        btnDelete.isEnabled = false
    }
    
    @IBAction func BtnAddTXTExtAndNew_Clicked(_ sender: Any) {
        tfFileName.stringValue.append(".txt")
        btnNewFile_Clicked(self)
    }
    
    @IBAction func BtnAddDateTime_Clicked(_ sender: Any) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd  HH：mm"
        tfFileName.stringValue.append(formatter.string(from: NSDate() as Date))
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
            btnDelete.isEnabled = true
            let item = directoryItems[tbFiles.selectedRow]
            if (item.isFolder) {
                directory = Directory(folderURL: item.url)
                reloadFileList(backorForward: false)
            } else {
                curFile = item.url.path
                if (item.url.pathExtension.lowercased() == "txt") {
                    loadTextFile(fileurl: item.url)
                } else {
                    NSWorkspace.shared().open(item.url as URL)
                }
            }
        } else {
            btnDelete.isEnabled = false
        }
    }
    
    // MARK: TextView Delegate
    
    
    // MARK: PathControl Delegate
    
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
