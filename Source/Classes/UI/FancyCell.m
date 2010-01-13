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
	
	if ([item timeText]) {
		CGFloat timeWidth = 55;
			
		CGFloat x = cellFrame.origin.x + cellFrame.size.height + 10;
		CGFloat width = cellFrame.size.width - x - timeWidth;
		NSRect rect = NSMakeRect(x, cellFrame.origin.y, width - 6, cellFrame.size.height);
		[[item primaryText] drawWithRect:rect
								 options:NSStringDrawingUsesLineFragmentOrigin
							  attributes:primaryTextAttributes];

		NSString *timeText = [item timeText];
		NSDictionary* timeTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
											secondaryColor, NSForegroundColorAttributeName,
											[NSFont systemFontOfSize:9], NSFontAttributeName,
											nil];
		rect = NSMakeRect(x + width, cellFrame.origin.y + 3, timeWidth, cellFrame.size.height);
		[timeText drawWithRect:rect
					   options:NSStringDrawingUsesLineFragmentOrigin
					attributes:timeTextAttributes];	
	} else {
		CGFloat x = cellFrame.origin.x + 5;
		if ([item isGroup]) x += 16;
		CGFloat width = cellFrame.size.width - x;
		NSRect rect = NSMakeRect(x, cellFrame.origin.y, width - 6, cellFrame.size.height);
		[[item primaryText] drawWithRect:rect
								 options:NSStringDrawingUsesLineFragmentOrigin
							  attributes:primaryTextAttributes];		
	}

	if ([item secondaryText]) {
		NSDictionary* secondaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
												 secondaryColor, NSForegroundColorAttributeName,
												 [NSFont systemFontOfSize:10], NSFontAttributeName, 
												 paragraphStyle, NSParagraphStyleAttributeName,
												 nil];
		CGFloat x = [item image] ? cellFrame.origin.x + cellFrame.size.height + 10 : cellFrame.origin.x + 5;
		CGFloat y = cellFrame.origin.y + cellFrame.size.height / 2;
		NSRect rect = NSMakeRect(x, y, cellFrame.size.width - x, cellFrame.size.height);
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

@end
