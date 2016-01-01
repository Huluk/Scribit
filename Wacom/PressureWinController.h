/*----------------------------------------------------------------------------

FILE NAME

PressureWinController.h - Header file for PressureWinController class.

COPYRIGHT

Copyright WACOM Technology, Inc. 2001.

All rights reserved.

----------------------------------------------------------------------------*/

#import <Cocoa/Cocoa.h>

@interface PressureWinController : NSObject
{
    IBOutlet id txtEventType;
    IBOutlet id txtDeviceID;
    
    IBOutlet id txtMouseX;
    IBOutlet id txtMouseY;
    
    IBOutlet id txtAbsoulteX;
    IBOutlet id txtAbsoulteY;
    
    IBOutlet id txtTiltX;
    IBOutlet id txtTiltY;
    
    IBOutlet id txtPressure;
    IBOutlet id txtRawTabletPressure;
    IBOutlet id txtScaledTabletPressure;
    
    IBOutlet id txtRotationDegrees;
    IBOutlet id txtRotationRadians;
    
    IBOutlet id clrForeColor;
    
    IBOutlet id wtvTabletDraw;
    
    IBOutlet id mnuLineSize;
    IBOutlet id mnuOpacity;
    
    IBOutlet id mnuCaptureMouseMoves;
}

- (IBAction) opacityMenuAction:(id)sender;
- (IBAction) lineSizeMenuAction:(id)sender;
- (IBAction) captureMouseMovesAction:(id)sender;
- (IBAction) openColorPanel:(id)sender;
- (void) changeColor:(id)sender;
- (void) wtvUpdatedStats:(NSNotification *)theNotification;
@end
