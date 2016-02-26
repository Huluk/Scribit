//
//  AppDelegate.swift
//  Scribit
//
//  Created by Lars Hansen on 2015-12-29.
//  Copyright © 2015 Lars Hansen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let dataDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0]).URLByAppendingPathComponent("Scribit")
    var brushesPlist: NSURL { return dataDirectory.URLByAppendingPathComponent("Brushes.plist") }
    
    var defaultPageFormats = DefaultPageFormats()

    var brushes = [Brush.defaultPen, Brush.defaultHighlighter]
    var brushKeyMapping = ["1":0, "2":1]

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if (NSFileManager.defaultManager().isReadableFileAtPath(brushesPlist.path!)) {
            let savedData = NSData(contentsOfURL: brushesPlist)!
            brushes = NSKeyedUnarchiver.unarchiveObjectWithData(savedData) as! [Brush]
        } else if (!NSFileManager.defaultManager().fileExistsAtPath(dataDirectory.path!)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(dataDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                NSLog("could not create data directory!")
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        let data = NSKeyedArchiver.archivedDataWithRootObject(brushes)
        let flag = data.writeToURL(brushesPlist, atomically: true)
        
        return flag ? .TerminateNow : .TerminateCancel
    }
}

