// 
// AvatarManager.m
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

#import "AvatarManager.h"
#import "NSImageAdditions.h"
#import "FoursquareXAppDelegate.h"

@implementation AvatarManager

- (id)init
{
	if (self = [super init]) {
		workerThread = [[[NSThread alloc] initWithTarget:self selector:@selector(threadMain:) object:nil] retain];
		[workerThread start];
	}
	return self;
}
				  
- (void)threadMain:(id)data
{
	NSThread *thread = [NSThread currentThread];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
	while (![thread isCancelled])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[runLoop run];
		[pool release];
	}
}

- (NSString *)fetchAvatarReturningPath:(NSURL *)url
{
	[self performSelector:@selector(doFetchAvatar:) 
				 onThread:workerThread 
			   withObject:[url retain]
			waitUntilDone:NO];
	
	NSString *fileName        = [[[[url path] componentsSeparatedByString:@"/"] lastObject] stringByDeletingPathExtension];
	NSString *avatarDirectory = [@"~/Library/Application Support/FoursquareX/Avatars/" stringByExpandingTildeInPath];
	NSString *outputPath      = [avatarDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.png", fileName]];
	return outputPath;
}

- (void)doFetchAvatar:(NSURL *)url
{	
	[url autorelease];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	
	NSString *fileName        = [[[[url path] componentsSeparatedByString:@"/"] lastObject] stringByDeletingPathExtension];
	NSString *avatarDirectory = [@"~/Library/Application Support/FoursquareX/Avatars/" stringByExpandingTildeInPath];
	NSString *outputPath      = [avatarDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.png", fileName]];
	NSString *outputPathFresh = [avatarDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@-fresh.png", fileName]];
	NSString *outputPathOld   = [avatarDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@-old.png", fileName]];
	
	// Create destination directory if needed
	BOOL isDir;
	if (![manager fileExistsAtPath:avatarDirectory isDirectory:&isDir] || !isDir) {
		NSError *error = nil;
		[manager createDirectoryAtPath:avatarDirectory
		   withIntermediateDirectories:YES 
							attributes:NO 
								 error:&error];
		if (error) {
			NSLog(@"Failed to create avatar directory!");
			return;
		}
	}
	
	// Skip if already fetched
	if ([manager fileExistsAtPath:outputPath] && [manager fileExistsAtPath:outputPathOld]) {
		return;
	}
	
	// Grab the image
	NSImage *image = [[[NSImage alloc] initWithContentsOfURL:url] autorelease];

	// Resize and save
	NSImage *smallImage = [image imageWithSize:NSMakeSize(36.0, 36.0)];
	NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[smallImage TIFFRepresentation]];
	NSData *data = [rep representationUsingType:NSPNGFileType properties:nil];
	[data writeToFile:outputPath atomically:NO];	
	
	// Create and save the "fresh" version
	NSImage *placardImage = [NSImage imageNamed:@"placard_fresh.png"];
	[placardImage lockFocus];
	[image drawInRect:NSMakeRect(10.0, 15.0, 36.0, 36.0) 
			 fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
			operation:NSCompositeCopy 
			 fraction:1.0];
	[placardImage unlockFocus];
	rep = [NSBitmapImageRep imageRepWithData:[placardImage TIFFRepresentation]];
	data = [rep representationUsingType:NSPNGFileType properties:nil];
	[data writeToFile:outputPathFresh atomically:NO];

	// Create and save the "old" version
	placardImage = [NSImage imageNamed:@"placard_old.png"];
	[placardImage lockFocus];
	[image drawInRect:NSMakeRect(10.0, 15.0, 36.0, 36.0) 
			 fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
			operation:NSCompositeCopy 
			 fraction:1.0];
	[placardImage unlockFocus];
	rep = [NSBitmapImageRep imageRepWithData:[placardImage TIFFRepresentation]];
	data = [rep representationUsingType:NSPNGFileType properties:nil];
	[data writeToFile:outputPathOld atomically:NO];
	
	// Tell the world
	[self performSelectorOnMainThread:@selector(gotAvatar:) withObject:outputPath waitUntilDone:NO];
}
			  
- (void)gotAvatar:(NSString *)path
{
	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	[appDelegate gotAvatar:path];
}

@end
