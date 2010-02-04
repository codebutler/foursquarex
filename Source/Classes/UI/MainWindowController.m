// 
// MainWindowController.m
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

#import <HTTPRiot/HTTPRiot.h>

#import "MainWindowController.h"
#import "NSArray-Blocks.h"
#import "NSDate+RFC2822.h"
#import "NSDataAdditions.h"
#import "NSImageAdditions.h"
#import "ListNode.h"
#import "Foursquare.h"
#import "FoursquareXAppDelegate.h"
#import "NSWindow-NoodleEffects.h"
#import "GHNSURL+Utils.h"

@interface MainWindowController (PrivateAPI)
- (void)callJSMapMethod:(NSString *)methodName withArguments:(NSArray *)args;
@end

@implementation MainWindowController

+ (void)initialize
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:@"YES" forKey:@"WebKitDeveloperExtras"];
}

- (id)initWithWindow:(NSWindow *)window
{
	if (self = [super initWithWindow:window]) {
	}
	return self;
}

- (void)awakeFromNib 
{   
	[[statusLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"map" ofType:@"html"];
	NSString *htmlString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	[[webView mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
}

- (IBAction)showShoutWindow:(id)sender
{
	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	[appDelegate showShoutWindow:shoutButton];
}

- (void)updaterStarted
{
	[indicator startAnimation:self];
	[statusLabel setStringValue:@""];
	[statusLabel setHidden:YES];
	[refreshButton setEnabled:NO];
}

- (void)updaterFinished
{	
	[indicator stopAnimation:self];
	[statusLabel setHidden:YES];	
	[refreshButton setEnabled:YES];
}

- (void)updaterFailedWithErrorText:(NSString *)errorText
{
	[indicator stopAnimation:self];
	[statusLabel setStringValue:errorText];
	[statusLabel setHidden:NO];
	[refreshButton setEnabled:YES];
}

- (void)updaterStatusTextChanged:(NSString *)statusText
{
	[statusLabel setStringValue:statusText];
	[statusLabel setHidden:NO];
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	[windowObject setValue:self forKey:@"MainWindowController"];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector 
{
	if (aSelector == @selector(highlightCheckinRow:))
		return NO;
	else if (aSelector == @selector(highlightVenueRow:))
		return NO;
	else if (aSelector == @selector(launchGoogleMap:))
		return NO;
	else if (aSelector == @selector(launchUrl:))
		return NO;
	else if (aSelector == @selector(showCheckinWindowForVenueId:venueName:))
		return NO;
	else if (aSelector == @selector(mapIsReady))
		return NO;
	return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(highlightCheckinRow:))
        return @"highlightCheckinRow";
	else if (sel == @selector(highlightVenueRow:))
		return @"highlightVenueRow";
	else if (sel == @selector(launchGoogleMap:))
		return @"launchGoogleMap";
	else if (sel == @selector(launchUrl:))
		return @"launchUrl";
	else if (sel == @selector(showCheckinWindowForVenueId:venueName:))
		return @"showCheckinWindow";
	else if (sel == @selector(mapIsReady))
		return @"mapIsReady";
    return nil;
}

#pragma mark Methods for JS

- (void)mapIsReady
{
	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	[appDelegate finishLoading];
	NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController]; 
	[userDefaultsController addObserver:self
							 forKeyPath:@"values.showOldCheckins"
								options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
								context:NULL];
	[userDefaultsController addObserver:self
							 forKeyPath:@"values.showOtherCities"
								options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
								context:NULL];
}

- (void)highlightCheckinRow:(NSNumber *)checkinId
{	
	if ([viewSwitcher selectedSegment] != 0) {
		[viewSwitcher setSelectedSegment:0];
		[self switchView:self];
	}
	
	if (checkinId != nil) {
		for (ListNode *group in checkins) {
			for (ListNode *node in [group children]) {
				NSLog(@"COMPARE %@ .. %@", [node checkinId], checkinId);
				if ([[node checkinId] isEqualToNumber:checkinId]) {
					int row = [checkinsOutlineView rowForItem:node];
					[checkinsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];			
					[checkinsOutlineView scrollRowToVisible:row];
					NSLog(@"highlight checkin %@", checkinId);
					return;
				}
			}
		}	
	}
	
	NSLog(@"Didn't find checkin %@", checkinId);
}

- (void)highlightVenueRow:(NSNumber *)venueId
{
	if ([viewSwitcher selectedSegment] != 1) {
		[viewSwitcher setSelectedSegment:1];
		[self switchView:self];
	}

	if (venueId != nil) {
		for (ListNode *group in venues) {
			for (ListNode *node in [group children]) {
				if ([[node venueId] isEqualToNumber:venueId]) {
					int row = [venuesOutlineView rowForItem:node];
					[venuesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
					[venuesOutlineView scrollRowToVisible:row];
					return;
				}
			}
		}	
	}
}

- (void)launchGoogleMap:(NSString *)address
{
	NSString *escapedAddress = [NSURL gh_encodeComponent:address];
	NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com?q=%@", escapedAddress];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (void)launchUrl:(NSString *)urlString
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}


- (void)showCheckinWindowForVenueId:(NSString *)venueId venueName:(NSString *)venueName
{	
	NSLog(@"ID: %@ Name: %@", venueId, venueName);
	
	CheckinWindowController *checkinWindowController = [((FoursquareXAppDelegate *)[NSApp delegate]) checkinWindowController];
	[checkinWindowController setVenueId:venueId venueName:venueName];
	[NSApp beginSheet:[checkinWindowController window]
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:nil];
}

#pragma mark Public methods

- (void)updateFriends:(NSArray *)friendCheckins
{	
	if (!friendCheckins) { 
		[statusLabel setStringValue:@"Error getting friends' checkins."];
		[statusLabel setHidden:NO];
		
		[checkins autorelease];
		checkins = nil;
		[checkinsOutlineView reloadData];
		[checkinsOutlineView expandItem:nil expandChildren:YES];
		
		return;
	}
	
	NSDate *threeHoursAgo = [[NSDate date] dateByAddingTimeInterval:-10800];
	
	// Resize all the avatars.
	// FIXME: Need a local cache of this.
	NSMutableArray *newFriendCheckins = [NSMutableArray arrayWithCapacity:[friendCheckins count]];
	for (NSDictionary *checkin in friendCheckins) {
		NSMutableDictionary *newCheckin = [NSMutableDictionary dictionaryWithDictionary:checkin];
		NSDate *created = [NSDate dateFromRFC2822:[checkin objectForKey:@"created"]];
		BOOL isCurrent = (BOOL) ([created laterDate:threeHoursAgo] == created);
		[newCheckin setObject:[NSNumber numberWithBool:isCurrent] forKey:@"isCurrent"];
		
		NSMutableDictionary *userDict = [NSMutableDictionary dictionaryWithDictionary:[checkin objectForKey:@"user"]];
 		
		NSString *photoUrl = [userDict objectForKey:@"photo"];
		NSImage *image = [[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:photoUrl]] autorelease];
		image = [image imageWithSize:NSMakeSize(36.0, 36.0)];
		NSString *b64String = [[NSString stringWithFormat:@"data:image/png;base64,%@", [[image TIFFRepresentation] base64Encoding]] autorelease];
		[userDict setObject:b64String forKey:@"photoData"];
		
		[newCheckin setObject:userDict forKey:@"user"];

		[newFriendCheckins addObject:newCheckin];		
	}
	
	NSString *json = [newFriendCheckins JSONRepresentation];
	[self callJSMapMethod:@"updateCheckins" withArguments:[NSArray arrayWithObject:json]];
	
	NSArray *sortedCheckins = [newFriendCheckins sort:^(id obj1, id obj2) {
		NSDate *date1 = [NSDate dateFromRFC2822:[obj1 objectForKey:@"created"]];
		NSDate *date2 = [NSDate dateFromRFC2822:[obj2 objectForKey:@"created"]];
		return [date2 compare:date1];
	}];
	
	NSMutableArray *groups = [NSMutableArray array];
	
	ListNode *recentGroupNode    = [[[ListNode alloc] initWithGroupName:@"Last 3 Hours"] autorelease];
	ListNode *todayGroupNode     = [[[ListNode alloc] initWithGroupName:@"Today"] autorelease];
	ListNode *yesterdayGroupNode = [[[ListNode alloc] initWithGroupName:@"Yesterday"] autorelease];
	ListNode *olderGroupNode     = [[[ListNode alloc] initWithGroupName:@"Older"] autorelease];
	
	ListNode *currentGroupNode = nil;
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	
	NSDateComponents *comps = [calendar components:unitFlags fromDate:[NSDate date]];
	NSDate *startOfToday = [calendar dateFromComponents:comps];
	
	NSDate *yesterdayDate = [[[NSDate alloc] initWithTimeInterval:86400 sinceDate:startOfToday] autorelease];
	comps = [calendar components:unitFlags fromDate:yesterdayDate];
	NSDate *startOfYesterday = [calendar dateFromComponents:comps];	
	
	for (NSDictionary *checkin in sortedCheckins) {
		ListNode *checkinNode = [[[ListNode alloc] initWithCheckinDict:checkin] autorelease];
		NSDate *created = [NSDate dateFromRFC2822:[checkin objectForKey:@"created"]];
		
		if ([created laterDate:threeHoursAgo] == created) {
			if (currentGroupNode != recentGroupNode) {
				[groups addObject:recentGroupNode];
				currentGroupNode = recentGroupNode; 
			}
		} else if ([created laterDate:startOfToday] == created) {
			if (currentGroupNode != todayGroupNode) {
				[groups addObject:todayGroupNode];
				currentGroupNode = todayGroupNode; 
			}
		} else if ([created laterDate:startOfYesterday] == created) {
			if (currentGroupNode != yesterdayGroupNode) {
				[groups addObject:yesterdayGroupNode];
				currentGroupNode = yesterdayGroupNode; 
			}			
		} else {
			if (currentGroupNode != olderGroupNode) {
				[groups addObject:olderGroupNode];
				currentGroupNode = olderGroupNode;
			}
		}
		[[currentGroupNode children] addObject:checkinNode];
	}
	
	[checkins autorelease];
	checkins = [groups retain];
	
	[checkinsOutlineView reloadData];
	[checkinsOutlineView expandItem:nil expandChildren:YES];
}

- (void)gotVenues:(NSDictionary *)venuesDict
{
	if (venuesDict != nil) {		
		NSMutableArray *newVenues = [NSMutableArray array];
		NSMutableArray *allVenues = [NSMutableArray array];
		
		for (NSDictionary *groupDict in [venuesDict objectForKey:@"groups"]) {
			ListNode *groupNode = [[[ListNode alloc] initWithGroupName:[groupDict objectForKey:@"type"]] autorelease];
			for (NSDictionary *venueDict in [groupDict objectForKey:@"venues"]) {
				ListNode *venueNode = [[[ListNode alloc] initWithVenueDict:venueDict] autorelease];
				[[groupNode children] addObject:venueNode];
				[allVenues addObject:venueDict];
			}	
			[newVenues addObject:groupNode];
		}
		
		NSString *json = [allVenues JSONRepresentation];
		[self callJSMapMethod:@"updateVenues" withArguments:[NSArray arrayWithObject:json]];
		
		[venues autorelease];
		venues = [newVenues retain];				  
	} else {
		[venues autorelease];
		venues = nil;
	}
	[venuesOutlineView reloadData];
	[venuesOutlineView expandItem:nil expandChildren:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"values.showOldCheckins"]) {
		BOOL showAll = [[NSUserDefaults standardUserDefaults] boolForKey:@"showOldCheckins"];
		[self callJSMapMethod:@"setShowAllCheckins" 
				withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:showAll]]];
    } else if ([keyPath isEqual:@"values.showOtherCities"]) {
		FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
		[appDelegate refreshEverything:self];
	}
}

