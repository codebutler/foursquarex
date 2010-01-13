// Based on code from http://lists.apple.com/archives/Cocoa-dev/2009/Jan/msg00366.html

#import "UnindentedOutlineView.h"

@implementation UnindentedOutlineView

// Changing the indentation of NSOutlineView causes the 0-level items
// to indent possibly large amounts as well, which looks bad.
// Similarly, if the indent is set to small values, disclosure triangles of
// top level items draw to far to the side and appear in the neighboring column.

#define kMaxFirstLevelIndentation 16
#define kMinFirstLevelIndentation 16

// corrects text and icons (if using ImageAndTextCell)
- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{	
	NSRect frame = [super frameOfCellAtColumn:column row:row];
	
	if ( column == 1 ) {
		
		CGFloat indent = [self indentationPerLevel];
		
		if ( indent > kMaxFirstLevelIndentation ) {
			frame.origin.x -= (indent - kMaxFirstLevelIndentation);
			frame.size.width += (indent - kMaxFirstLevelIndentation);
		}
		else if ( indent < kMinFirstLevelIndentation ) {
			frame.origin.x += (kMinFirstLevelIndentation - indent);
			frame.size.width -= (kMinFirstLevelIndentation - indent);
		}
		
	}
	return frame;
}

// corrects disclosure control icon
- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row;
{	
	NSRect frame = [super frameOfOutlineCellAtRow:row];
	
	CGFloat indent = [self indentationPerLevel];
	if ( indent > kMaxFirstLevelIndentation )
		frame.origin.x -= (indent - kMaxFirstLevelIndentation);
	else if ( indent < kMinFirstLevelIndentation )
		frame.origin.x += (kMinFirstLevelIndentation - indent);
	
	return frame;
}

@end
