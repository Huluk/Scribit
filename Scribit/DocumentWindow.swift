//
//  DocumentWindow.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-02-07.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class DocumentWindow: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override func synchronizeWindowTitleWithDocumentName() {
        let doc = document as! Document
        let pageInfo = String(
            format: NSLocalizedString("page x of y", comment:"window title (page $1 of $2)"),
            doc.canvas!.currentPageIndex, doc.pages.count)
        let title = doc.displayName + pageInfo
        windowTitleForDocumentDisplayName(title)
    }

}
