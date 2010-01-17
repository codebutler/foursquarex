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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[emailField setStringValue:[defaults objectForKey:@"email"]];
	[passwordField setStringValue:[defaults objectForKey:@"password"]];
}

- (IBAction)updateAccount:(id)sender
{
	NSWindow *window = [_preferencesView window];
	[window makeFirstResponder:nil];
	
	[sender setEnabled:NO];
	[accountIndicator startAnimation:self];
	
	[FoursquareTester setBasicAuthWithUsername:[emailField stringValue]
									  password:[passwordField stringValue]];
	[FoursquareTester test:^(BOOL success, id response) {
		if (success) {
			 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			 [defaults setObject:[emailField stringValue] forKey:@"email"];
			 [defaults setObject:[passwordField stringValue] forKey:@"password"];
			 [Foursquare setBasicAuthWithUsername:[emailField stringValue] password:[passwordField stringValue]];
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
			
			[alert beginSheetModalForWindow:window 
							  modalDelegate:nil 
							 didEndSelector:NULL
								contextInfo:nil];
		}
		[accountIndicator stopAnimation:self];
		[sender setEnabled:YES];
	}];
}


@end