#pragma mark IBActions

- (IBAction)searchActivated:(id)sender
{
	 NSString *query = [searchField stringValue];
	
	FoursquareXAppDelegate *appDelegate = (FoursquareXAppDelegate *)[NSApp delegate];
	CLLocation *lastKnownLocation = [appDelegate lastKnownLocation];
	
	if (!lastKnownLocation) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Cannot search"];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setInformativeText:@"Your location is unknown."];
		[alert beginSheetModalForWindow:[self window] 
						  modalDelegate:self 
						 didEndSelector:nil
							contextInfo:nil];
		return;
	}
	
	NSLog(@"Looking for nearby venues");
	[indicator startAnimation:self];
	[statusLabel setStringValue:@"Searching for venues..."];
	[statusLabel setHidden:NO];	
	[Foursquare venuesNearLatitude:lastKnownLocation.coordinate.latitude
						 longitude:lastKnownLocation.coordinate.longitude
						  matching:query
							 limit:nil 
						  callback:^(BOOL success, id result) {
							  if (success) {
								  [statusLabel setHidden:YES];
								  [indicator stopAnimation:self];								  
								  
								  [self gotVenues:result];
							  } else {
								  NSLog(@"Error searching for venues: %@", result);
								  [statusLabel setStringValue:@"Error searching for venues."];
								  [statusLabel setHidden:NO];
								  [indicator stopAnimation:self];
								  [self gotVenues:nil];
							  }
						  }];
}

