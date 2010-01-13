// 
// GeneralPreferences.m
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

// Start-at-login code based on code by Justin Williams
// Copyright 2008 Second Gear LLC. All rights reserved.
// http://bitbucket.org/secondgear/shared-file-list-example/

// Hide-dock-icon code based on code from the SSHKeyChain project
// Copyright (c) Bart Matthaei. All rights reserved.
// http://sshkeychain.sourceforge.net/

#import <utime.h>
#import "GeneralPreferences.h"

@interface GeneralPreferences (PrivateAPI)
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath;
- (NSString *)appPath;
@end

@implementation GeneralPreferences

- (BOOL) isResizable {
	return NO;
}

- (NSImage *) imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSNumber *error = (NSNumber *)contextInfo;
	if (![error boolValue] && returnCode == 1) {
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:@"/usr/bin/open"];
		[task setArguments:[NSArray arrayWithObject:[self appPath]]];
		[task launch];
		exit(0);
	}
	[error release];
}

- (BOOL)startAtLogin {
	BOOL result = NO;
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	CFURLRef thePath = (CFURLRef)[NSURL fileURLWithPath:[self appPath]];
	
	UInt32 seedValue;
	
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
	for (id item in loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:[self appPath]]) {
				result = YES;
				break;
			}
		}
	}
	
	[loginItemsArray release];	
	
	CFRelease(loginItems);
	
	return result;
}

- (void)setStartAtLogin:(BOOL)shouldStartAtLogin {
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:[self appPath]];
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems) {
		if (shouldStartAtLogin)
			[self enableLoginItemWithLoginItemsReference:loginItems ForPath:url];
		else
			[self disableLoginItemWithLoginItemsReference:loginItems ForPath:url];
	}
	CFRelease(loginItems);
}

- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath 
{
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, thePath, NULL, NULL);		
	if (item)
		CFRelease(item);
}

- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs ForPath:(CFURLRef)thePath 
{
	UInt32 seedValue;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:[self appPath]])
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
		}
	}
	
	[loginItemsArray release];
}

- (BOOL)hideDockIcon {
	NSURL *url = [NSURL fileURLWithPath: [NSString stringWithFormat: @"%@/Contents/Info.plist", [self appPath]]];
	
	NSMutableDictionary *plist = [[[NSMutableDictionary alloc] initWithContentsOfFile:[url path]] autorelease];
	return [[plist objectForKey:@"LSUIElement"] boolValue] == YES;
}

- (void)setHideDockIcon:(BOOL)shouldHideDockIcon {	
	BOOL error = NO;
	
	NSURL *url = [NSURL fileURLWithPath: [NSString stringWithFormat: @"%@/Contents/Info.plist", [self appPath]]];
	
	NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:[url path]];
	[plist setObject:[NSNumber numberWithBool:shouldHideDockIcon] forKey:@"LSUIElement"];
	if (![plist writeToFile:[url path] atomically:YES]) {
		error = YES;
	}
	[plist release];
	
	if (utime([[[NSBundle mainBundle] bundlePath] cStringUsingEncoding:NSUTF8StringEncoding], nil) == -1) {
		error = YES;
	}	
	
	NSAlert *alert = nil;
	
	if (!error) {
		alert = [NSAlert alertWithMessageText:@"Do you want to restart FoursquareX now?"
								defaultButton:@"Yes"
							  alternateButton:@"No"
								  otherButton:nil
					informativeTextWithFormat:@"Otherwise, this change will take effect the next time you launch FoursquareX."];
	} else {	
		alert = [NSAlert alertWithMessageText:@"Failed to set option"
								defaultButton:nil
							  alternateButton:nil
								  otherButton:nil
					informativeTextWithFormat:@"Make sure your user has write-access to the FoursquareX executable."];
		[alert setAlertStyle:NSCriticalAlertStyle];
	}
	
	NSWindow *window = [_preferencesView window];
	[alert beginSheetModalForWindow:window
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:[[NSNumber numberWithBool:error] retain]];
}


- (NSString *)appPath {
	return [[NSBundle mainBundle] bundlePath];
}

@end
