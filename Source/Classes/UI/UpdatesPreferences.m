// 
// UpdatesPreferences.m
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

#import "UpdatesPreferences.h"
#import <Sparkle/Sparkle.h>

@interface UpdatesPreferences (PrivateAPI)
- (void)refreshUpdateLabel;
@end

@implementation UpdatesPreferences

- (BOOL)isResizable {
	return NO;
}

- (NSImage *)imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"NSNetwork"];
}

- (void)willBeDisplayed
{
	[self refreshUpdateLabel];
}

- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast
{
	[self refreshUpdateLabel];
}

- (void)refreshUpdateLabel
{
	SUUpdater *updater = [SUUpdater sharedUpdater];
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	
	NSDate *lastCheck = [updater lastUpdateCheckDate];
	NSString *lastCheckString = lastCheck ? [formatter stringFromDate:lastCheck] : @"never";
	[lastUpdateCheckLabel setStringValue:[NSString stringWithFormat:@"Last check: %@", lastCheckString]];
}

@end
