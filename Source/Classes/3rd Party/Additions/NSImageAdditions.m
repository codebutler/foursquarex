// http://www.cocoadev.com/index.pl?ThumbnailImages

#import "NSImageAdditions.h"

@implementation NSImage (NSImageAdditions)
- (NSImage *)imageWithSize:(NSSize)newSize
{
	NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
	NSRect oldRect = NSMakeRect(0.0, 0.0, [self size].width, [self size].height);
	NSRect newRect = NSMakeRect(0.0, 0.0, newSize.width, newSize.height);
	
	[newImage lockFocus];
	[self drawInRect:newRect fromRect:oldRect operation:NSCompositeCopy fraction:1.0];
	[newImage unlockFocus];
	return [newImage autorelease];
}

@end
