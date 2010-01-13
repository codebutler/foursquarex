// Based on code from http://fi.am/entry/parsing-rfc2822-dates-with-nsdate/ 

#import <Foundation/Foundation.h>

@interface NSDate (RFC2822)
+ (NSDate *)dateFromRFC2822:(NSString *)rfc2822;
@end