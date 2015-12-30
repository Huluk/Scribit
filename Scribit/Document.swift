//
//  Document.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    let archivePagesKey = "pagesKey"
    let archiveCurrentPageIndexKey = "currentPageIndexKey"
    
    @IBOutlet var canvas: Canvas!
    var pages = [Page]()
    var defaultPageRect = NSMakeRect(0, 0, 600, 400)
    var defaultPageBackgroundColor = NSColor.whiteColor()
    
    var fileUnarchiver: NSKeyedUnarchiver?

    override init() {
        super.init()
        canvas = Canvas(frame:defaultPageRect)
        canvas.document = self
        pages.append(Page(pageRect: defaultPageRect, backgroundColor: defaultPageBackgroundColor))
        pages[0].addLine()
        pages.append(Page(pageRect: defaultPageRect, backgroundColor: defaultPageBackgroundColor))
        pages[1].addLine()
        pages[1].addLine()
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        self.undoManager?.disableUndoRegistration()
        canvas.currentPageIndex = fileUnarchiver?.decodeIntegerForKey(archiveCurrentPageIndexKey) ?? 0
        fileUnarchiver?.finishDecoding()
        fileUnarchiver = nil
        makeScrollView()
        self.undoManager?.enableUndoRegistration()
        canvas.window?.makeFirstResponder(canvas)
        canvas.needsDisplay = true
    }
    
    func makeScrollView() {
        let scrollView = NSScrollView(frame: windowForSheet!.contentView!.frame)
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.ViewWidthSizable,.ViewHeightSizable]
        scrollView.documentView = canvas
        scrollView.backgroundColor = NSColor.grayColor()
        scrollView.drawsBackground = true
        scrollView.allowsMagnification = true
        windowForSheet!.contentView = scrollView
        windowForSheet!.makeKeyAndOrderFront(nil)
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    override func saveDocumentToPDF(sender: AnyObject?) {
        let pageIndexBackup = canvas.currentPageIndex
        var printInfoDict = [String:AnyObject]()
        printInfoDict[NSPrintPaperSize] = NSValue(size: defaultPageRect.size)
        let savePanel = NSSavePanel()
        savePanel.title = "Export As PDF..."
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.runModal()
        printInfoDict[NSPrintJobSavingURL] = savePanel.URL
        printInfoDict[NSPrintJobDisposition] = NSPrintSaveJob
        let printOp = NSPrintOperation(view: canvas, printInfo:
            NSPrintInfo(dictionary: printInfoDict))
        printOp.showsPrintPanel = false
        printOp.runOperation()
        canvas.currentPageIndex = pageIndexBackup
    }
    
    /*// print and pdf export
    override func printDocumentWithSettings(printSettings: [String : AnyObject], showPrintPanel: Bool, delegate: AnyObject?, didPrintSelector: Selector, contextInfo: UnsafeMutablePointer<Void>)
    {
        let pageIndexBackup = canvas.currentPageIndex
        /*var printInfoDict = getPrintInfoDict()
        printInfoDict[NSPrintPaperSize] = defaultPageRect.size as? AnyObject
        printInfoDict[NSPrintTopMargin] = 0.0
        printInfoDict[NSPrintBottomMargin] = 0.0
        printInfoDict[NSPrintLeftMargin] = 0.0
        printInfoDict[NSPrintRightMargin] = 0.0
        let printOp = NSPrintOperation(view:canvas)
        printOp.printInfo = NSPrintInfo(dictionary: printInfoDict)*/
        let printOp = NSPrintOperation(view:canvas)
        printOp.runOperation()
        canvas.currentPageIndex = pageIndexBackup
    }*/
    
    // fucking shit why does pageInfo.dictionary() return incompatible type?
    private func getPrintInfoDict() -> [String : AnyObject] {
        let objcDict = printInfo.dictionary()
        var swiftDict = [String:AnyObject]()
        for key : AnyObject in objcDict.allKeys {
            let stringKey = key as! String
            if let keyValue = objcDict.valueForKey(stringKey){
                swiftDict[stringKey] = keyValue
            }
        }
        return swiftDict
    }

    // write native file format
    override func dataOfType(typeName: String) throws -> NSData {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        archiver.encodeInteger(canvas.currentPageIndex, forKey: archiveCurrentPageIndexKey)
        archiver.encodeObject(pages, forKey: archivePagesKey)
        archiver.finishEncoding()
        return data
    }

    // read native file format
    override func readFromData(data: NSData, ofType typeName: String) throws {
        self.undoManager?.disableUndoRegistration()
        fileUnarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        pages = fileUnarchiver?.decodeObjectForKey(archivePagesKey) as! [Page]
        self.undoManager?.enableUndoRegistration()
    }
}

