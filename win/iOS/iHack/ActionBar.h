//
//  ActionBar.h
//  RogueTerm
//
//  Created by Dirk Zimmermann on 6/8/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _ActionBarPlacement {
    ActionBarPlacementRight,
    ActionBarPlacementLeft,
    ActionBarPlacementTop,
    ActionBarPlacementBottom,
} ActionBarPlacement;

@interface ActionBar : UIScrollView {
    
    NSMutableDictionary *buttonActions;
    CGFloat gap;
    
}

@property (nonatomic, retain) NSArray *actions;
@property (nonatomic, readonly) CGSize buttonSize;
@property (nonatomic, assign) ActionBarPlacement placement;
@property (nonatomic, copy) NSString *name;

@end
