// 
// FoursquareXAppDelegate.m
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

#import "FoursquareXAppDelegate.h"
#import "Foursquare.h"
#import "FoursquareUpdater.h"

#import "NSData_HexAdditions.h"
#import "NSDate+RFC2822.h"
#import "NSWindow-NoodleEffects.h"
#import "NSArray-Blocks.h"

@interface FoursquareXAppDelegate (PrivateAPI)
- (void)getCheckinsAtVenue:(NSNumber *)venueId;
- (void)showCheckinGrowl:(NSDictionary *)checkin isFriend:(BOOL)isFriend;
- (void)suggestCheckins;
- (IBAction)updateLocation;
@end

@implementation FoursquareXAppDelegate

+ (void)initialize
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool:YES],
						  @"showNotifications",
						  [NSNumber numberWithBool:YES],
						  @"showReminders",
						  [NSNumber numberWithBool:NO],
						  @"showStrangers",
						  nil];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:dict];
}

- (id)init 
{
	if (self = [super init]) {
		loadFinished = NO;
		
		lastFriendUpdate = [[NSDate date] retain];
		
		[GrowlApplicationBridge setGrowlDelegate:self];
		
		NSArray *regExes = [NSArray arrayWithObject:@"State:/Network/Interface/.*/AirPort"];
		systemConfigNotificationManager = [IXSCNotificationManager new];
        [systemConfigNotificationManager setObservedKeys:nil regExes:regExes];
		
		quickCheckinMenuItems = [[NSMutableArray alloc] init];
		
		hasTwitter = YES;
		hasFacebook = YES;
	}
	return self;
}

- (void)dealloc
{
	[statusItem release];
	[quickCheckinMenuItems release];
	[systemConfigNotificationManager release];
	[lastFriendUpdate release];
	[lastVenueUpdate release];
	[lastSuggestion release];
	[myUserId release];
	[currentCheckin release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Searching for nearby venues..."
												   action:NULL
											keyEquivalent:@""] autorelease];
	[[quickCheckinMenuItem submenu] insertItem:item atIndex:2];
	[quickCheckinMenuItems addObject:item];
	
	[statusItemMenu setAutoenablesItems:NO];
}

- (CLLocation *)lastKnownLocation {
	return [updater lastKnownLocation];
}

#pragma mark NSApplicationDelegate methods

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	PFMoveToApplicationsFolderIfNecessary();
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *email = [defaults stringForKey:@"email"];
	NSString *password = [defaults stringForKey:@"password"];
	
	// FIXME: Validate email / password
	BOOL accountConfigured = (email && password);
	if (!accountConfigured) {
		firstRun = YES;
		[welcomeWindowController showWindow:self];
	} else {	
		firstRun = NO;
		[Foursquare setBasicAuthWithUsername:email password:password];
	}
}

#pragma mark NSNotificationCenter callbacks

- (void)airportChanged:(NSNotification *)notification 
{
	NSDictionary *dict = [notification userInfo];
	
	NSString *ssid  = [dict objectForKey:@"SSID_STR"];
	NSData   *bssid = [dict objectForKey:@"BSSID"];
	
	NSLog(@"Airport Changed! %@ (%@)", ssid, [bssid stringWithHexBytes]);
	
	// We may have just woken up from sleep, so update checkin.
	[timer fire];
}

#pragma mark IBActions

- (IBAction)refreshEverything:(id)sender
{
	[updater refreshEverything:sender];
}

