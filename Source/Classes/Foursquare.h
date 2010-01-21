// 
// Foursquare.h
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
#import <HTTPRiot/HTTPRiot.h>

typedef void(^FoursquareCallback)(BOOL success, id result);

@interface Foursquare : HRRestModel {
}

+ (void)listCities:(FoursquareCallback)callback;

+ (void)cityNearestLatitude:(NSString *)geoLat 
				  longitude:(NSString *)geoLong 
				   callback:(FoursquareCallback)callback;

+ (void)switchToCity:(NSNumber *)cityId 
			callback:(FoursquareCallback)callback;

+ (void)recentFriendCheckinsInCity:(NSNumber *)cityId 
						  callback:(FoursquareCallback)callback;

+ (void)checkinAtVenueId:(NSString *)venueId 
			   venueName:(NSString *)venueName 
				   shout:(NSString *)shout 
			 showFriends:(BOOL)showFriends 
			   sendTweet:(BOOL)sendTweet
			tellFacebook:(BOOL)tellFacebook
				latitude:(NSString *)geolat
			   longitude:(NSString *)geolong
				callback:(FoursquareCallback)callback;

+ (void)checkinHistoryWithLimit:(NSNumber *)limit 
					   callback:(FoursquareCallback)callback;

+ (void)detailForUser:(NSNumber *)userId 
		   showBadges:(BOOL)showBadges 
			showMayor:(BOOL)showMayor 
			 callback:(FoursquareCallback)callback;

+ (void)friendsForUser:(NSNumber *)userId  			 
			  callback:(FoursquareCallback)callback;

+ (void)venuesNearLatitude:(double)geoLat 
				 longitude:(double)geoLong
				  matching:(NSString *)keywordSearch  
					 limit:(NSNumber *)limit   
				  callback:(FoursquareCallback)callback;

+ (void)detailForVenue:(NSNumber *)venueId
			  callback:(FoursquareCallback)callback;

+ (void)addVenue:(NSString *)name 
		 address:(NSString *)address 
	 crossStreet:(NSString *)crossStreet 
			city:(NSString *)city
		   state:(NSString *)state
			 zip:(NSString *)zip
		  cityId:(NSNumber *)cityId
		   phone:(NSString *)phone
		callback:(FoursquareCallback)callback;

+ (void)tipsNearLatitude:(NSString *)geoLat
			   longitude:(NSString *)geoLong
				   limit:(NSNumber *)limit 			
				callback:(FoursquareCallback)callback;

+ (void)addTip:(NSString *)tip 
	  forVenue:(NSNumber *)venueId 
	  callback:(FoursquareCallback)callback;

+ (void)addTodo:(NSString *)todo 
	   forVenue:(NSNumber *)venueId 		
	   callback:(FoursquareCallback)callback;

+ (void)friendRequests:(FoursquareCallback)callback;

+ (void)approveFriendRequest:(NSNumber *)userId 
					callback:(FoursquareCallback)callback;

+ (void)denyFriendRequest:(NSNumber *)userId 
				 callback:(FoursquareCallback)callback;

+ (void)sendFriendRequest:(NSNumber *)userId
				 callback:(FoursquareCallback)callback;

+ (void)findFriendsByName:(NSString *)nameQuery
				 callback:(FoursquareCallback)callback;

+ (void)findFriendsByPhone:(NSString *)phoneNumberQuery
				  callback:(FoursquareCallback)callback;

+ (void)findFriendsByTwitter:(NSString *)twitterQuery
					callback:(FoursquareCallback)callback;

+ (void)setPingsOff:(FoursquareCallback)callback;

+ (void)setPingsOffFor:(NSNumber *)userId callback:(FoursquareCallback)callback;

+ (void)setPingsOn:(FoursquareCallback)callback;

+ (void)setPingsOnFor:(NSNumber *)userId callback:(FoursquareCallback)callback;

+ (void)goodnight:(FoursquareCallback)callback;

+ (void)test:(FoursquareCallback)callback;

+ (NSString *)fullAddressForVenue:(NSDictionary *)venueDict;

@end
