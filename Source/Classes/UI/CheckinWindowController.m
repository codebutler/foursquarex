// 
// CheckinWindowController.m
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

#import "CheckinWindowController.h"
#import "Foursquare.h"
#import "FoursquareXAppDelegate.h"
#import "NSAlertAdditions.h"

@interface CheckinWindowController (PrivateAPI)
- (void)clearVenue;
- (void)updateCheckboxes;
@end

@implementation CheckinWindowController

- (void)awakeFromNib 
{
	[super awakeFromNib];
	[[[self window] standardWindowButton:NSWindowZoomButton] setEnabled:NO];
}

- (void)dealloc
{
	[venueId release];
	
	[super dealloc];
}

- (IBAction)closeWindow:(id)sender
{
	if ([[self window] isSheet]) {
		[[self window] orderOut:self];
		[NSApp endSheet:[self window]];
	} else {
		[[self window] close];
	}
}

- (IBAction)checkinClicked:(id)sender
{
	[progressIndicator startAnimation:self];
	
	BOOL tellFriends = [friendsCheck state] == NSOnState;
	BOOL tellTwitter = [twitterCheck state] == NSOnState;
	BOOL tellFacebook = [facebookCheck state] == NSOnState;
	
	NSString *shout = [shoutField stringValue];
	if ([shout isEqualToString:@""])
		shout = nil;
	
	NSString *venueName = (venueId == nil) ? [venueField stringValue] : nil;
	
	[Foursquare checkinAtVenueId:venueId
					   venueName:venueName
						   shout:shout
					 tellFriends:tellFriends
					 tellTwitter:tellTwitter
					tellFacebook:tellFacebook 
						latitude:nil
					   longitude:nil
						callback:^(id result, NSError *error) {
							[progressIndicator stopAnimation:self];
							if (!error) {
								[[self window] close];
								FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
								[appDelegate refreshEverything:self];
								
								NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
								
								if ([twitterCheck isEnabled])
									[defaults setObject:[NSNumber numberWithBool:tellTwitter] forKey:@"tellTwitter"];
								
								if ([facebookCheck isEnabled])
									[defaults setObject:[NSNumber numberWithBool:tellFacebook] forKey:@"tellFacebook"];
								
								[defaults setObject:[NSNumber numberWithBool:tellFriends] forKey:@"tellFriends"];
								
							} else {
								NSAlert *alert = [NSAlert alertWithError:error result:result];
								[alert beginSheetModalForWindow:[self window] 
												  modalDelegate:nil
												 didEndSelector:nil 
													contextInfo:nil];				
							}
						}];
}

- (IBAction)showWindow:(id)sender
{
	[self showWindow:sender withVenue:nil];
}

- (IBAction)showWindow:(id)sender withVenue:(NSDictionary *)venueDict
{
	[self closeWindow:self];

	if (venueDict) {
		[self setVenueId:[[venueDict objectForKey:@"id"] stringValue]
			   venueName:[venueDict objectForKey:@"name"]];
	} else {
		[self clearVenue];
	}
	
	[super showWindow:sender];

	[NSApp activateIgnoringOtherApps:YES];
	[[self window] makeKeyAndOrderFront:self];	
}

- (void)setVenueId:(NSString *)aVenueId venueName:(NSString *)venueName
{
	[self closeWindow:self];
	
	[venueField setStringValue:venueName];
	[venueField setEnabled:NO];	
	
	[venueId release];
	venueId = [aVenueId retain];	

	[self updateCheckboxes];
}

- (void)clearVenue
{
	[venueId release];
	venueId = nil;
	
	[venueField setStringValue:@""];	
	[venueField setEnabled:YES];
	
	[self updateCheckboxes];
}


- (void)updateCheckboxes
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL tellFriends  = [[defaults objectForKey:@"tellFriends"] boolValue];
	BOOL tellTwitter  = [[defaults objectForKey:@"tellTwitter"] boolValue];
	BOOL tellFacebook = [[defaults objectForKey:@"tellFacebook"] boolValue];
	
	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	[twitterCheck setEnabled:[appDelegate hasTwitter]];
	[facebookCheck setEnabled:[appDelegate hasFacebook]];
	
	if ([appDelegate hasTwitter])
		[twitterCheck setState:((tellTwitter) ? NSOnState : NSOffState)];
	else
		[twitterCheck setState:NSOffState];
	
	if ([appDelegate hasFacebook])
		[facebookCheck setState:((tellFacebook) ? NSOnState : NSOffState)];
	else
		[facebookCheck setState:NSOffState];
	
	[friendsCheck setState:((tellFriends) ? NSOnState : NSOffState)];
}

@end