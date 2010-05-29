#import <Cocoa/Cocoa.h>


@interface NSURL (Additions)

- (NSURL *)URLBySmartlyAppendingPathComponent:(NSString *)component;

@end
