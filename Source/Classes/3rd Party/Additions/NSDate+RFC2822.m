// Based on code from http://fi.am/entry/parsing-rfc2822-dates-with-nsdate/ 

#import "NSDate+RFC2822.h"

@implementation NSDate (RFC2822)

+ (NSDateFormatter*)rfc2822Formatter {
	static NSDateFormatter *formatter = nil;
	if (formatter == nil) {
		formatter = [[NSDateFormatter alloc] init];
		NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[formatter setLocale:enUS];
		[enUS release];
		[formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
	}
	return formatter;
}

+ (NSDate*)dateFromRFC2822:(NSString *)rfc2822 {
	NSDateFormatter *formatter = [NSDate rfc2822Formatter];
	return [formatter dateFromString:rfc2822];
}

@end
