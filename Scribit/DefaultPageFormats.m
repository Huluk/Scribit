//
//  DefaultPageFormats.m
//  Scribit
//
//  Created by Lars Hansen on 2016-02-24.
//  Copyright © 2016 Lars Hansen. All rights reserved.
//

#import "DefaultPageFormats.h"

@implementation DefaultPageFormats

@synthesize pageFormats;
@synthesize displayNames;

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
        NSMutableDictionary *_displayNames = [[NSMutableDictionary alloc]
                                              initWithCapacity:numPaperList];
        
        CFStringRef *paperName = malloc(sizeof(CFStringRef));
        for (long i=0; i<numPaperList; i++) {
            PMPaper paper = (PMPaper)CFArrayGetValueAtIndex(*paperList, i);
            PMPaperGetPPDPaperName(paper, paperName);
            NSString *internalName = (NSString *)CFBridgingRelease(*paperName);
            [_pageFormats addObject:internalName];
            PMPaperCreateLocalizedName(paper, *printer, paperName);
            [_displayNames setObject:(NSString *)CFBridgingRelease(*paperName)
                             forKey:internalName];
        }
        free(printer);
        free(paperList);
        free(paperName);
        
        pageFormats = [[NSArray alloc] initWithArray:_pageFormats];
        displayNames = [[NSDictionary alloc] initWithDictionary:_displayNames];
    }
    
    return self;
}

@end
