// 
// FoursquareUpdater.h
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

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>


@interface FoursquareUpdater : NSObject <CLLocationManagerDelegate> {
	id delegate;
	
	BOOL refreshing;
	
	CLLocationManager *locationManager;
	CLLocation *lastKnownLocation;
}

- (IBAction)refreshEverything:(id)sender;

@property (assign) CLLocation* lastKnownLocation;

@end

@interface NSObject (FoursquareUpdaterDelegate)
- (void)foursquareUpdaterStartedUpdating:(FoursquareUpdater *)updater;
- (void)foursquareUpdaterFinishedUpdating:(FoursquareUpdater *)updater;
- (void)foursquareUpdater:(FoursquareUpdater *)updater failedWithResponse:(id)response whileUpdating:(NSString *)task;
- (void)foursquareUpdater:(FoursquareUpdater *)updater statusChanged:(NSString *)statusText;
- (void)foursquareUpdater:(FoursquareUpdater *)updater gotOwnCheckin:(NSDictionary *)venueDict isValid:(BOOL)isValid;
- (void)foursquareUpdater:(FoursquareUpdater *)updater gotFriendCheckins:(NSArray *)friendCheckins;
- (void)foursquareUpdater:(FoursquareUpdater *)updater gotVenueDetails:(NSDictionary *)venueDict;
- (void)foursquareUpdater:(FoursquareUpdater *)updater gotNearbyVenues:(NSDictionary *)venues
			   atLocation:(CLLocation *)newLocation 
			  oldLocation:(CLLocation *)oldLocation;
@end