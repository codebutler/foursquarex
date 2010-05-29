// 
// WelcomeWindowController.m
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

#import "WelcomeWindowController.h"
#import "Foursquare.h"
#import "FoursquareXAppDelegate.h"
#import "NSAlertAdditions.h"
#import <GoogleToolboxForMac/GTMNSDictionary+URLArguments.h>

@interface WelcomeWindowController(PrivateAPI)
- (void)alertDidEnd:(NSAlert *)alert 
		 returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo;
@end

@implementation WelcomeWindowController

- (void)awakeFromNib
{
	// Automatically migrate username/pass to OAuth when upgrading.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *email    = [defaults stringForKey:@"email"];
	NSString *password = [defaults stringForKey:@"password"];
	if ([email length] > 0 && [password length] > 0) {
		NSLog(@"Migrating preferences to OAuth...");
		
		[emailField setStringValue:email];
		[passwordField setStringValue:password];
		
		[self loginClicked:self];
	}
}

- (IBAction)loginClicked:(id)sender 
{
	// The text fields only save their value after losing focus.
	[[self window] makeFirstResponder:nil];
	
	// Set the UI to busy
	[emailField setEnabled:NO];
	[passwordField setEnabled:NO];
	[loginButton setEnabled:NO];
	[indicator startAnimation:self];
	
	// Perform authorization exchange to get access token.
	NSString *username = [emailField stringValue];
	NSString *password = [passwordField stringValue];
	[Foursquare getOAuthAccessTokenForUsername:username password:password callback:^(BOOL success, id result) {
		[indicator stopAnimation:self];
		
		if (success) {		
			NSDictionary *dict = [result objectForKey:@"credentials"];
			
			NSString *token  = [dict objectForKey:@"oauth_token"];
			NSString *secret = [dict objectForKey:@"oauth_token_secret"];
			
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:token  forKey:@"access_token"];
			[defaults setObject:secret forKey:@"access_secret"];
			
			[defaults removeObjectForKey:@"email"];
			[defaults removeObjectForKey:@"password"];
						
			[Foursquare setOAuthAccessToken:token secret:secret];
			
			[self close];
						
			FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
			[appDelegate finishLoading];

			return;
		}
		
		// Failed!
		NSAlert *alert = [NSAlert alertWithResponse:result];
		[alert beginSheetModalForWindow:[self window] 
						  modalDelegate:self 
						 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
							contextInfo:nil];
	}];
	
}

- (void)alertDidEnd:(NSAlert *)alert 
		 returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo 
{
	[emailField setEnabled:YES];
	[passwordField setEnabled:YES];
	[loginButton setEnabled:YES];
}

- (IBAction)quitClicked:(id)sender 
{
	[indicator stopAnimation:self];
	[NSApp terminate:self];
}

@end
