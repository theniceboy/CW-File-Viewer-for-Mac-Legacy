//
//  archiveorg.swift
//  CW File Viewer for Mac
//
//  Created by David Chen on 8/6/17.
//  Copyright © 2017 David Chen. All rights reserved.
//

import Foundation

func getArchiveTXTTitle (link: String) -> String {
    let html = Just.get(link).text
    do {
        let doc: Document = try SwiftSoup.parse(html!)
        let title = try doc.select("h1").first()?.text()
        return title!
    } catch {
        return ""
    }
}

func getArchiveTXT (link: String) -> String {
    do {
        var txtlinkcomponents = link.components(separatedBy: "/")
        if (txtlinkcomponents.last == "") {
            _ = txtlinkcomponents.popLast()
        }
        txtlinkcomponents.append(txtlinkcomponents.last! + "_djvu.txt")
        var txtlink = ""
        for component in txtlinkcomponents {
            if (component == "details") {
                txtlink = txtlink + "stream/"
            } else {
                txtlink = txtlink + component + "/"
            }
        }
        txtlink.remove(at: txtlink.index(before: txtlink.endIndex))
        let txthtml = Just.get(txtlink).text
        let txtdoc: Document = try SwiftSoup.parse(txthtml!)
       // print(txthtml)
        let txtcontent = try txtdoc.select("pre").first()?.text()
        return txtcontent!
    } catch {
        return ""
    }
}
