//
//  MainMenuViewController.h
//  iNetHack
//
//  Created by Dirk Zimmermann on 9/1/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface MainMenuViewController : UITableViewController <SKRequestDelegate,SKProductsRequestDelegate> {
    
    SKProductsRequest *request;
    NSMutableArray *sections;
    
}

@end
