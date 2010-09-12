// 
// FoursquareUpdater.m
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

#import "FoursquareUpdater.h"
#import "Foursquare.h"
#import "NSDate+RFC2822.h"
#import "NSArray-Blocks.h"

@interface FoursquareUpdater (PrivateAPI)
- (void)updateLocation;
- (void)getFriendCheckins;
- (void)getNearbyVenues;
- (void)getCheckinsAtVenue:(NSNumber *)venueId;
- (void)handleError:(NSError *)error withResult:(id)result forTask:(NSString *)task;
- (void)finish;
- (void)updateStatus:(NSString *)statusText;
@end

@implementation FoursquareUpdater

- (id)init
{
	if (self = [super init]) {
		locationManager = [[CLLocationManager alloc] init];
		[locationManager setDistanceFilter:kCLDistanceFilterNone];
		[locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
		[locationManager setDelegate:self];
	}
	return self;
}

- (void) dealloc
{
	delegate = nil;
	[locationManager release];
	[lastKnownLocation release];
	
	[super dealloc];
}


- (IBAction)refreshEverything:(id)sender
{
	if (refreshing) {
		NSLog(@"Refresh already in progress.");
		return;
	}
	
	refreshing = YES;
	
	if ([delegate respondsToSelector:@selector(foursquareUpdaterStartedUpdating:)])
		[delegate foursquareUpdaterStartedUpdating:self];
	
	[self updateStatus:@"Getting current checkin..."];
	
	[Foursquare detailForUser:nil 
				   showBadges:NO
					showMayor:NO
					 callback:^(id result, NSError *error) {
						 if (error) {
							 [self handleError:error withResult:result forTask:@"currentCheckin"];
							 return;
						 }
						
						 NSDictionary *dict = (NSDictionary *)result;
						 
						 NSDictionary *user    = [dict objectForKey:@"user"];
						 NSDictionary *checkin = [user objectForKey:@"checkin"];			
						 NSDictionary *venue   = [checkin objectForKey:@"venue"];
						 
						 NSString *venueName = [venue objectForKey:@"name"];
						 NSNumber *venueId   = [venue objectForKey:@"id"];
						 
						 NSLog(@"Got current venue: %@", venueName);
						 
						 NSDate *created       = [NSDate dateFromRFC2822:[checkin objectForKey:@"created"]];
						 NSDate *threeHoursAgo = [[NSDate date] dateByAddingTimeInterval:-10800];
						 
						 BOOL isValid = (venueId && [created laterDate:threeHoursAgo] == created);
						 
						 if ([delegate respondsToSelector:@selector(foursquareUpdater:gotOwnProfile:isValid:)])
							 [delegate foursquareUpdater:self gotOwnProfile:user isValid:isValid];
						 
						 if (isValid) {
							 // If we have a valid checkin, see if anyone else is at the venue.
							 [self getCheckinsAtVenue:venueId];
						 } else {
							 // Else, figure out where we are!
							 [self updateLocation];
						 }
					 }];
}

- (void)getCheckinsAtVenue:(NSNumber *)venueId
{
	[self updateStatus:[NSString stringWithFormat:@"Get checkins at venue: %@", venueId]];
	
	[Foursquare detailForVenue:venueId
					  callback:^(id result, NSError *error) {
						  if (error) {
							  [self handleError:error withResult:result forTask:@"venueCheckins"];
							  return;
						  }
						  
						  NSDictionary *venue = [result objectForKey:@"venue"];
						  
						  NSLog(@"Got detail for venue: %@", [venue objectForKey:@"id"]);
						  
						  if ([delegate respondsToSelector:@selector(foursquareUpdater:gotVenueDetails:)])
							  [delegate foursquareUpdater:self gotVenueDetails:venue];
						  
						  // Onto the next step!
						  [self updateLocation];
					  }];
}

- (void)updateLocation
{
	[self updateStatus:@"Finding your location..."];									  								
	[locationManager stopUpdatingLocation];
	[locationManager startUpdatingLocation];	
}

// Called when location is found
- (void)getFriendCheckins
{
	[self updateStatus:@"Getting friend checkins..."];
	
	NSNumber *geoLat = [NSNumber numberWithDouble:lastKnownLocation.coordinate.latitude];
	NSNumber *geoLng = [NSNumber numberWithDouble:lastKnownLocation.coordinate.longitude];
	
	[Foursquare recentFriendCheckinsNearLatitude:geoLat
									   longitude:geoLng
										callback:^(id result, NSError *error) {
											if (error) {
												[self handleError:error withResult:result forTask:@"friendCheckins"];
												return;
											}
											
											NSLog(@"Got friend checkins");
											
											NSArray *checkins = [result objectForKey:@"checkins"];
											
											// Filter out friends in other cities, if desired.
											NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
											BOOL showOtherCities = [[defaults objectForKey:@"showOtherCities"] boolValue];
											if (!showOtherCities) {
												checkins = [checkins findAll:^BOOL(id checkin, NSUInteger idx) {
													NSNumber *distance = [checkin objectForKey:@"distance"];
													return (BOOL) ([distance intValue] < 40000);
												}];
											}
											
											if ([delegate respondsToSelector:@selector(foursquareUpdater:gotFriendCheckins:)])
												[delegate foursquareUpdater:self gotFriendCheckins:checkins];
											
											// Next, what's nearby?
											[self getNearbyVenues];
										}];
}

- (void)getNearbyVenues
{	
	[self updateStatus:@"Searching for venues..."];
	[Foursquare venuesNearLatitude:lastKnownLocation.coordinate.latitude
						 longitude:lastKnownLocation.coordinate.longitude
						  matching:nil 
							 limit:nil 
						  callback:^(id result, NSError *error) {
							  if (error) {
								  [self handleError:error withResult:result forTask:@"nearbyVenues"];
								  return;
							  }
							  
							  NSDictionary *venuesDict = (NSDictionary *)result;
							  
							  if ([delegate respondsToSelector:@selector(foursquareUpdater:gotNearbyVenues:atLocation:oldLocation:)])
								  [delegate foursquareUpdater:self 
											  gotNearbyVenues:venuesDict
												   atLocation:lastKnownLocation
												  oldLocation:oldLastKnownLocation];
							  
							  [self finish];
						  }];
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation 
{	
	NSLog(@"DidUpdateToLocation!");
	
	NSDate *locationDate = [newLocation timestamp];
	NSTimeInterval locationAge = abs([locationDate timeIntervalSinceNow]);
	if (locationAge > 5.0) {
		NSLog(@"Location stale! %d", locationAge);
		// Location is stale - wait for next callback.
		return;
	}
	
	NSLog(@"Good location");
	
	[locationManager stopUpdatingLocation];
	
	[oldLastKnownLocation autorelease];
	oldLastKnownLocation = [lastKnownLocation copy];
	
	[lastKnownLocation autorelease];
	lastKnownLocation = [newLocation copy];
	
	[self getFriendCheckins];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error 
{
	[locationManager stopUpdatingLocation];
	[self handleError:error  withResult:nil forTask:@"location"];
}	

- (void)handleError:(NSError *)error withResult:(id)result forTask:(NSString *)task
{
	refreshing = NO;
	
	if ([delegate respondsToSelector:@selector(foursquareUpdater:failedWithError:result:whileUpdating:)])
		[delegate foursquareUpdater:self failedWithError:error result:result whileUpdating:task];
}

- (void)finish
{
	refreshing = NO;
	
	[self updateStatus:@"Update finished!"];
	
	if ([delegate respondsToSelector:@selector(foursquareUpdaterFinishedUpdating:)])
		[delegate foursquareUpdaterFinishedUpdating:self];
}

- (void)updateStatus:(NSString *)statusText
{
	if ([delegate respondsToSelector:@selector(foursquareUpdater:statusChanged:)])
		[delegate foursquareUpdater:self statusChanged:statusText];
}

@synthesize lastKnownLocation;

@end
