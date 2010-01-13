//
//  NSArray-Blocks.m
//  Handy codebits
//
//  Created by Sijawusz Pur Rahnama on 15/11/09.
//  Copyleft 2009. Some rights reserved.
//

#import "NSArray-Blocks.h"

/**
 *
 */
static NSComparisonResult block_compare(id arg1, id arg2, NSComparisonResult (^block)(id, id)) {
    return block(arg1, arg2);
}

/**
 *
 */
@implementation NSArray (Blocks)

+ (NSArray *) arrayWithBlock:(id (^)(NSUInteger))block size:(NSUInteger)size {
    id new = [NSMutableArray arrayWithCapacity:size];
    for (NSUInteger i = 0; i < size; i++) {
        [new addObject:block(i)];
    }
    return new;
}

- (BOOL) all:(NSArrayLogicalBlock)block {
    NSUInteger i = 0;
    BOOL truth = YES;
    for (id obj in self) {
        truth = truth && block(obj, i++);
    }
    return truth;
}

- (BOOL) every:(NSArrayLogicalBlock)block {
    return [self all:block];
}

- (BOOL) any:(NSArrayLogicalBlock)block {
    NSUInteger i = 0;
    BOOL truth = NO;
    for (id obj in self) {
        truth = truth || block(obj, i++);
    }
    return truth;
}

- (BOOL) some:(NSArrayLogicalBlock)block {
    return [self any:block];
}

- (void) each:(void (^)(id, NSUInteger))block {
    NSUInteger i = 0;
    for (id obj in self) {
        block(obj, i++);
    }
}

- (id) find:(NSArrayLogicalBlock)block {
    NSUInteger i = 0;
    for (id obj in self) {
        if (block(obj, i++)) return obj;
    }
    return nil;
}

- (id) detect:(NSArrayLogicalBlock)block {
    return [self find:block];
}

- (id) inject:(id)memo with:(NSArrayInjectionBlock)block {
    NSUInteger i = 0;
    for (id obj in self) {
        memo = block(memo, obj, i++);
    }
    return memo;
}

- (id) inject:(NSArrayInjectionBlock)block {
    if ([self count]) {
        return [self inject:[self objectAtIndex:0] with:block];
    }
    return nil;
}

- (NSArray *) sort:(NSComparisonResult (^)(id, id))block {
    return [self sortedArrayUsingFunction:&block_compare context:block];
}

- (NSArray *) select:(NSArrayLogicalBlock)block {
    NSMutableArray *new = [NSMutableArray array];
    NSUInteger i = 0;
    for (id obj in self) {
        if (block(obj, i++)) [new addObject:obj];
    }
    return new;
}

- (NSArray *) findAll:(NSArrayLogicalBlock)block {
    return [self select:block];
}

- (NSArray *) filter:(NSArrayLogicalBlock)block {
    return [self select:block];
}

- (NSArray *) reject:(NSArrayLogicalBlock)block {
    NSMutableArray *new = [NSMutableArray array];
    NSUInteger i = 0;
    for (id obj in self) {
        if (!block(obj, i++)) [new addObject:obj];
    }
    return new;
}

- (NSArray *) partition:(NSArrayLogicalBlock)block {
    NSMutableArray *ayes = [NSMutableArray array];
    NSMutableArray *noes = [NSMutableArray array];
    NSUInteger i = 0;
    for (id obj in self) {
        if (block(obj, i++)) [ayes addObject:obj];
        else                 [noes addObject:obj];
    }
    return [NSArray arrayWithObjects:ayes, noes, nil];
}

- (NSArray *) map:(NSArrayBlock)block {
    NSMutableArray *new = [NSMutableArray arrayWithCapacity:[self count]];
    NSUInteger i = 0;
    for (id obj in self) {
        id newObj = block(obj, i++);
        [new addObject:newObj ? newObj : [NSNull null]];
    }
    return new;
}

- (NSArray *) collect:(NSArrayBlock)block {
    return [self map:block];
}

@end
