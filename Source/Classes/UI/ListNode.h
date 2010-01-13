// 
// ListNode.h
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

#import <Cocoa/Cocoa.h>

@interface ListNode : NSObject
{	
	// For venues
	NSDictionary *venueDict;
	
	// For checkins
	NSDictionary *checkinDict;
	NSImage *avatar;
	
	// For groups
	NSString *groupName;
	NSMutableArray *children;
}

- (id)initWithGroupName:(NSString *)aGroupName;
- (id)initWithCheckinDict:(NSDictionary *)aCheckinDict;
- (id)initWithVenueDict:(NSDictionary *)aVenueDict;

- (BOOL)isGroup;
- (BOOL)isCheckin;
- (BOOL)isVenue;
- (BOOL)isLeaf;

- (NSString *)primaryText;
- (NSString *)secondaryText;
- (NSString *)timeText;
- (NSImage *)image;

- (NSNumber *)checkinId;
- (NSNumber *)venueId;

- (NSMutableArray *)children;

@end
