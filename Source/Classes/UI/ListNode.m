// 
// ListNode.m
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

#import "ListNode.h"
#import "NSDate+RFC2822.h"
#import "Foursquare.h"
#import "NSDateAdditions.h"

@implementation ListNode

- (id)initWithGroupName:(NSString *)aGroupName {
	if (self = [super init]) {
		groupName = [aGroupName copy];
		children = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc {
	[avatar release];
	[venueDict release];
	[groupName release];
	[children release];
	[super dealloc];
}

- (id)initWithVenueDict:(NSDictionary *)aVenueDict {
	if (self = [super init]) {
		venueDict = [aVenueDict retain];
	}
	return self;
}

- (id)initWithCheckinDict:(NSDictionary *)aCheckinDict {
	if (self = [super init]) {
		checkinDict = [aCheckinDict retain];
	}
	return self;
}

- (BOOL)isGroup {
	return (children != nil);
}

- (BOOL)isVenue {
	return (venueDict != nil);
}

- (BOOL)isCheckin {
	return (checkinDict != nil);
}

- (BOOL)isLeaf {
	return ![self isGroup];
}

- (NSString *)primaryText {
	if ([self isVenue]) {
		return [venueDict objectForKey:@"name"]; 
	} else if ([self isCheckin]) {
		return [checkinDict objectForKey:@"display"];
	} else {
		return groupName;
	}
}

- (NSString *)secondaryText {
	if ([self isVenue]) {
		return [Foursquare fullAddressForVenue:venueDict];
	} else if ([self isCheckin]) {
		if ([[checkinDict objectForKey:@"shout"] length] > 0) {
			return [checkinDict objectForKey:@"shout"];
		} else {
			return [Foursquare fullAddressForVenue:[checkinDict objectForKey:@"venue"]];
		}
	}
	return nil;
}

- (NSString *)timeText {
	if ([self isCheckin]) {
		return [[NSDate dateFromRFC2822:[checkinDict objectForKey:@"created"]] shortTimeAgoInWords];
	}
	return nil;
}

- (NSImage *)image {
	if ([self isCheckin]) {
		if (avatar == nil)
			avatar = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[[checkinDict objectForKey:@"user"] objectForKey:@"photo"]]];
	}
	return avatar;
}

- (NSNumber *)checkinId {
	return [checkinDict objectForKey:@"id"];
}

- (NSNumber *)venueId {
	return [venueDict objectForKey:@"id"];
}

- (NSMutableArray *)children {
	return children;
}

@end
