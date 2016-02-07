//
//  CanvasWindowController.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-02-07.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

class CanvasWindowController: NSWindowController {
    @IBOutlet var canvas: Canvas!
    @IBOutlet var pageSelectionPanel: NSPanel!
    @IBOutlet var pageSelection: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        canvas.document = document as! Document
        document?.windowControllerDidLoadNib(self)
    }

    override func windowTitleForDocumentDisplayName(displayName: String) -> String {
        if let doc = document as? Document {
            let numFormatter = NSNumberFormatter()
            let pageIndex = canvas != nil ? canvas!.currentPageIndex + 1 : 1
            let pageInfo = String.localizedStringWithFormat(
                NSLocalizedString("page x of y", comment:"window title (page $1 of $2)"),
                numFormatter.stringFromNumber(pageIndex)!,
                numFormatter.stringFromNumber(doc.pagesCount())!)
            return doc.displayName + " " + pageInfo
        } else {
            return super.windowTitleForDocumentDisplayName(displayName)
        }
    }
    
    override func keyDown(event: NSEvent) {
        switch event.keyCode {
        case 123: canvas.goToPage(canvas.currentPageIndex - 1) // left arrow
        case 124: canvas.goToPage(canvas.currentPageIndex + 1) // right arrow
        default: break
        }
    }

    @IBAction func showPageSelectionPanel(sender: AnyObject) {
        window!.beginSheet(pageSelectionPanel, completionHandler: nil)
        if pageSelection.stringValue == "" {
            pageSelection.takeIntegerValueFrom(1)
        }
    }
    
    @IBAction func closePageSelectionPanel(sender: AnyObject) {
        window!.endSheet(pageSelectionPanel)
        pageSelectionPanel.orderOut(sender)
    }
    
    @IBAction func goToPage(sender: AnyObject) {
        let pageNumber = pageSelection.integerValue
        closePageSelectionPanel(sender)
        if !canvas.goToPage(pageNumber-1) {
            NSBeep()
        }
    }
    
    @IBAction func appendPage(sender: AnyObject) {
        let doc = document as! Document
        doc.addPage(index: doc.pagesCount())
    }
    
    @IBAction func insertPage(sender: AnyObject) {
        let doc = document as! Document
        doc.addPage(index: canvas.currentPageIndex+1)
    }
    
    @IBAction func deletePage(sender: AnyObject) {
        let doc = document as! Document
        if doc.pagesCount() > 0 {
            doc.deletePage(index: canvas.currentPageIndex)
        }
    }
}
