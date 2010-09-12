// 
// CheckinWindowController.h
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

@interface CheckinWindowController : NSWindowController <NSOutlineViewDelegate> {
	IBOutlet NSButton *friendsCheck;
	IBOutlet NSButton *twitterCheck;
	IBOutlet NSButton *facebookCheck;
	IBOutlet NSTextField *venueField;
	IBOutlet NSTextField *shoutField;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSButton *okButton;
	
	NSString *venueId;
 }

- (IBAction)showWindow:(id)sender withVenue:(NSDictionary *)venueDict;
- (IBAction)closeWindow:(id)sender;
- (IBAction)checkinClicked:(id)sender;
- (void)setVenueId:(NSString *)aVenueId venueName:(NSString *)venueName;
@end
