// http://lists.apple.com/archives/cocoa-dev/2007/Nov/msg02176.html

#import <Foundation/Foundation.h>

@interface NSData (NSData_HexAdditions)
- (NSString*) stringWithHexBytes;
@end

@implementation NSData (NSData_HexAdditions)
- (NSString*) stringWithHexBytes {
	NSMutableString *stringBuffer = [NSMutableString
									 stringWithCapacity:([self length] * 2)];
	const unsigned char *dataBuffer = [self bytes];
	int i;
	
	for (i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02X", (unsigned long)dataBuffer[ i ]];
	
	return [[stringBuffer copy] autorelease];
}
@end