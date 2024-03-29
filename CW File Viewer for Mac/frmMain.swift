//
//  ViewController.swift
//  CW File Viewer for Mac
//
//  Created by David Chen on 7/26/17.
//  Copyright © 2017 David Chen. All rights reserved.
//

import Cocoa

class frmMain: NSViewController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSPathControlDelegate, NSTextViewDelegate {

    // MARK: Outlets
    
    @IBOutlet var vMain: NSView!
    @IBOutlet weak var tbFiles: NSTableView!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var btnForward: NSButton!
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet var tvMain: NSTextView!
    @IBOutlet weak var tfFileName: NSTextField!
    @IBOutlet weak var btnDelete: NSButton!
    @IBOutlet weak var lbFileCount: NSTextField!
    @IBOutlet weak var lbFileWordCount: NSTextField!
    @IBOutlet weak var btnSave: NSButton!
    
    // MARK: Vars & Lets
    
    var firstOpen: Bool = true {
        didSet {
            if (!firstOpen) {
                btnSave.isEnabled = true
            }
        }
    }
    
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
        
        lbFileCount.stringValue = "\(directoryItems.count)个项目"
        
        self.view.window?.title = curPath
    }
    
    var fromArchive: Bool = false
    func loadTextFile (fileurl: URL) {
        if (fileManager.isReadableFile(atPath: fileurl.path)) {
            if (!firstOpen) {
                if (curContent != tvMain.string) {
                    try! tvMain.string?.write(toFile: curTextFile, atomically: true, encoding: String.Encoding.utf8)
                }
            } else {
                firstOpen = false
            }
            var str = ""
            do {
                str = try String(contentsOf: fileurl, encoding: String.Encoding.utf8)
                if (fromArchive) {
                    tvMain.string = archiveContent
                    fromArchive = false
                } else {
                    tvMain.string = str
                }
                curTextFile = fileurl.path
                curContent = tvMain.string!
            } catch {
                do {
                    let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
                    str = try String(contentsOf: fileurl, encoding: String.Encoding(rawValue: enc))
                    if (fromArchive) {
                        tvMain.string = archiveContent
                        fromArchive = false
                    } else {
                        tvMain.string = str
                    }
                    curTextFile = fileurl.path
                    curContent = tvMain.string!
                } catch {
                    do {
                        str = try String(contentsOf: fileurl, encoding: String.Encoding.ascii)
                        if (fromArchive) {
                            tvMain.string = archiveContent
                            fromArchive = false
                        } else {
                            tvMain.string = str
                        }
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
                }
            }
            tfFileName.stringValue = fileurl.lastPathComponent
        }
        let startoffile = NSPoint(x: 0, y: 0)
        tvMain.scroll(startoffile)
        lbFileWordCount.stringValue = "\(curContent.characters.count)字 \(curContent.components(separatedBy: " ").count)英文单词"
    }
    
    // MARK: Startups
    
    override func viewDidAppear() {
        self.view.window?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tbFiles.delegate = self
        tbFiles.dataSource = self
        
        tbFiles.doubleAction = #selector(tableViewDoubleClick(_:))
        
        curPath = fileManager.homeDirectoryForCurrentUser.path + "/Desktop"
        historyPaths.append(curPath)
        directory = Directory(folderURL: URL(fileURLWithPath: curPath))
        reloadFileList(backorForward: false)
        
        btnBack.isEnabled = false
        btnForward.isEnabled = false
        
        tvInit()
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        if (firstOpen) {
            return true
        }
        
        var doclose: Bool = false
        
        if (curContent != tvMain.string) {
            let alert = NSAlert()
            alert.messageText = "文件最新的编辑未保存，是否保存？"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "保存")
            alert.addButton(withTitle: "不保存")
            alert.addButton(withTitle: "取消")
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (returnCode: NSModalResponse) in
                if (returnCode == 1000) {
                    do {
                        try self.tvMain.string?.write(toFile: self.curTextFile, atomically: true, encoding: String.Encoding.utf8)
                        doclose = true
                    } catch {
                        let savefail = NSAlert()
                        savefail.messageText = "保存失败"
                        savefail.alertStyle = NSAlertStyle.critical
                        savefail.addButton(withTitle: "确定")
                        savefail.runModal()
                    }
                } else if (returnCode == 1001) {
                    doclose = true
                }
                self.view.window?.close()
            })
        } else {
            doclose = true
        }
        return doclose
            /*
        {
            if (curContent != tvMain.string) {
                do {
                    try tvMain.string?.write(toFile: curTextFile, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    let savefail = NSAlert()
                    alert.messageText = "保存失败"
                    alert.alertStyle = NSAlertStyle.critical
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
 */
        //let choice = alert.runModal()
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
    
    @IBAction func btnOpenInFinder_Clicked(_ sender: Any) {
        NSWorkspace.shared().openFile(curPath)
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
        let filepath = curPath + "/" + tfFileName.stringValue.trimmingCharacters(in: .whitespaces)
        let fileurl = URL(fileURLWithPath: filepath)
        if (fileManager.fileExists(atPath: filepath)) {
            let alert = NSAlert()
            alert.messageText = "同名文件已存在"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        do {
            try fileManager.moveItem(atPath: curFile, toPath: filepath)
        } catch {
            let alert = NSAlert()
            alert.messageText = "重命名文件失败"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
        curFile = filepath
        if (fileurl.pathExtension.lowercased() == "txt") {
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
        print(curPath)
        let filepath = curPath + "/" + tfFileName.stringValue.trimmingCharacters(in: .whitespaces)
        let fileurl = URL(fileURLWithPath: filepath)
        print(fileurl)
        print(filepath)
        
        if (fileManager.fileExists(atPath: filepath)) {
            let alert = NSAlert()
            alert.messageText = "同名文件/文件夹已存在"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        
        let filename = filepath.components(separatedBy: "/").last
        let fileext = filepath.components(separatedBy: ".").last
        
        if (fileext == "" || filepath.components(separatedBy: ".").count == 1) {
            do {
                try fileManager.createDirectory(atPath: filepath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                let alert = NSAlert()
                alert.messageText = "新建文件夹失败"
                alert.alertStyle = NSAlertStyle.critical
                alert.addButton(withTitle: "确定")
                alert.runModal()
            }
            //btnRefresh_Clicked(self)
            //return
        } else {
            if (fromArchive) {
                do {
                    try archiveContent.write(toFile: fileurl.path, atomically: true, encoding: String.Encoding.utf8)
                } catch { }
            } else {
                fileManager.createFile(atPath: filepath, contents: nil, attributes: nil)
            }
        }
        
        btnRefresh_Clicked(self)
        var index = 0
        for item in directoryItems {
            if (item.name == filename) {
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
        directory = Directory(folderURL: URL(fileURLWithPath: curPath))
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
        formatter.dateFormat = "yyyy-MM-dd HH;mm"
        tfFileName.stringValue.append(formatter.string(from: NSDate() as Date))
    }
    
    
    @IBAction open func btnSave_Clicked(_ sender: Any) {
        do {
            try tvMain.string?.write(toFile: curTextFile, atomically: true, encoding: String.Encoding.utf8)
            curContent = tvMain.string!
        } catch {
            let alert = NSAlert()
            alert.messageText = "文件保存失败"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    @IBAction func btnRemoveExtraEndline_Clicked(_ sender: Any) {
        tvMain.string = tvMain.string?.replaceAll(of: " \n", with: " ")
    }
    
    // MARK: Menu Items
    
    var archiveTitle: String = ""
    var archiveContent: String = ""
    @IBAction func newTXTfromArchiveOrg(_ sender: AnyObject?) {
        let link = tfFileName.stringValue.trim()
        archiveTitle = getArchiveTXTTitle(link: link)
        archiveContent = getArchiveTXT(link: link)
        if (archiveTitle.trim() == "" || archiveContent.trim() == "") {
            let alert = NSAlert()
            alert.messageText = "文件创建失败"
            alert.alertStyle = NSAlertStyle.critical
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        archiveContent = "Origin Link: " + link + "\n\n\n" + archiveContent
        tfFileName.stringValue = archiveTitle + ".txt"
        fromArchive = true
        btnNewFile_Clicked(self)
    }
    
    @IBAction func saveDocument(_ sender: AnyObject?) {
        btnSave_Clicked(self)
    }
    
    @IBAction func openiCloud(_ sender: AnyObject?) {
        directory = Directory(folderURL: URL(fileURLWithPath: fileManager.homeDirectoryForCurrentUser.path + "/Library/Mobile Documents/com~apple~CloudDocs"))
        reloadFileList(backorForward: false)
    }
    
    @IBAction func closeWindow(_ sender: AnyObject?) {
        if (windowShouldClose(self)) {
            self.view.window?.close()
        }
    }
    
    @IBAction func openBothLincolnFolder(_ sender: AnyObject?) { // Already Checked
        
        //do {
        
        let pathComponents: [String] = URL(fileURLWithPath: curPath).pathComponents
        var path1_Components: [String] = pathComponents // Folder path in desktop
        var path2_Components: [String] = pathComponents // Folder path in Google Drive
        var path1: String = "/"
        var path2: String = "/"
        
        if (pathComponents[3] == "Desktop") {
            path2_Components[3] = "Google 云端硬盘"
            path2_Components.remove(at: 4)
            path2_Components[4].removeSubrange(path2_Components[4].startIndex...pathComponents[4].index(path2_Components[4].startIndex, offsetBy: 7))
            path2_Components[4].remove(at: path2_Components[4].startIndex)
        } else {
            path1_Components[3] = "Desktop"
            path1_Components.insert("Lincoln", at: 4)
            path1_Components[5] = "Lincoln " + path1_Components[5]
        }
        
        for i in 1 ... path1_Components.count - 1 {
            path1.append(path1_Components[i])
            path1.append("/")
        }
        path1.remove(at: path1.index(path1.endIndex, offsetBy: -1))
        
        for i in 1 ... path2_Components.count - 1 {
            path2.append(path2_Components[i])
            path2.append("/")
        }
        path2.remove(at: path2.index(path2.endIndex, offsetBy: -1))
        
        print(path1)
        print(path2)
        
        NSWorkspace.shared().openFile(path1)
        NSWorkspace.shared().openFile(path2)
        
        /*
         ["/", "Users", "david", "Desktop", "Lincoln", "Lincoln And"]
         ["/", "Users", "david", "Google 云端硬盘", "And"]
        */
        
        //} catch { }
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
