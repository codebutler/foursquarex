// 
// NSDateAdditions.m
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


#import "NSDateAdditions.h"

@implementation NSDate (Additions)

- (NSString *)shortTimeAgoInWords
{
	NSTimeInterval interval = [self timeIntervalSinceNow];
	NSTimeInterval secondsAgo = fabs(interval);
	double minutesAgo = round(secondsAgo / 60.0);
	
	if (minutesAgo < 1)
		return @"just now";
	else if (minutesAgo < 60)
		return [NSString stringWithFormat:@"%.0f mins ago", minutesAgo];
	else if (minutesAgo < 1440)
		return [NSString stringWithFormat:@"%.0f hrs ago", round(minutesAgo / 60.0)];
	else {
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateStyle:NSDateFormatterShortStyle];
		return [formatter stringFromDate:self];	
	}
}

@end
