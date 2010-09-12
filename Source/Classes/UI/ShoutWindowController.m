// 
// ShoutWindowController.h
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

#import "ShoutWindowController.h"

#import "CustomTextFieldFormatter.h"
#import "NSAlertAdditions.h"
#import "Foursquare.h"
#import "FoursquareXAppDelegate.h"

@interface ShoutWindowController (PrivateAPI)
- (void)enableDisableCheckboxes;
@end

@implementation ShoutWindowController

- (void)awakeFromNib 
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textDidChange:)  
												 name:NSControlTextDidChangeNotification
											   object:textField];
	
	CustomTextFieldFormatter *formatter = [[CustomTextFieldFormatter new] autorelease];
	[formatter setMaximumLength:140];
	[textField setFormatter:formatter];
	
	[[[self window] standardWindowButton:NSWindowZoomButton] setEnabled:NO];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSControlTextDidChangeNotification 
												  object:textField];
	
	[super dealloc];
}

- (void)showWindow:(id)sender
{	
	[self enableDisableCheckboxes];	
	[super showWindow:self];
	[[self window] makeKeyAndOrderFront:self];
}

- (void)textDidChange:(NSNotification *)aNotification 
{
	NSUInteger textLen = [[textField stringValue] length];
	NSUInteger remaining = 140 - textLen;
	[numLabel setStringValue:[NSString stringWithFormat:@"%d", remaining]];
}

- (IBAction)shoutClicked:(id)sender 
{
	[shoutButton setEnabled:NO];
	[textField setEnabled:NO];
	[twitterCheck setEnabled:NO];
	[facebookCheck setEnabled:NO];
	[indicator startAnimation:self];
	
	NSString *shout = [textField stringValue];
	BOOL tellTwitter = [twitterCheck state] == NSOnState;
	BOOL tellFacebook = [facebookCheck state] == NSOnState;
	
	[Foursquare checkinAtVenueId:nil
					   venueName:nil
						   shout:shout
					 tellFriends:YES
					 tellTwitter:tellTwitter
					tellFacebook:tellFacebook
						latitude:nil
					   longitude:nil
						callback:^(id result, NSError *error) {
							[indicator stopAnimation:self];
							[shoutButton setEnabled:YES];
							[textField setEnabled:YES];
							[self enableDisableCheckboxes];
							
							if (!error) {								
								NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
								
								if ([twitterCheck isEnabled])
									[defaults setObject:[NSNumber numberWithBool:tellTwitter] forKey:@"tellTwitter"];
								
								if ([facebookCheck isEnabled])
									[defaults setObject:[NSNumber numberWithBool:tellFacebook] forKey:@"tellFacebook"];								
								
								[[self window] close];
								[textField setStringValue:@""];
							} else {
								NSAlert *alert = [NSAlert alertWithError:error result:result];
								[alert beginSheetModalForWindow:[self window] 
												  modalDelegate:nil
												 didEndSelector:nil 
													contextInfo:nil];
								
								[[self window] makeFirstResponder:textField];
							}
						}];
}

- (void)enableDisableCheckboxes
{
	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	[twitterCheck setEnabled:[appDelegate hasTwitter]];
	[facebookCheck setEnabled:[appDelegate hasFacebook]];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL tellTwitter  = [[defaults objectForKey:@"tellTwitter"] boolValue];
	BOOL tellFacebook = [[defaults objectForKey:@"tellFacebook"] boolValue];	
	
	if ([appDelegate hasTwitter])
		[twitterCheck setState:((tellTwitter) ? NSOnState : NSOffState)];
	else
		[twitterCheck setState:NSOffState];
	
	if ([appDelegate hasFacebook])
		[facebookCheck setState:((tellFacebook) ? NSOnState : NSOffState)];
	else
		[facebookCheck setState:NSOffState];	
}
@end
