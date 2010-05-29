// 
// AccountPreferences.m
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


#import "AccountPreferences.h"
#import "Foursquare.h"
#import "FoursquareXAppDelegate.h"

@interface FoursquareTester : Foursquare
@end

@implementation FoursquareTester
@end

@implementation AccountPreferences

- (BOOL)isResizable {
	return NO;
}

- (NSImage *)imageForPreferenceNamed:(NSString *) name {
	return [NSImage imageNamed:@"NSUser"];
}

- (void)willBeDisplayed 
{
}

- (IBAction)showSheet:(id)sender
{
	[emailField setStringValue:@""];
	[passwordField setStringValue:@""];
	
	[NSApp beginSheet:sheetWindow
	   modalForWindow:[_preferencesView window]
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:nil];
}

- (IBAction)hideSheet:(id)sender
{
	[sheetWindow orderOut:self];
	[NSApp endSheet:sheetWindow];
}

- (IBAction)updateAccount:(id)sender
{
	[sheetWindow makeFirstResponder:nil];
	
	[sender setEnabled:NO];
	[accountIndicator startAnimation:self];
	
	[FoursquareTester getOAuthAccessTokenForUsername:[emailField stringValue]
											password:[passwordField stringValue]
											callback:^(BOOL success, id response) 
	{
		[accountIndicator stopAnimation:self];
		
		if (success) {
			NSDictionary *dict = [response objectForKey:@"credentials"];
			
			NSString *token  = [dict objectForKey:@"oauth_token"];
			NSString *secret = [dict objectForKey:@"oauth_token_secret"];
			
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:token  forKey:@"access_token"];
			[defaults setObject:secret forKey:@"access_secret"];
			
			[Foursquare setOAuthAccessToken:token secret:secret];			
			
			[self hideSheet:self];
			
			FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
			[appDelegate refreshEverything:self];
		} else {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Login Failed"];
			[alert setAlertStyle:NSWarningAlertStyle];
			
			NSString *errorText = nil;
			if ([response isKindOfClass:[NSError class]]) {
				NSError *error = (NSError *)response;
				errorText = [error localizedDescription];			
				
				[alert setInformativeText:errorText];
			} 
			
			[alert beginSheetModalForWindow:sheetWindow
							  modalDelegate:nil 
							 didEndSelector:NULL
								contextInfo:nil];
		}
		
		[sender setEnabled:YES];
	}];
}


@end
