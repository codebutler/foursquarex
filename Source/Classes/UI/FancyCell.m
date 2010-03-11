// 
// FancyCell.m
// FoursquareX
//
// Copyright (C) 2010 Eric Butler <eric@codebutler.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "FancyCell.h"
#import "NSDateAdditions.h"
#import "ListNode.h"

@interface FancyCell (PrivateAPI)
- (int)drawBadgeInRect:(NSRect)aRect;
@end

@implementation FancyCell

- (void)setObjectValue:(id <NSCopying>)object {
    id oldObjectValue = [self objectValue];
    if (object != oldObjectValue) {
        [(NSObject *)object retain];
        [oldObjectValue release];
        [super setObjectValue:[NSValue valueWithNonretainedObject:object]];
    }
}

- (id)objectValue {
	if ([[super objectValue] isKindOfClass:[NSValue class]])
		return [[super objectValue] nonretainedObjectValue];
	else
		return nil;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView 
{
	NSColor* primaryColor = [self isHighlighted] ? [NSColor alternateSelectedControlTextColor] : [NSColor textColor];
	NSColor* secondaryColor = [self isHighlighted] ? [NSColor alternateSelectedControlTextColor] : [NSColor disabledControlTextColor];

	ListNode *item = [self objectValue];
		
	//TODO: Selection with gradient and selection color in white with shadow
	// check out http://www.cocoadev.com/index.pl?NSTableView
	
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
	
	NSDictionary* primaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
										   primaryColor, NSForegroundColorAttributeName,
										   [NSFont systemFontOfSize:13], NSFontAttributeName,
										   paragraphStyle, NSParagraphStyleAttributeName,
										   nil];	
	int badgeWidth = ([item isVenue]) ? [self drawBadgeInRect:cellFrame] : 0;
		
	if ([item timeText]) {
		NSString *timeText = [item timeText];
		NSMutableParagraphStyle *rightStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[rightStyle setAlignment:NSRightTextAlignment];
		NSDictionary* timeTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
											secondaryColor, NSForegroundColorAttributeName,
											[NSFont systemFontOfSize:9], NSFontAttributeName,
											rightStyle, NSParagraphStyleAttributeName,
											nil];

		CGFloat timeWidth = [timeText sizeWithAttributes:timeTextAttributes].width;
			
		CGFloat x = cellFrame.origin.x + cellFrame.size.height + 10;
		CGFloat width = cellFrame.size.width - x - timeWidth - badgeWidth - 6;
		NSRect rect = NSMakeRect(x, cellFrame.origin.y, width - 6, cellFrame.size.height);
		[[item primaryText] drawWithRect:rect
								 options:NSStringDrawingUsesLineFragmentOrigin
							  attributes:primaryTextAttributes];

		rect = NSMakeRect(x + width, cellFrame.origin.y + 3, timeWidth, cellFrame.size.height);
		[timeText drawWithRect:rect
					   options:NSStringDrawingUsesLineFragmentOrigin
					attributes:timeTextAttributes];	
	} else {
		CGFloat x = cellFrame.origin.x + 5;
		if ([item isGroup]) x += 16;
		CGFloat width = cellFrame.size.width - x - badgeWidth - 6;
		NSRect rect = NSMakeRect(x, cellFrame.origin.y, width, cellFrame.size.height);
		if ([item isGroup]) {
			NSMutableDictionary *groupTextAttributes = [primaryTextAttributes mutableCopy];
			[groupTextAttributes setValue:secondaryColor forKey:NSForegroundColorAttributeName];
			NSShadow *textShadow = [NSShadow alloc];
			[textShadow setShadowOffset:NSMakeSize(0,-1)];
			[textShadow setShadowBlurRadius:1.0];
			[textShadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:1.0]];			
			[groupTextAttributes setValue:textShadow forKey:NSShadowAttributeName];
			[[item primaryText] drawWithRect:rect
									 options:NSStringDrawingUsesLineFragmentOrigin
								  attributes:groupTextAttributes];				
			
		} else {
			[[item primaryText] drawWithRect:rect
									 options:NSStringDrawingUsesLineFragmentOrigin
								  attributes:primaryTextAttributes];				
		}
	}

	if ([item secondaryText]) {
		NSDictionary* secondaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
												 secondaryColor, NSForegroundColorAttributeName,
												 [NSFont systemFontOfSize:10], NSFontAttributeName, 
												 paragraphStyle, NSParagraphStyleAttributeName,
												 nil];
		CGFloat x = [item image] ? cellFrame.origin.x + cellFrame.size.height + 10 : cellFrame.origin.x + 5;
		CGFloat y = cellFrame.origin.y + cellFrame.size.height / 2;
		CGFloat width = cellFrame.size.width - x - badgeWidth - 6;
		NSRect rect = NSMakeRect(x, y, width, cellFrame.size.height);
		
		[[item secondaryText] drawWithRect:rect
								   options:NSStringDrawingUsesLineFragmentOrigin
								attributes:secondaryTextAttributes];
	}
	
	if ([item image]) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		float yOffset = cellFrame.origin.y;
		if ([controlView isFlipped]) {
			NSAffineTransform* xform = [NSAffineTransform transform];
			[xform translateXBy:0.0 yBy: cellFrame.size.height];
			[xform scaleXBy:1.0 yBy:-1.0];
			[xform concat];		
			yOffset = 0-cellFrame.origin.y;
		}
	
		NSImageInterpolation interpolation = [[NSGraphicsContext currentContext] imageInterpolation];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];	
		
		[[item image] drawInRect:NSMakeRect(cellFrame.origin.x+5,yOffset+3,cellFrame.size.height-6, cellFrame.size.height-6)
						fromRect:NSMakeRect(0, 0, [[item image] size].width, [[item image] size].height)
					   operation:NSCompositeSourceOver
						fraction:1.0];
		
		[[NSGraphicsContext currentContext] setImageInterpolation: interpolation];
		[[NSGraphicsContext currentContext] restoreGraphicsState];	
	}
}