- (IBAction)showMainWindow:(id)sender 
{
	[NSApp activateIgnoringOtherApps:YES];
	[mainWindowController showWindow:self];
	[[mainWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)showQuickCheckinWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[checkinWindowController showWindow:self];
	[[checkinWindowController window] makeKeyAndOrderFront:self];	
}

- (IBAction)showShoutWindow:(id)sender 
{
	if ([sender isKindOfClass:[NSButton class]]) {
		NSRect buttonFrame = [sender frame];
		NSRect windowFrame = [[sender window] frame];
		NSRect rect = NSMakeRect(buttonFrame.origin.x + windowFrame.origin.x, 
								 buttonFrame.origin.y + windowFrame.origin.y, 
								 buttonFrame.size.width,
								 buttonFrame.size.height);
		[[shoutWindowController window] zoomOnFromRect:rect];
	} else {
		[NSApp activateIgnoringOtherApps:YES];
		[shoutWindowController showWindow:self];
	}
	
	[[shoutWindowController window] makeKeyAndOrderFront:self];
}

- (IBAction)showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	
	[NSPreferences setDefaultPreferencesClass: [AppPreferences class]];
	[[NSPreferences sharedPreferences] showPreferencesPanel];
}

- (IBAction)showAddFriends:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://foursquare.com/import/"]];
}

- (IBAction)showManageFriends:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://foursquare.com/manage_friends"]];
}

- (IBAction)showAddVenue:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://foursquare.com/add_venue"]];
}

#pragma mark GrowlApplicationBridgeDelegate methods 

- (void)growlNotificationWasClicked:(id)clickContext 
{
	NSURL *url = [NSURL URLWithString:clickContext];
	
	NSLog(@"Ow! %@ - %@", [url scheme], [url resourceSpecifier]);
	
	if ([[url scheme] isEqualToString:@"friend"]) {
		[NSApp activateIgnoringOtherApps:YES];
		[mainWindowController showWindow:self];
		[[mainWindowController window] makeKeyAndOrderFront:self];
		[mainWindowController highlightCheckinRow:[NSNumber numberWithDouble:[[url resourceSpecifier] doubleValue]]];
	} else if ([[url scheme] isEqualToString:@"venue"]) {
		[NSApp activateIgnoringOtherApps:YES];
		[mainWindowController showWindow:self];
		[[mainWindowController window] makeKeyAndOrderFront:self];
		[mainWindowController highlightVenueRow:[NSNumber numberWithDouble:[[url resourceSpecifier] doubleValue]]];
	} else if ([[url scheme] isEqualToString:@"reminder"]) {
		[NSApp activateIgnoringOtherApps:YES];
		[mainWindowController showWindow:self];
		[[mainWindowController window] makeKeyAndOrderFront:self];
		[mainWindowController highlightVenueRow:nil];
	}
}

#pragma mark FoursquareUpdaterDelegate methods

- (void)foursquareUpdaterStartedUpdating:(FoursquareUpdater *)updater
{	
	[quickCheckinMenuItem setEnabled:NO];
	[shoutMenuItem setEnabled:NO];
	[locationMenuItem setTitle:@"Updating..."];	
	[mainWindowController updaterStarted];
}

- (void)foursquareUpdaterFinishedUpdating:(FoursquareUpdater *)updater
{
	[quickCheckinMenuItem setEnabled:YES];
	[shoutMenuItem setEnabled:YES];	
	[mainWindowController updaterFinished];
}

- (void)foursquareUpdater:(FoursquareUpdater *)updater
			gotOwnProfile:(NSDictionary *)user
				  isValid:(BOOL)isValid
{	
	NSDictionary *checkin = [user objectForKey:@"checkin"];
	
	// If we've moved to a new venue, update lastVenueUpdate to avoid
	// a flood notifications for other people who checked in at the same 
	// venue before you.
	if (![[currentCheckin objectForKey:@"id"] isEqualTo:[checkin objectForKey:@"id"]]) {
		[lastVenueUpdate autorelease];
		lastVenueUpdate = [[NSDate date] retain];
	}
	
	hasTwitter  = ([user objectForKey:@"twitter"] != nil);
	hasFacebook = ([user objectForKey:@"facebook"] != nil);
	
	NSNumber *userId = [user objectForKey:@"id"];
	
	[myUserId autorelease];
	myUserId = [userId retain];
	
	if (isValid) {
		[currentCheckin autorelease];
		currentCheckin = [checkin copy];
		
		NSDictionary *venue = [checkin objectForKey:@"venue"];
		NSString *venueName = [venue objectForKey:@"name"];		
		
		[locationMenuItem setTitle: [NSString stringWithFormat:@"You're checked in at: %@", venueName]];
	} else {
		[currentCheckin autorelease];
		currentCheckin = nil;
		
		[locationMenuItem setTitle: @"You're not checked in anywhere."];
	}
}

