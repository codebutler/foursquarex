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

@interface FoursquareUpdater (PrivateAPI)
- (void)getFriendCheckins;
- (void)getCheckinsAtVenue:(NSNumber *)venueId;
- (void)handleError:(id)response forTask:(NSString *)task;
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
					 callback:^(BOOL success, id response) {
						 if (!success) {
							 [self handleError:response forTask:@"currentCheckin"];
							 return;
						 }
						
						 NSDictionary *dict = (NSDictionary *)response;
						 
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
							 // Else, figure out where out friends are!
							 [self getFriendCheckins];
						 }
					 }];
}

- (void)getCheckinsAtVenue:(NSNumber *)venueId
{
	[self updateStatus:[NSString stringWithFormat:@"Get checkins at venue: %@", venueId]];
	
	[Foursquare detailForVenue:venueId
					  callback:^(BOOL success, id response) {
						  if (!success) {
							  [self handleError:response forTask:@"venueCheckins"];
						  }
						  
						  NSDictionary *venue = [response objectForKey:@"venue"];
						  
						  NSLog(@"Got detail for venue: %@", [venue objectForKey:@"id"]);
						  
						  if ([delegate respondsToSelector:@selector(foursquareUpdater:gotVenueDetails:)])
							  [delegate foursquareUpdater:self gotVenueDetails:venue];
						  
						  // Onto the next step!
						  [self getFriendCheckins];
					  }];
}

- (void)getFriendCheckins
{
	[self updateStatus:@"Getting friend checkins..."];
	
	[Foursquare recentFriendCheckinsInCity:nil
								  callback:^(BOOL success, id response) {
									  if (!success) {
										  [self handleError:response forTask:@"friendCheckins"];
									  }
								  
									  NSLog(@"Got friend checkins");
									  
									  NSArray *checkins = [response objectForKey:@"checkins"];
									  
									  if ([delegate respondsToSelector:@selector(foursquareUpdater:gotFriendCheckins:)])
										  [delegate foursquareUpdater:self gotFriendCheckins:checkins];
									  
									  // Next, where are we?
									  [self updateStatus:@"Finding your location..."];									  								
									  [locationManager stopUpdatingLocation];
									  [locationManager startUpdatingLocation];
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
	
	if (lastKnownLocation && [newLocation distanceFromLocation:lastKnownLocation] < 10.0) {
		// Location didn't change, no need to refresh venues.
		NSLog(@"Location didn't change - not refreshing venues.");
		[self finish];
		return;
	}
	
	CLLocation *oldLastKnownLocation = [[lastKnownLocation retain] autorelease];
	
	[lastKnownLocation autorelease];
	lastKnownLocation = [newLocation copy];
	
	[self updateStatus:@"Searching for venues..."];
	[Foursquare venuesNearLatitude:newLocation.coordinate.latitude
						 longitude:newLocation.coordinate.longitude
						  matching:nil 
							 limit:nil 
						  callback:^(BOOL success, id result) {
							  if (!success) {
								  [self handleError:result forTask:@"nearbyVenues"];
								  return;
							  }
							  
							  NSDictionary *venuesDict = (NSDictionary *)result;
							  
							  if ([delegate respondsToSelector:@selector(foursquareUpdater:gotNearbyVenues:atLocation:oldLocation:)])
								  [delegate foursquareUpdater:self 
											  gotNearbyVenues:venuesDict
												   atLocation:newLocation
												  oldLocation:oldLastKnownLocation];
								  
								  [self finish];
						  }];
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error 
{
	[locationManager stopUpdatingLocation];
	[self handleError:error forTask:@"location"];
}	

- (void)handleError:(id)response forTask:(NSString *)task
{
	refreshing = NO;
	
	if ([delegate respondsToSelector:@selector(foursquareUpdater:failedWithResponse:whileUpdating:)])
		[delegate foursquareUpdater:self failedWithResponse:response whileUpdating:task];
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