// Based on code from
// http://www.bdunagan.com/2008/09/03/cocoa-tutorial-source-list-badges/

// Initialize badge variables, based on Apple Mail.
static int BADGE_BUFFER_LEFT = 4;
static int BADGE_BUFFER_TOP = 3;
static int BADGE_BUFFER_LEFT_SMALL = 2;
static int BADGE_CIRCLE_BUFFER_RIGHT = 5;
static int BADGE_TEXT_HEIGHT = 14;
static int BADGE_X_RADIUS = 7;
static int BADGE_Y_RADIUS = 8;
static int BADGE_TEXT_SMALL = 20;

- (int)drawBadgeInRect:(NSRect)aRect
{		
	ListNode *item = [self objectValue];
	
	if (![item isVenue] || [[item hereNow] intValue] < 1)
		return 0;
	
    // Set up badge string and size.
    NSString *badge = [NSString stringWithFormat:@"%@", [item hereNow]];
    NSSize badgeNumSize = [badge sizeWithAttributes:nil];
	
    // Calculate the badge's coordinates.
    int badgeWidth = badgeNumSize.width + BADGE_BUFFER_LEFT * 2;
    if (badgeWidth < BADGE_TEXT_SMALL)
    {
        // The text is too short. Decrease the badge's size.
        badgeWidth = BADGE_TEXT_SMALL;
    }
    int badgeX = aRect.origin.x + aRect.size.width - BADGE_CIRCLE_BUFFER_RIGHT - badgeWidth;
	int badgeY = aRect.origin.y + (aRect.size.height / 2) - (BADGE_TEXT_HEIGHT / 2);
    int badgeNumX = badgeX + BADGE_BUFFER_LEFT;
    if (badgeWidth == BADGE_TEXT_SMALL)
    {
        badgeNumX += BADGE_BUFFER_LEFT_SMALL;
    }
    NSRect badgeRect = NSMakeRect(badgeX, badgeY, badgeWidth, BADGE_TEXT_HEIGHT);
	
    // Draw the badge and number.
    NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:BADGE_X_RADIUS yRadius:BADGE_Y_RADIUS];
    if ([[NSApp mainWindow] isVisible] && ![self isHighlighted])
    {
        // The row is not selected and the window is in focus.
		
        [[NSColor colorWithCalibratedRed:.53 green:.60 blue:.74 alpha:1.0] set];
        [badgePath fill];
        NSDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
        [dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
        [dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        [badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
    }
    else if ([[NSApp mainWindow] isVisible])
    {
        // The row is selected and the window is in focus.
        [[NSColor whiteColor] set];
        [badgePath fill];
        NSDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
        [dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
        [dict setValue:[NSColor alternateSelectedControlColor] forKey:NSForegroundColorAttributeName];
        [badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
    }
    else if (![[NSApp mainWindow] isVisible] && ![self isHighlighted])
    {
        // The row is not selected and the window is not in focus.
        [[NSColor disabledControlTextColor] set];
        [badgePath fill];
        NSDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
        [dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
        [dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        [badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
    }
    else
    {
        // The row is selected and the window is not in focus.
        [[NSColor whiteColor] set];
        [badgePath fill];
        NSDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:[NSFont boldSystemFontOfSize:11] forKey:NSFontAttributeName];
        [dict setValue:[NSNumber numberWithFloat:-.25] forKey:NSKernAttributeName];
        [dict setValue:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
        [badge drawAtPoint:NSMakePoint(badgeNumX,badgeY) withAttributes:dict];
    }
	
	return badgeWidth;
}



@end
