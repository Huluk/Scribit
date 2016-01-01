/*----------------------------------------------------------------------------

FILE NAME

PressureWinController.m - Implementation file for PressureWinController class.

COPYRIGHT

Copyright WACOM Technology, Inc. 2001.

All rights reserved.

----------------------------------------------------------------------------*/

#import "PressureWinController.h"
#import "WTView.h"

@implementation PressureWinController
///////////////////////////////////////////////////////////////////////////
- (id) init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        
        // Must want to know when WTCView's data has been updated
        [[NSNotificationCenter defaultCenter] addObserver:self
               selector:@selector(wtvUpdatedStats:)
               name:WTViewUpdatedNotification
               object:wtvTabletDraw];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////
- (void) awakeFromNib
{
   [wtvTabletDraw setForeColor:[clrForeColor color]];
   
   // Set check marks of Pressure Menu Items
   if([wtvTabletDraw mAdjustOpacity])
   {
      [mnuOpacity setState:NSOnState];
   }
   else
   {
      [mnuOpacity setState:NSOffState];
   }
   
   if([wtvTabletDraw mAdjustSize])
   {
      [mnuOpacity setState:NSOnState];
   }
   else
   {
      [mnuLineSize setState:NSOffState];
   }
   
   // Set check marks for Events menu
   if([wtvTabletDraw mCaptureMouseMoves])
   {
      [mnuCaptureMouseMoves setState:NSOnState];
   }
   else
   {
      [mnuCaptureMouseMoves setState:NSOffState];
   }
}



///////////////////////////////////////////////////////////////////////////
- (IBAction) opacityMenuAction:(id)sender
{
   if([sender state] == NSOnState)
   {
      [sender setState:NSOffState];
      [wtvTabletDraw setAdjustOpacity:NO];
   }
   else
   {
      [sender setState:NSOnState];
      [wtvTabletDraw setAdjustOpacity:YES];
   }
}



///////////////////////////////////////////////////////////////////////////
- (IBAction) lineSizeMenuAction:(id)sender
{
   if([sender state] == NSOnState)
   {
      [sender setState:NSOffState];
      [wtvTabletDraw setAdjustSize:NO];
   }
   else
   {
      [sender setState:NSOnState];
      [wtvTabletDraw setAdjustSize:YES];
   }
}



///////////////////////////////////////////////////////////////////////////
- (IBAction) captureMouseMovesAction:(id)sender
{
   if([sender state] == NSOnState)
   {
      [sender setState:NSOffState];
      [wtvTabletDraw setCaptureMouseMoves:NO];
   }
   else
   {
      [sender setState:NSOnState];
      [wtvTabletDraw setCaptureMouseMoves:YES];
   }
}



///////////////////////////////////////////////////////////////////////////
- (IBAction) openColorPanel:(id)sender
{
   [sender activate:NO];
}



///////////////////////////////////////////////////////////////////////////
- (IBAction) changeColor:(id)sender
{
   [wtvTabletDraw setForeColor: [sender color]];
}



///////////////////////////////////////////////////////////////////////////
-(void) wtvUpdatedStats:(NSNotification *)theNotification
{
   switch([wtvTabletDraw mEventType])
   {
      case NSLeftMouseDown:
      case NSRightMouseDown:
         [txtEventType setStringValue:@"Mouse Down"];
      break;
      
      case NSLeftMouseUp:
      case NSRightMouseUp:
         [txtEventType setStringValue:@"Mouse Up"];
      break;
      
      case NSLeftMouseDragged:
      case NSRightMouseDragged:
         [txtEventType setStringValue:@"Mouse Drag"];
      break;
      
      case NSMouseMoved:
         [txtEventType setStringValue:@"Mouse Move"];
      break;
   }
   
   [txtDeviceID setIntValue:[wtvTabletDraw mDeviceID]];
   [txtMouseX setFloatValue:[wtvTabletDraw mMouseX]];
   [txtMouseY setFloatValue:[wtvTabletDraw mMouseY]];
   [txtPressure setFloatValue:[wtvTabletDraw mPressure]];
   [txtRawTabletPressure setFloatValue:[wtvTabletDraw mTabletRawPressure]];
   [txtScaledTabletPressure setFloatValue:[wtvTabletDraw mTabletScaledPressure]];
   [txtAbsoulteX setIntValue:[wtvTabletDraw mAbsX]];
   [txtAbsoulteY setIntValue:[wtvTabletDraw mAbsY]];
   [txtTiltX setFloatValue:[wtvTabletDraw mTiltX]];
   [txtTiltY setFloatValue:[wtvTabletDraw mTiltY]];
   [txtRotationDegrees setFloatValue:[wtvTabletDraw mRotDeg]];
   [txtRotationRadians setFloatValue:[wtvTabletDraw mRotRad]];
   
   [clrForeColor setColor:[wtvTabletDraw mForeColor]];
}
@end
