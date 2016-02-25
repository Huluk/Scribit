//
//  DefaultPageFormats.m
//  Scribit
//
//  Created by Lars Hansen on 2016-02-24.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

#import "DefaultPageFormats.h"

@implementation DefaultPageFormats

@synthesize gddNames;
@synthesize identifiers;
@synthesize displayNames;
@synthesize sizes;

-(DefaultPageFormats *) init
{
    if(self = [super init])
    {
        PMPrinter *printer = malloc(sizeof(PMPrinter));
        OSStatus printerStatus = PMCreateGenericPrinter(printer);
        if (printerStatus != 0) {
            NSLog(@"Could not retrieve page formats: error in PMCreateGenericPrinter %d",
                  (int)printerStatus);
        }
        CFArrayRef *paperList = malloc(sizeof(CFArrayRef));
        PMPrinterGetPaperList(*printer, paperList);
        long numPaperList = CFArrayGetCount(*paperList);
        
        NSMutableArray *_pageFormats = [[NSMutableArray alloc] initWithCapacity:numPaperList];
        NSMutableArray *_displayNames = [[NSMutableArray alloc] initWithCapacity:numPaperList];
        NSMutableArray *_identifiers = [[NSMutableArray alloc] initWithCapacity:numPaperList];
        NSMutableArray *_sizes = [[NSMutableArray alloc] initWithCapacity:numPaperList];
        
        CFStringRef *paperName = malloc(sizeof(CFStringRef));
        NSPrinter *defaultPrinter = [[NSPrintInfo sharedPrintInfo] printer];
        for (long i=0; i<numPaperList; i++) {
            PMPaper paper = (PMPaper)CFArrayGetValueAtIndex(*paperList, i);
            PMPaperGetPPDPaperName(paper, paperName);
            NSString *internalName = (NSString *)CFBridgingRelease(*paperName);
            [_pageFormats addObject:internalName];
            PMPaperGetID(paper, paperName);
            [_identifiers addObject:(NSString *)CFBridgingRelease(*paperName)];
            PMPaperCreateLocalizedName(paper, *printer, paperName);
            [_displayNames addObject:(NSString *)CFBridgingRelease(*paperName)];
            [_sizes addObject:[NSValue valueWithSize:[defaultPrinter pageSizeForPaper:internalName]]];
        }
        free(printer);
        free(paperList);
        free(paperName);
        
        gddNames = [[NSArray alloc] initWithArray:_pageFormats];
        displayNames = [[NSArray alloc] initWithArray:_displayNames];
        identifiers = [[NSArray alloc] initWithArray:_identifiers];
        sizes = [[NSArray alloc] initWithArray:_sizes];
    }
    
    return self;
}

@end