- (void)foursquareUpdater:(FoursquareUpdater *)updater 
		gotFriendCheckins:(NSArray *)checkins
{
	// Update the main window
	[mainWindowController updateFriends:checkins];
	
	// Show any growl notifications
	for (NSDictionary *checkin in checkins) {
		NSDate *created = [NSDate dateFromRFC2822:[checkin objectForKey:@"created"]];
		NSNumber *friendId = [[checkin objectForKey:@"user"] objectForKey:@"id"];
		if (![friendId isEqualTo:myUserId]) {
			if ([lastFriendUpdate laterDate:created] == created) {
				[self showCheckinGrowl:checkin isFriend:YES];
			}
		}
	}
	[lastFriendUpdate release];
	lastFriendUpdate = [[NSDate date] retain];
}

- (void)foursquareUpdater:(FoursquareUpdater *)updater gotVenueDetails:(NSDictionary *)venue
{
	NSNumber *venueId = [venue objectForKey:@"id"];
	if ([[[currentCheckin objectForKey:@"venue"] objectForKey:@"id"] isEqualToNumber:venueId]) {
		NSArray *checkins = [venue objectForKey:@"checkins"];
		for (NSDictionary *checkin in checkins) {
			NSDate *created = [NSDate dateFromRFC2822:[checkin objectForKey:@"created"]];
			if (!lastVenueUpdate || [lastVenueUpdate laterDate:created] == created) {
				// Create a new dictionary that looks like the checkin objects returned by
				// the friends API call. Yay for consistency...
				NSMutableDictionary *completeCheckin = [[[NSMutableDictionary alloc] initWithDictionary:checkin] autorelease];
				NSDictionary *venueDict = [[[NSDictionary alloc] initWithObjectsAndKeys:
											[venue objectForKey:@"name"],
											@"name",
											[venue objectForKey:@"id"],
											@"id",
											[venue objectForKey:@"address"],
											@"address",
											[venue objectForKey:@"crossstreet"],
											@"crossstreet",
											nil]
										   autorelease];
				[completeCheckin setObject:venueDict forKey:@"venue"];
				[self showCheckinGrowl:completeCheckin isFriend:NO];
			}
		}	
		[lastVenueUpdate autorelease];
		lastVenueUpdate = [[NSDate date] retain];
	} else {
		NSLog(@"No longer at venue");
	}
}

