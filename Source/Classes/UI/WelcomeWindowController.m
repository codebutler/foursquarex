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

@interface WelcomeWindowController(PrivateAPI)
- (void)alertDidEnd:(NSAlert *)alert 
		 returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo;
@end

@implementation WelcomeWindowController

- (IBAction)loginClicked:(id)sender {
	// The text fields only save their value after losing focus.
	[[self window] makeFirstResponder:nil];
	
	// Set the UI to busy
	[emailField setEnabled:NO];
	[passwordField setEnabled:NO];
	[loginButton setEnabled:NO];
	[indicator startAnimation:self];
	
	// Try out the credentials
	
	[Foursquare setBasicAuthWithUsername:[emailField stringValue] 
								password:[passwordField stringValue]];
	
	[Foursquare test:^(BOOL success, id result) {
		[indicator stopAnimation:self];
		
		if (success) {
			NSString *response = [result objectForKey:@"response"];
			if ([response isEqualToString:@"ok"]) {
				
				// The login worked! Save settings and finish loading app.
				
				[self close];
				
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[defaults setObject:[emailField stringValue] forKey:@"email"];
				[defaults setObject:[passwordField stringValue] forKey:@"password"];
				
				FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
				[appDelegate finishLoading];
								
				return;
			}	
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
		contextInfo:(void *)contextInfo {
	[emailField setEnabled:YES];
	[passwordField setEnabled:YES];
	[loginButton setEnabled:YES];
}

- (IBAction)quitClicked:(id)sender {
	[indicator stopAnimation:self];
	[NSApp terminate:self];
}

@end
