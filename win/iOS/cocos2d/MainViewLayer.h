//
//  MainViewLayer.h
//  iNetHack
//
//  Created by Dirk Zimmermann on 8/19/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class TileSet;

@interface MainViewLayer : CCNode {
    
    int clipX, clipY;
    TileSet *tileSet;
    CCSpriteBatchNode *levelBatchNode;
    CGSize tileSize;
    
}

+ (id)sharedInstance;
+ (CCScene *)scene;

- (void)drawFrame;
- (void)updateTileSet;
- (void)clipAroundX:(int)x y:(int)y;

@end