- (void)foursquareUpdater:(FoursquareUpdater *)updater 
		  gotNearbyVenues:(NSDictionary *)venuesDict
			   atLocation:(CLLocation *)newLocation
			  oldLocation:(CLLocation *)oldLocation
{
	NSMenu *menu = [quickCheckinMenuItem submenu];
	
	if ([quickCheckinMenuItems count] > 0) {
		for (NSMenuItem *item in quickCheckinMenuItems) {
			[menu removeItem:item];
		}								  
		[quickCheckinMenuItems removeAllObjects];		  
	}
	
	NSLog(@"Got nearby venues");
	
	NSArray *groups = [venuesDict objectForKey:@"groups"];
	
	if ([venuesDict count] > 0) {
		for (NSDictionary *groupDict in groups) {
			for (NSDictionary *venueDict in [groupDict objectForKey:@"venues"]) {
				int idx = [quickCheckinMenuItems count] + 2;
				NSString *venueName = [[[venueDict objectForKey:@"name"] copy] autorelease];
				NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:venueName 
															   action:@selector(quickCheckinAction:) 
														keyEquivalent:@""] autorelease];
				[item setRepresentedObject:venueDict];
				[menu insertItem:item atIndex:idx];
				[quickCheckinMenuItems addObject:item];
			}
		}
	} else {
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"No nearby venues found"
													   action:NULL
												keyEquivalent:@""] autorelease];
		[menu insertItem:item atIndex:2];
		[quickCheckinMenuItems addObject:item];
	}
	
	[mainWindowController gotVenues:venuesDict];
	
	if (oldLocation && [newLocation distanceFromLocation:oldLocation] > 10.0) {
		NSLog(@"Reset lastSuggestion... %f", [newLocation distanceFromLocation:oldLocation]);
		[lastSuggestion autorelease];
		lastSuggestion = nil;
	}
	
	NSDate *twentyFourHoursAgo = [[NSDate date] dateByAddingTimeInterval:-86400];
	if (!lastSuggestion || ([lastSuggestion laterDate:twentyFourHoursAgo] == twentyFourHoursAgo)) {
		NSDictionary *favoritesGroup = [groups find:^(id obj, NSUInteger idx) {
			return [[obj objectForKey:@"type"] isEqualToString:@"My Favorites"];
		}];
		if (favoritesGroup) {									  
			int count = [[favoritesGroup objectForKey:@"venues"] count];
			if (count > 0) {
				[self suggestCheckins];
				
				[lastSuggestion autorelease];
				lastSuggestion = [[NSDate date] retain];
			}
		}	
	}
}

- (void)foursquareUpdater:(FoursquareUpdater *)updater statusChanged:(NSString *)statusText
{
	NSLog(@"%@", statusText);
	[mainWindowController updaterStatusTextChanged:statusText];
}

- (void)foursquareUpdater:(FoursquareUpdater *)updater 
	   failedWithResponse:(id)response
			whileUpdating:(NSString *)task
{
	// Always clear out the menu on error so it doesn't get stuck saying "Searching..."
	NSMenu *menu = [quickCheckinMenuItem submenu];		
	if ([quickCheckinMenuItems count] > 0) {
		for (NSMenuItem *item in quickCheckinMenuItems) {
			[menu removeItem:item];
		}
		[quickCheckinMenuItems removeAllObjects];
	}
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:@"Error finding nearby venues"
												   action:NULL
											keyEquivalent:@""] autorelease];
	[menu insertItem:item atIndex:2];
	[quickCheckinMenuItems addObject:item];		
	
	[locationMenuItem setTitle:@"[Error fetching current checkin]"];
	
	
	NSString *errorText = @"An error occurred";	
	if ([task isEqualToString:@"currentCheckin"]) {
		errorText = @"Failed to get current venue";
	} else if ([task isEqualToString:@"friendCheckins"]) {
		errorText = @"Failed to get friend checkins";
		[mainWindowController updateFriends:nil];
	} else if ([task isEqualToString:@"venueCheckins"]) {
		errorText = @"Failed to get venue details";
	} else if ([task isEqualToString:@"location"]) {	
		errorText = @"Failed to find your location";
	} else if ([task isEqualToString:@"nearbyVenues"]) {
		errorText = @"Error getting nearby venues";
		[mainWindowController gotVenues:nil];
	}
	
	if ([response isKindOfClass:[NSError class]]) 
		errorText = [NSString stringWithFormat:@"%@: %@", errorText, [response localizedDescription]];
	else if ([response isKindOfClass:[NSDictionary class]] && [response objectForKey:@"error"])
		errorText = [NSString stringWithFormat:@"%@: %@", errorText, [response objectForKey:@"error"]];
	else
		errorText = [NSString stringWithFormat:@"%@.", errorText];
	
	NSLog(@"%@", errorText);
	
	[quickCheckinMenuItem setEnabled:YES];
	[shoutMenuItem setEnabled:YES];	
	
	[mainWindowController updaterFailedWithErrorText:errorText];
}

#pragma mark Private methods

