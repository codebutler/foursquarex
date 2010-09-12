// 
// Foursquare.m
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

#import "Foursquare.h"
#import "OAuthHelper.h"
#import "NSURLAdditions.h"

@interface Foursquare (PrivateAPI)
+ (void)        get:(NSString *)methodName
         withParams:(NSDictionary *)params 
		   callback:(FoursquareCallback)callback;

+ (void)       post:(NSString *)methodName
		 withParams:(NSDictionary *)params
		   callback:(FoursquareCallback)callback;

+ (void)    request:(NSString *)methodName 
	     withParams:(NSDictionary *)params 
	     httpMethod:(NSString *)httpMethod
		   callback:(FoursquareCallback)callback;

// Declared in HRRestModel
+ (void)setAttributeValue:(id)attr forKey:(NSString *)key;
+ (NSMutableDictionary *)classAttributes;
@end

@implementation Foursquare

+ (void)initialize
{
	[self setFormat:HRDataFormatJSON];
	[self setDelegate:self];
	[self setBaseURL:[NSURL URLWithString:@"https://api.foursquare.com/v1"]];
}

+ (void)getOAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password callback:(id)callback
{
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							username, @"fs_username", 
							password, @"fs_password",
							nil];
	[self post:@"authexchange" withParams:params callback:callback];	
}

+ (void)setOAuthAccessToken:(NSString *)token secret:(NSString *)secret
{
    [self setAttributeValue:[[token copy] autorelease]  forKey:@"oauth_access_token"];
    [self setAttributeValue:[[secret copy] autorelease] forKey:@"oauth_access_secret"];
}

+ (void)listCities:(FoursquareCallback)callback
{
	[self get:@"cities" withParams:nil callback:callback];
}

+ (void)cityNearestLatitude:(NSString *)geoLat 
				  longitude:(NSString *)geoLong 
				   callback:(FoursquareCallback)callback 
{	
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							geoLat, @"geolat", 
							geoLong, @"geolong", 
							nil];
	[self get:@"/checkcity" withParams:params callback:callback];
}

+ (void)switchToCity:(NSNumber *)cityId 
			callback:(FoursquareCallback)callback 
{
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							cityId, @"cityid", 
							nil];
	[self post:@"switchcity" withParams:params callback:callback];
}

+ (void)recentFriendCheckinsNearLatitude:(NSNumber *)geoLat
							   longitude:(NSNumber *)geoLong
								callback:(FoursquareCallback)callback
{	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	
	if (geoLat)
		[params setObject:[NSString stringWithFormat:@"%f", [geoLat doubleValue]]
				   forKey:@"geolat"];
	
	if (geoLong)
		[params setObject:[NSString stringWithFormat:@"%f", [geoLong doubleValue]]
				   forKey:@"geolong"];
	
	[self get:@"checkins" withParams:params callback:callback];
}

+ (void)checkinAtVenueId:(NSString *)venueId 
			   venueName:(NSString *)venueName 
				   shout:(NSString *)shout 
			 showFriends:(BOOL)showFriends 
			   sendTweet:(BOOL)sendTweet
			tellFacebook:(BOOL)tellFacebook
				latitude:(NSString *)geoLat
			   longitude:(NSString *)geoLong
				callback:(FoursquareCallback)callback 
{	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	
	if (venueId)
		[params setObject:venueId forKey:@"vid"];
	
	if (venueName)
		[params setObject:venueName forKey:@"venue"];
	
	if (shout)
		[params setObject:shout forKey:@"shout"];
	
	NSString *private = showFriends ? @"0" : @"1";
	[params setObject:private forKey:@"private"];
	
	NSString *twitter = sendTweet ? @"1" : @"0";
	[params setObject:twitter forKey:@"twitter"];
	
	NSString *facebook = tellFacebook ? @"1" : @"0";
	[params setObject:facebook forKey:@"facebook"];
	
	if (geoLat)	
		[params setObject:geoLat forKey:@"geolat"];
	
	if (geoLong)	
		[params setObject:geoLong forKey:@"geolong"];
	
	[self post:@"checkin" withParams:params callback:callback];	
}

+ (void)checkinHistoryWithLimit:(NSNumber *)limit 
					   callback:(FoursquareCallback)callback 
{
	[self doesNotRecognizeSelector:_cmd];
}

+ (void)detailForUser:(NSNumber *)userId 
		   showBadges:(BOOL)showBadges 
			showMayor:(BOOL)showMayor 
			 callback:(FoursquareCallback)callback 
{
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	
	if (userId)
		[params setObject:userId forKey:@"uid"];
	
	NSString *badges = showBadges ? @"1" : @"0";
	[params setObject:badges forKey:@"badges"];
	
	NSString *mayor = showMayor ? @"1" : @"0";
	[params setObject:mayor forKey:@"mayor"];
	
	[self get:@"user" withParams:params callback:callback];
}

+ (void)friendsForUser:(NSNumber *)userId  			 
			  callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)venuesNearLatitude:(double)geoLat 
				 longitude:(double)geoLong
				  matching:(NSString *)keywordSearch  
					 limit:(NSNumber *)limit   
				  callback:(FoursquareCallback)callback
{	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	
	[params setObject:[NSString stringWithFormat:@"%f", geoLat] 
			   forKey:@"geolat"];

	[params setObject:[NSString stringWithFormat:@"%f", geoLong]
			   forKey:@"geolong"];

	if (keywordSearch)
		[params setObject:[[keywordSearch copy] autorelease] forKey:@"q"];
	
	if (limit)
		[params setObject:limit forKey:@"l"];
		
	[self get:@"venues" withParams:params callback:callback];
}


