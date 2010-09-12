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
#import "NSAlertAdditions.h"

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

	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	[appDelegate changeUsername:[emailField stringValue]
					   password:[passwordField stringValue]
			   alertParentWindow:sheetWindow
				  alertDelegate:self
					   callback:^(BOOL success) {
						   [accountIndicator stopAnimation:self];
						   if (success) {
							   [self hideSheet:self];
							   [appDelegate refreshEverything:self];
						   }
						 }];
}

- (void)alertDidEnd:(NSAlert *)alert 
		 returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo 
{
	[changeButton setEnabled:YES];
}

@end
