//
//  Document.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    let archivePagesKey = "documentPagesKey"
    let archiveBrushesKey = "documentBrushesKey"
    let archiveCurrentPageIndexKey = "canvasCurrentPageIndexKey"
    let archiveMagnificationKey = "scrollViewMagnificationKey"
    
    let defaultPageRect = NSMakeRect(0, 0, 100, 200)
    let defaultPageBackgroundColor = NSColor.whiteColor()
    
    weak var canvas: Canvas!
    var pages = [Page]()
    var brushes = [Brush.defaultPen]
    
    var fileUnarchiver: NSKeyedUnarchiver?

    override init() {
        super.init()
        pages.append(Page(pageRect: defaultPageRect, backgroundColor: defaultPageBackgroundColor))
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        if let canvasWindowController = aController as? CanvasWindowController {
            canvas = canvasWindowController.canvas
            canvas.document = self
            if let unarchiver = fileUnarchiver {
                fileUnarchiver = nil
                self.undoManager?.disableUndoRegistration()
                canvas.currentPageIndex = unarchiver.decodeIntegerForKey(archiveCurrentPageIndexKey)
                unarchiver.finishDecoding()
                self.undoManager?.enableUndoRegistration()
            } else {
                canvas.enclosingScrollView!.magnification = 1.4 // TODO
            }
            canvas.reload()
        }
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    func addLineOnPage(line line: Line, page: Page) {
        page.addLine(line)
        undoManager!.prepareWithInvocationTarget(self).deleteLineOnPage(line: line, page: page)
        undoManager!.setActionName(NSLocalizedString("Add Line", comment: "undo add line"))
        canvas.setNeedsDisplayInRect(line.bounds, onPage: pageIndex(page)!)
    }
    
    func deleteLineOnPage(line line: Line, page: Page) {
        page.deleteLine(line)
        undoManager!.prepareWithInvocationTarget(self).addLineOnPage(line: line, page: page)
        undoManager!.setActionName(NSLocalizedString("Delete Line", comment: "undo delete line"))
        canvas.setNeedsDisplayInRect(line.bounds, onPage: pageIndex(page)!)
    }
    
    func addPage(index index: Int) {
        let newPage = Page(pageRect: defaultPageRect, backgroundColor: defaultPageBackgroundColor)
        addPage(newPage, index: index)
    }
    
    func addPage(page: Page, index: Int) {
        pages.insert(page, atIndex: index)
        undoManager!.prepareWithInvocationTarget(self).deletePage(index: index)
        undoManager!.setActionName(NSLocalizedString("Add Page", comment: "undo add page"))
        canvas.goToPage(index)
        updateWindowTitle()
    }
    
    func deletePage(index index: Int) {
        let page = pages.removeAtIndex(index)
        undoManager!.prepareWithInvocationTarget(self).addPage(page, index: index)
        undoManager!.setActionName(NSLocalizedString("Delete Page", comment: "undo delete page"))
        if canvas.currentPageIndex >= pagesCount() {
            canvas.goToPage(pagesCount()-1)
        } else {
            canvas.reload()
        }
        updateWindowTitle()
    }

    override func makeWindowControllers() {
        addWindowController(CanvasWindowController(windowNibName: "Document"))
    }
    
    func updateWindowTitle() {
        for windowController in windowControllers {
            if let canvasWindowController = windowController as? CanvasWindowController {
                canvasWindowController.synchronizeWindowTitleWithDocumentName()
            }
        }
    }
    
    override func saveDocumentToPDF(sender: AnyObject?) {
        let pageIndexBackup = canvas.currentPageIndex
        var printInfoDict = [String:AnyObject]()
        printInfoDict[NSPrintPaperSize] = NSValue(size: canvas.frame.size)
        let savePanel = NSSavePanel()
        savePanel.title = "Export As PDF..."
        savePanel.allowedFileTypes = ["pdf"]
        savePanel.runModal()
        printInfoDict[NSPrintJobSavingURL] = savePanel.URL
        printInfoDict[NSPrintJobDisposition] = NSPrintSaveJob
        printInfoDict[NSPrintTopMargin] = 0.0
        printInfoDict[NSPrintBottomMargin] = 0.0
        printInfoDict[NSPrintLeftMargin] = 0.0
        printInfoDict[NSPrintRightMargin] = 0.0
        
        let printOp = NSPrintOperation(view: canvas, printInfo:
            NSPrintInfo(dictionary: printInfoDict))
        printOp.showsPrintPanel = false
        printOp.runOperation()
        canvas.currentPageIndex = pageIndexBackup
    }
    
    func pageIndex(page: Page) -> Int? {
        return pages.indexOf(page)
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
        archiver.encodeObject(brushes, forKey: archiveBrushesKey)
        archiver.finishEncoding()
        return data
    }

    // read native file format
    override func readFromData(data: NSData, ofType typeName: String) throws {
        self.undoManager?.disableUndoRegistration()
        fileUnarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        pages = fileUnarchiver?.decodeObjectForKey(archivePagesKey) as! [Page]
        brushes = fileUnarchiver?.decodeObjectForKey(archiveBrushesKey) as! [Brush]
        self.undoManager?.enableUndoRegistration()
    }
    
    func pagesCount() -> Int {
        return pages.count
    }
}

