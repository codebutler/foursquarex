// 
// MainWindowController.h
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
#import <WebKit/WebKit.h>
#import <WebKit/WebView.h>

#import "AvatarManager.h"

@interface MainWindowController : NSWindowController {
	IBOutlet WebView *webView;
	IBOutlet NSProgressIndicator *indicator;
	IBOutlet NSTextField *statusLabel;
	IBOutlet NSOutlineView *checkinsOutlineView;
	IBOutlet NSOutlineView *venuesOutlineView;
	IBOutlet NSSegmentedControl *viewSwitcher;
	IBOutlet NSTabView *tabView;
	IBOutlet NSButton *shoutButton;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSButton *refreshButton;
	
	IBOutlet AvatarManager *avatarManager;
	
	NSArray *checkins;
	NSArray *venues;
	
	BOOL supressSelectionChanges;
}

- (IBAction)showShoutWindow:(id)sender;
- (IBAction)switchView:(id)sender;
- (IBAction)searchActivated:(id)sender;
- (IBAction)selectFriends:(id)sender;
- (IBAction)selectVenues:(id)sender;

- (void)gotVenues:(NSDictionary *)venuesDict;
- (void)updateFriends:(NSArray *)friendCheckins;

- (void)highlightCheckinRow:(NSNumber *)checkinId;
- (void)highlightVenueRow:(NSNumber *)venueId;

- (void)updaterStarted;
- (void)updaterFinished;
- (void)updaterStatusTextChanged:(NSString *)statusText;
- (void)updaterFailedWithErrorText:(NSString *)errorText;

- (void)gotAvatar:(NSString *)path;
@end
