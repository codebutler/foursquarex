// 
// NSAlertAdditions.m
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

#import "NSAlertAdditions.h"


@implementation NSAlert (NSAlertAdditions)
+ (NSAlert *)alertWithResponse:(id)response
{
	NSAlert *alert = nil;
	if ([response isKindOfClass:[NSError class]]) {
		alert = [NSAlert alertWithError:response];
	} else {
		NSString *infoText = nil;
		if ([response isKindOfClass:[NSDictionary class]] && [response objectForKey:@"error"]) {
			infoText = [response objectForKey:@"error"];
		}
		alert = [NSAlert alertWithMessageText:@"Sorry, an error occured."
								defaultButton:nil
							  alternateButton:nil
								  otherButton:nil
					informativeTextWithFormat:infoText];
	}
	return alert;
}
@end