- (IBAction)switchView:(id)sender
{
	NSString *viewName = [viewSwitcher selectedSegment] == 0 ? @"checkins" : @"venues";
	[self callJSMapMethod:@"switchView" withArguments:[NSArray arrayWithObject:viewName]];

	[tabView selectTabViewItemAtIndex:[viewSwitcher selectedSegment]];
}

#pragma mark NSOutlineView delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item 
{
	return [item isGroup];
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item 
{
	return [item isGroup] ? [outlineView rowHeight] : [outlineView rowHeight] * 2;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item 
{
	return [item isLeaf];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == checkinsOutlineView) {
		NSUInteger row = [[checkinsOutlineView selectedRowIndexes] firstIndex];
		ListNode *node = [checkinsOutlineView itemAtRow:row];
		id checkinId = [node checkinId];
		id arg = checkinId ? checkinId : [NSNull null];
		[self callJSMapMethod:@"selectCheckin"
				withArguments:[NSArray arrayWithObject:arg]];
	} else if ([notification object] == venuesOutlineView) {
		NSUInteger row = [[venuesOutlineView selectedRowIndexes] firstIndex];
		ListNode *node = [venuesOutlineView itemAtRow:row];
		id venueId = [node venueId];
		id arg = venueId ? venueId : [NSNull null];
		[self callJSMapMethod:@"selectVenue"
				withArguments:[NSArray arrayWithObject:arg]];
	}
}

#pragma mark NSOutlineView dataSource methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView
  numberOfChildrenOfItem:(id)item
{
	NSArray *contentArray = (outlineView == checkinsOutlineView) ? checkins : venues;
							 
	if (item == nil) {
		if (contentArray) {
			return [contentArray count];
		}
	} else {
		if ([item isGroup]) {
			return [[item children] count];
		}
	}
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	return [item isGroup];
}

- (id)               outlineView:(NSOutlineView *)outlineView 
       objectValueForTableColumn:(NSTableColumn *)tableColumn
						  byItem:(id)item
{
	return item;
}

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index
		   ofItem:(id)item
{
	NSArray *contentArray = (outlineView == checkinsOutlineView) ? checkins : venues;
	if (item == nil) {
		return [contentArray objectAtIndex:index];
	} else {
		return [[item children] objectAtIndex:index];
	}
}

#pragma mark PrivateAPI

- (void)callJSMapMethod:(NSString *)methodName withArguments:(NSArray *)args
{	
	id mapObject = [[webView windowScriptObject] valueForKey:@"FoursquareMap"];
	
	id ret = [mapObject callWebScriptMethod:methodName withArguments:args];
	
	if ([ret isKindOfClass:[WebUndefined class]])
		NSLog(@"FoursquareMap.%@ undefined", methodName);
	else if ([ret boolValue] != YES)
		NSLog(@"FoursquareMap.%@ failed", methodName);	
}

@end
