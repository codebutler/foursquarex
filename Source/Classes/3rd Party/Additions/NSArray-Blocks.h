//
//  NSArray-Blocks.h
//  Handy codebits
//
//  If you want to keep block definitions terse, simple and dynamic, have no
//  problems with the incompatible block pointer types and you don't mind
//  compiler warnings about sending a message without matching signature,
//  DO NOT IMPORT THIS FILE, seriously.
//
//  Created by Sijawusz Pur Rahnama on 15/11/09.
//  Copyleft 2009. Some rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *
 */
static NSComparisonResult block_compare(id arg1, id arg2, NSComparisonResult (^block)(id, id));

/**
 *
 */
typedef BOOL (^NSArrayLogicalBlock)(id obj, NSUInteger idx);
typedef id   (^NSArrayInjectionBlock)(id memo, id obj, NSUInteger idx);
typedef id   (^NSArrayBlock)(id obj, NSUInteger idx);

/**
 *
 */
@interface NSArray (Blocks)

+ (NSArray *) arrayWithBlock:(id (^)(NSUInteger))block size:(NSUInteger)size;

- (BOOL) all:(NSArrayLogicalBlock)block;
- (BOOL) every:(NSArrayLogicalBlock)block; /// @ref self::all()
- (BOOL) any:(NSArrayLogicalBlock)block;
- (BOOL) some:(NSArrayLogicalBlock)block; /// @ref self::any()

- (void) each:(void (^)(id, NSUInteger))block;

- (id) find:(NSArrayLogicalBlock)block;
- (id) detect:(NSArrayLogicalBlock)block; /// @ref self::find()
- (id) inject:(id)memo with:(NSArrayInjectionBlock)block;
- (id) inject:(NSArrayInjectionBlock)block;

- (NSArray *) sort:(NSComparisonResult (^)(id, id))block;

- (NSArray *) select:(NSArrayLogicalBlock)block;
- (NSArray *) findAll:(NSArrayLogicalBlock)block; /// @ref self::select()
- (NSArray *) filter:(NSArrayLogicalBlock)block; /// @ref self::select()
- (NSArray *) reject:(NSArrayLogicalBlock)block;
- (NSArray *) partition:(NSArrayLogicalBlock)block;
- (NSArray *) map:(NSArrayBlock)block;
- (NSArray *) collect:(NSArrayBlock)block; /// @ref self::map()

@end
