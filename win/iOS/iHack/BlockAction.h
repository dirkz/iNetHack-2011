//
//  BlockAction.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 7/15/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Action.h"

typedef void (^ActionBlock)(Action *action);

@interface BlockAction : Action {
    
}

@property (nonatomic, copy) ActionBlock actionBlock;

+ (id)actionWithTitle:(NSString *)t actionBlock:(ActionBlock)b;

- (id)initWithTitle:(NSString *)t actionBlock:(ActionBlock)b;

@end