+ (void)detailForVenue:(NSNumber *)venueId
			  callback:(FoursquareCallback)callback 
{
	NSDictionary *params = [NSDictionary dictionaryWithObject:[venueId stringValue] 
													   forKey:@"vid"];
	[self get:@"venue" withParams:params callback:callback];
}

+ (void)addVenue:(NSString *)name 
		 address:(NSString *)address 
	 crossStreet:(NSString *)crossStreet 
			city:(NSString *)city
		   state:(NSString *)state
			 zip:(NSString *)zip
		  cityId:(NSNumber *)cityId
		   phone:(NSString *)phone
		callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)tipsNearLatitude:(NSString *)geoLat
			   longitude:(NSString *)geoLong
				   limit:(NSNumber *)limit 			
				callback:(FoursquareCallback)callback 
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)addTip:(NSString *)tip 
	  forVenue:(NSNumber *)venueId 
	  callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)addTodo:(NSString *)todo 
	   forVenue:(NSNumber *)venueId 		
	   callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)friendRequests:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)approveFriendRequest:(NSNumber *)userId 
					callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)denyFriendRequest:(NSNumber *)userId 
				 callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)sendFriendRequest:(NSNumber *)userId
				 callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)findFriendsByName:(NSString *)nameQuery
				 callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)findFriendsByPhone:(NSString *)phoneNumberQuery
				  callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)findFriendsByTwitter:(NSString *)twitterQuery
					callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)setPingsOff:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)setPingsOffFor:(NSNumber *)userId callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)setPingsOn:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)setPingsOnFor:(NSNumber *)userId callback:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)goodnight:(FoursquareCallback)callback
{
	[self doesNotRecognizeSelector:_cmd];	
}

+ (void)test:(FoursquareCallback)callback
{
	[self get:@"test" withParams:nil callback:callback];
}

#pragma mark Static helper methods

+ (NSString *)fullAddressForVenue:(NSDictionary *)venueDict
{
	NSString *fullAddress = @"";
	
	NSString *address = [venueDict objectForKey:@"address"];
	NSString *crossStreet = [venueDict objectForKey:@"crossstreet"];
	
	if ([address length] > 0) {
		if ([crossStreet length] > 0)
			fullAddress = [NSString stringWithFormat:@"%@, %@", address, crossStreet];
		else
			fullAddress = address;
	}
	
	return fullAddress;
}

#pragma mark HRRequestOperation Delegates
+ (void)restConnection:(NSURLConnection *)connection
	  didFailWithError:(NSError *)error 
				object:(id)object 
{
	FoursquareCallback callback = (FoursquareCallback)object;
	callback(nil, error);
	[callback release];
}

+ (void)restConnection:(NSURLConnection *)connection 
	   didReceiveError:(NSError *)error 
			  resource:(id)resource
			  response:(NSHTTPURLResponse *)response 
				object:(id)object
{
	FoursquareCallback callback = (FoursquareCallback)object;
	callback(resource, error);
	[callback release];
}

+ (void)restConnection:(NSURLConnection *)connection
  didReceiveParseError:(NSError *)error 
		  responseBody:(NSString *)string
				object:(id)object
{
	FoursquareCallback callback = (FoursquareCallback)object;
	callback(string, error);
	[callback release];
}

+ (void)restConnection:(NSURLConnection *)connection 
	 didReturnResource:(id)resource 
			  response:(NSHTTPURLResponse *)response
				object:(id)object
{
	FoursquareCallback callback = (FoursquareCallback)object;
	callback(resource, nil);
	[callback release];
}

#pragma mark Private methods

+ (void)        get:(NSString *)methodName
         withParams:(NSDictionary *)params 
		   callback:(FoursquareCallback)callback
{
	[self request:methodName withParams:params httpMethod:@"GET" callback:callback];
}

+ (void)       post:(NSString *)methodName
		 withParams:(NSDictionary *)params
		   callback:(FoursquareCallback)callback 
{
	[self request:methodName withParams:params httpMethod:@"POST" callback:callback];
}

+ (void)    request:(NSString *)methodName 
	     withParams:(NSDictionary *)params 
	     httpMethod:(NSString *)httpMethod
		   callback:(FoursquareCallback)callback
{
	callback = [callback copy];
	
	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	
	NSString *path = nil;
	// HACK: This method is apparently XML-only and sometimes returns plaintext errors.
	if ([methodName isEqualToString:@"authexchange"]) {
		path = [NSString stringWithFormat:@"/%@", methodName];
		[options setValue:[NSNumber numberWithInt:HRDataFormatUnknown] forKey:kHRClassAttributesFormatKey];
	} else {
		path = [NSString stringWithFormat:@"/%@.json", methodName];
	}
	
	NSString *token  = [[self classAttributes] objectForKey:@"oauth_access_token"];
	NSString *secret = [[self classAttributes] objectForKey:@"oauth_access_secret"];
	
	NSString *url = [[[self baseURL] URLBySmartlyAppendingPathComponent:path] absoluteString];
		
	NSDictionary *finalParams = [OAuthHelper signRequest:url
												  method:httpMethod 
												  params:params
											 consumerKey:OAUTH_KEY
										  consumerSecret:OAUTH_SECRET
											 accessToken:token
											accessSecret:secret];
	
	[options setObject:finalParams forKey:kHRClassAttributesParamsKey];

	if ([httpMethod isEqualToString:@"GET"])
		[self getPath:path withOptions:options object:callback];
	else
		[self postPath:path withOptions:options object:callback];
}
@end
