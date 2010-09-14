// 
// DockIcon.m
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

// Hide-dock-icon code based on code from the SSHKeyChain project
// Copyright (c) Bart Matthaei. All rights reserved.
// http://sshkeychain.sourceforge.net/

#import "DockIcon.h"
#include <utime.h>

@implementation DockIcon

+ (BOOL)hidden {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	NSURL *url = [NSURL fileURLWithPath: [NSString stringWithFormat: @"%@/Contents/Info.plist", appPath]];
	NSMutableDictionary *plist = [[[NSMutableDictionary alloc] initWithContentsOfFile:[url path]] autorelease];
	return [[plist objectForKey:@"LSUIElement"] boolValue] == YES;	
}

+ (BOOL)setHidden:(BOOL)hidden restart:(BOOL)restart {
	if (hidden != [self hidden]) {
		NSString *appPath = [[NSBundle mainBundle] bundlePath];
		NSURL *url = [NSURL fileURLWithPath: [NSString stringWithFormat: @"%@/Contents/Info.plist", appPath]];
		NSMutableDictionary *plist = [[[NSMutableDictionary alloc] initWithContentsOfFile:[url path]] autorelease];
		
		[plist setObject:[NSNumber numberWithBool:hidden] forKey:@"LSUIElement"];
		
		if ([plist writeToFile:[url path] atomically:YES]) {
			if (utime([[[NSBundle mainBundle] bundlePath] cStringUsingEncoding:NSUTF8StringEncoding], nil) != -1) {
				if (restart) {
					[self restartApp];
				}				
				return YES;
			}
		}		
	}
	return NO;
}

+ (void)restartApp
{
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *script = [NSString stringWithFormat:@"while [ `ps -p %d | wc -l` -gt 1 ]; do sleep 0.1; done; open '%@'", pid, bundlePath];
	[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", script, nil]];
	
	[NSApp terminate:nil];
	
	/*
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/open"];
	[task setArguments:[NSArray arrayWithObject:[self appPath]]];
	[task launch];
	exit(0);
	*/
}

@end