- (void)finishLoading
{
	if (loadFinished)
		return;
	
	loadFinished = YES;
	
	NSLog(@"Finishing the load...");
	
	// Show icon	
	NSImage *image =[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"menu_icon" ofType:@"png"]] autorelease];
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	statusItem = [[statusBar statusItemWithLength:-2] retain];
	[statusItem setMenu:statusItemMenu];
	[statusItem setHighlightMode:YES];
	[statusItem setImage:image];
	
	// Listen for WiFi events
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self
			   selector:@selector(airportChanged:) 
				   name:@"State:/Network/Interface/en1/AirPort"	
				 object:systemConfigNotificationManager];
	
	// Start update timer
	timer = [NSTimer scheduledTimerWithTimeInterval:300 
											 target:self 
										   selector:@selector(timerElapsed) 
										   userInfo:nil 
											repeats:YES];

	// But don't wait for it!
	[timer fire];
	
	if (firstRun) {
		[mainWindowController showWindow:self];
	}
}

- (void)timerElapsed 
{	
	[self refreshEverything:self];
}

/* FIXME
- (void)updateLocation
{
	[locationManager stopUpdatingLocation];
	[locationManager startUpdatingLocation];
}
*/

- (void)suggestCheckins
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults boolForKey:@"showNotifications"] || ![defaults boolForKey:@"showReminders"])
		return;
	
	NSString *description = @"Foursquare venues nearby! Don't forget to check in!";
	NSString *clickContext = @"reminder:checkin";
	
	[GrowlApplicationBridge notifyWithTitle:@"Foursquare Reminder"
								description:description
						   notificationName:@"Check-in reminder"
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:clickContext];
}

- (void)showCheckinGrowl:(NSDictionary *)checkin isFriend:(BOOL)isFriend
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults boolForKey:@"showNotifications"] || (!isFriend && ![defaults boolForKey:@"showStrangers"]))
		return;
	
	NSString *venueName = [[checkin objectForKey:@"venue"] objectForKey:@"name"];
	
	if (!venueName)
		return;
	
	NSDate *time = [NSDate dateFromRFC2822:[checkin objectForKey:@"created"]];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
	[dateFormatter setDateFormat:@"h:mm a"];
	
	NSString *fullAddress = [Foursquare fullAddressForVenue:[checkin objectForKey:@"venue"]];
	
	NSString *description = [NSString stringWithFormat:@"%@ @ %@ (%@) at %@", 
							 [[checkin objectForKey:@"user"] objectForKey:@"firstname"],
							 venueName,
							 fullAddress,
							 [dateFormatter stringFromDate:time]];
	
	
	NSString *notificationName = nil;
	NSString *clickContext = nil;
	NSString *title = nil;
	if (isFriend) {
		clickContext = [NSString stringWithFormat:@"friend:%@",
						[checkin objectForKey:@"id"]];
		notificationName = @"Friend checks-in";
		title = @"Foursquare Check-in";
	} else {
		clickContext = [NSString stringWithFormat:@"venue:%@", 
						[[checkin objectForKey:@"venue"] objectForKey:@"id"]];
		notificationName = @"Someone checks-in at same venue as you";
		title = @"Foursquare user nearby!";
	}
	
	NSString *photoUrl = [[checkin objectForKey:@"user"] objectForKey:@"photo"];
	NSImage *avatarImage = [[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:photoUrl]] autorelease];
	
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:notificationName
								   iconData:[avatarImage TIFFRepresentation]
								   priority:0
								   isSticky:NO
							   clickContext:clickContext];
}

- (void)quickCheckinAction:(id)sender
{
	NSDictionary *venueDict = [sender representedObject];
	[NSApp activateIgnoringOtherApps:YES];
	[checkinWindowController showWindow:self withVenue:venueDict];
	[[checkinWindowController window] makeKeyAndOrderFront:self];
}

#pragma mark Properties

@synthesize currentCheckin;
@synthesize checkinWindowController;
@synthesize hasTwitter;
@synthesize hasFacebook;

@end
