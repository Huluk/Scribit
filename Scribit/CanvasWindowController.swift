//
//  CanvasWindowController.swift
//  Scribit
//
//  Created by Lars Hansen on 2016-02-07.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

import Cocoa

enum CursorMode {
    case Draw, Selected, Dragging, RectSelect
}

class CanvasWindowController: NSWindowController {
    let DPI = 72
    let CM_PER_INCH = 2.54
    let PORTRAIT = 0
    unowned let appDelegate = NSApp.delegate as! AppDelegate
    
    @IBOutlet var canvas: Canvas!
    
    @IBOutlet var pageSelectionPanel: NSPanel!
    @IBOutlet var pageSelection: NSTextField!
    
    var selectionView: SelectionView?
    
    var pageFormats : [String : NSSize]?
    @IBOutlet var pageFormatPanel: NSPanel!
    @IBOutlet var pageFormatPicker: NSPopUpButton!
    @IBOutlet var pageWidth: NSTextField!
    @IBOutlet var pageHeight: NSTextField!
    @IBOutlet var pageResolution: NSTextField!
    @IBOutlet var pageOrientationPicker: NSPopUpButton!
    
    var cursorMode: CursorMode = .Draw
    
    override func windowDidLoad() {
        super.windowDidLoad()
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
        if let chars = event.charactersIgnoringModifiers {
            if let brushKey = appDelegate.brushKeyMapping[chars] {
                canvas.currentBrushIndex = brushKey
                return
            }
        }
        interpretKeyEvents([event])
        // call list: http://www.hcs.harvard.edu/~jrus/Site/System%20Bindings.html
    }
    
    override func moveLeft(sender: AnyObject?) {
        canvas.goToPage(canvas.currentPageIndex - 1)
    }
    
    override func moveRight(sender: AnyObject?) {
        canvas.goToPage(canvas.currentPageIndex + 1)
    }
    
    override func deleteBackward(sender: AnyObject?) {
        // TODO canvas.deleteSelection()
    }
    
    override func deleteForward(sender: AnyObject?) {
        // TODO canvas.deleteSelection()
    }
    
    @IBAction func makeRectangleSelection(sender: AnyObject?) {
        selectionView = SelectionView(frame: canvas.bounds)
        cursorMode = .RectSelect
        canvas.addSubview(selectionView!)
        window!.invalidateCursorRectsForView(canvas) // change cursor
    }
    
    func showPageFormatPicker() {
        let defaultPageFormats = appDelegate.defaultPageFormats
        let displayNames = defaultPageFormats.displayNames as! [String]
        //let sizes = defaultPageFormats.sizes.map({($0 as! NSValue).sizeValue})
        pageFormats = Dictionary<String,NSSize>()
        for (index, elem) in defaultPageFormats.sizes.enumerate() {
            pageFormats![displayNames[index]] = (elem as! NSValue).sizeValue
        }

        window!.beginSheet(pageFormatPanel, completionHandler: nil)
        pageFormatPicker.removeAllItems()
        pageFormatPicker.addItemsWithTitles(displayNames)
        pageOrientationPicker.removeAllItems()
        pageOrientationPicker.addItemsWithTitles([
            NSLocalizedString("Portrait", comment: "horizontal paper orientation"),
            NSLocalizedString("Landscape", comment: "vertical paper orientation")])
        pageResolution.takeIntegerValueFrom(DPI) // TODO make changeable
        
        if let defaultFormat = NSPrintInfo.sharedPrintInfo().paperName {
            let identifiers = defaultPageFormats.identifiers as! [String]
            if let index = identifiers.indexOf(defaultFormat) {
                pageFormatPicker.selectItemAtIndex(index)
            }
        }
        formatPickerAction(self)
    }
    
    @IBAction func formatPickerAction(sender: AnyObject) {
        let pageSize = pageSizeWithOrientation()
        pageWidth.takeFloatValueFrom(Double(pageSize.width) / Double(DPI) * CM_PER_INCH)
        pageHeight.takeFloatValueFrom(Double(pageSize.height) / Double(DPI) * CM_PER_INCH)
    }
    
    func pageSizeWithOrientation() -> NSSize {
        if let selection = pageFormatPicker.selectedItem {
            let pageSize = pageFormats![selection.title]!
            let shortedge = min(pageSize.width, pageSize.height)
            let longedge = max(pageSize.width, pageSize.height)
            let orientation = pageOrientationPicker.indexOfSelectedItem
            if orientation == PORTRAIT {
                return NSSize(width: shortedge, height: longedge)
            } else {
                return NSSize(width: longedge, height: shortedge)
            }
        }
        return NSSize()
    }
    
    @IBAction func closePageFormatPicker(sender: AnyObject) {
        window!.endSheet(pageFormatPanel)
        pageFormatPanel.orderOut(sender)
        if (self != sender as! NSObject) {
            (document as! Document).close()
        }
    }
    
    @IBAction func pickPageFormat(sender: AnyObject) {
        let pageSize = pageSizeWithOrientation()
        if pageSize.width * pageSize.height > 0 {
            (document as! Document).setInitialPageFormat(size: pageSize)
            closePageFormatPicker(self)
        } else {
            NSBeep()
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
        closePageSelectionPanel(self)
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
