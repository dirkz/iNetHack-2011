//
//  ActionBar.m
//  RogueTerm
//
//  Created by Dirk Zimmermann on 6/8/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ActionBar.h"

#import "Action.h"

@interface ActionBar ()

@property (nonatomic, readonly) UIViewController *viewController;

- (void)buttonPressed:(id)sender;
- (void)defaultsChanged:(NSNotification *)n;
- (id)actionBarButton;

@end

@implementation ActionBar

@synthesize actions;
@synthesize buttonSize;
@synthesize placement;
@synthesize name;

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.bounces = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            buttonSize = CGSizeMake(60.f, 60.f);
        } else {
            buttonSize = CGSizeMake(40.f, 40.f);
        }
        self.placement = ActionBarPlacementLeft;
        gap = 2.f;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    CGRect frame = CGRectMake(0.f, 0.f, buttonSize.width, buttonSize.height);
    for (UIView *v in self.subviews) {
        v.frame = frame;
        if (self.placement == ActionBarPlacementLeft || self.placement == ActionBarPlacementRight) {
            frame.origin.y += buttonSize.height;
        } else {
            frame.origin.x += buttonSize.width;
        }
    }

    // layout self
    UIView *sview = self.superview;
    if (sview) {
        CGRect sbounds = sview.bounds;
        if (self.placement == ActionBarPlacementLeft || self.placement == ActionBarPlacementRight) {
            int numButtonsToOmit = 2;
            int numVisibleButtons = floorf(sbounds.size.height / buttonSize.height) - numButtonsToOmit; // omit one button at top and bottom respectively
            numVisibleButtons = MIN(numVisibleButtons, actions.count);
            CGFloat height = MIN(numVisibleButtons * buttonSize.height, sbounds.size.height - numButtonsToOmit * buttonSize.width);
            frame = CGRectMake(0.f, (sbounds.size.height-height)/2,
                               buttonSize.width, height);
            if (self.placement == ActionBarPlacementLeft) {
                frame.origin.x = gap;
            } else {
                frame.origin.x = sbounds.size.width-buttonSize.width - gap;
            }
        } else {
            int numButtons = floorf(sbounds.size.width / buttonSize.width);
            int numVisibleButtons = MIN(numButtons, actions.count);
            CGFloat width = numVisibleButtons * buttonSize.width;
            frame = CGRectMake((sbounds.size.width - width)/2, gap, width, buttonSize.height);
            if (self.placement == ActionBarPlacementBottom) {
                frame.origin.y = sbounds.size.height-buttonSize.height;
            }
        }
        
        if (!CGRectEqualToRect(self.frame, frame)) {
            self.frame = frame;
        }
    }
}

#pragma mark - Util

- (id)actionBarButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        button.titleLabel.font = [button.titleLabel.font fontWithSize:22.f];
    } else {
        button.titleLabel.font = [button.titleLabel.font fontWithSize:12.f];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[button layer] setCornerRadius:6.f];
    } else {
        [[button layer] setCornerRadius:4.f];
    }
    [[button layer] setMasksToBounds:YES];
    [[button layer] setBorderWidth:1.f];
    [[button layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    return button;
}

#pragma mark - Properties

- (void)setActions:(NSArray *)as {
    if (as != actions) {
        [actions release];
        actions = [as retain];
        for (UIView *v in self.subviews) {
            [v removeFromSuperview];
        }

        [buttonActions release];
        buttonActions = [[NSMutableDictionary alloc] initWithCapacity:as.count];
        
        for (Action *a in as) {
            UIButton *button = [self actionBarButton];
            [button setTitle:a.title forState:UIControlStateNormal];
            
            [buttonActions setObject:a forKey:[NSValue valueWithPointer:button]];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
        }
    }
    
    [self setNeedsLayout];
}

- (void)setPlacement:(ActionBarPlacement)p {
    placement = p;

    CGSize contentSize = CGSizeZero;
    if (self.placement == ActionBarPlacementLeft || self.placement == ActionBarPlacementRight) {
        contentSize = CGSizeMake(self.buttonSize.width, self.buttonSize.height * self.actions.count);
    } else {
        contentSize = CGSizeMake(self.buttonSize.width * self.actions.count, self.buttonSize.height);
    }
    if (!CGSizeEqualToSize(contentSize, self.contentSize)) {
        [self setContentSize:contentSize];
    }

    [self setNeedsLayout];
}

#pragma mark - Actions

- (void)buttonPressed:(id)sender {
    Action *a = [buttonActions objectForKey:[NSValue valueWithPointer:sender]];
    [a invoke:sender];
}

#pragma mark - Util

- (UIViewController *)viewController {
    UIResponder *r = [self nextResponder];
    while (![r isKindOfClass:[UIViewController class]] && r != nil) {
        r = [r nextResponder];
    }
    return (UIViewController *) r;
}

#pragma mark - Notifications

- (void)defaultsChanged:(NSNotification *)n {
}

#pragma mark - Memory

- (void)dealloc
{
    [actions release];
    [buttonActions release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [super dealloc];
}

@end
