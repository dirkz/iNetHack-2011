//
//  BlockAction.m
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/15/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import "BlockAction.h"

@implementation BlockAction

@synthesize actionBlock;

+ (id)actionWithTitle:(NSString *)t actionBlock:(ActionBlock)b {
    return [[[self alloc] initWithTitle:t actionBlock:b] autorelease];
}

- (id)initWithTitle:(NSString *)t actionBlock:(ActionBlock)b {
    if ((self = [super initWithTitle:t])) {
        self.actionBlock = b;
    }
    return self;
}

- (void)invoke:(id)sender {
    if (self.actionBlock) {
        self.actionBlock(self);
    }
}

- (void)addTarget:(id)target action:(SEL)action arg:(id)arg {
    [NSException raise:NSInternalInconsistencyException format:@"%@ no support for addTarget", self];
}

- (void)addInvocation:(NSInvocation *)inv {
    [NSException raise:NSInternalInconsistencyException format:@"%@ no support for addInvocation", self];
}

- (void)dealloc {
    [actionBlock release];
    [super dealloc];
}

@end
