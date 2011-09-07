//
//  MainMenuViewController.m
//  iNetHack
//
//  Created by Dirk Zimmermann on 9/1/11.
//  Copyright 2011 Dirk Zimmermann. All rights reserved.
//

#import "MainMenuViewController.h"

#import "TileSetViewController.h"
#import "MainViewController.h"

@interface MainMenuViewController ()

@property (nonatomic, readonly) UIActivityIndicatorView *activityIndicator;

- (void)setActivity:(BOOL)active;

@end

@implementation MainMenuViewController

@synthesize activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.title = @"Main Menu";
        
        skProducts = [[NSMutableArray alloc] init];

        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:@"BuyAWish", nil]];
        request.delegate = self;
        [self setActivity:YES];
        [request start];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return skProducts.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Tilesets";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        SKProduct *product = [skProducts objectAtIndex:indexPath.row-1];
        cell.textLabel.text = product.localizedTitle;
        cell.detailTextLabel.text = product.localizedDescription;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - SKRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSUInteger oldCount = [skProducts count];
    [skProducts setArray:response.products];
    NSUInteger newCount = [skProducts count];
    
    DLog(@"old # of products %u, new %u", oldCount, newCount);
    
    NSMutableArray *indexPathsToDelete = nil;
    if (oldCount > 0) {
        indexPathsToDelete = [NSMutableArray arrayWithCapacity:oldCount];
        for (uint i = 0; i < oldCount; ++i) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i+1 inSection:0]];
        }
    }
    
    NSMutableArray *indexPathsToAdd = nil;
    if (newCount > 0) {
        indexPathsToAdd = [NSMutableArray arrayWithCapacity:[skProducts count]];
        for (uint i = 0; i < newCount; ++i) {
            [indexPathsToAdd addObject:[NSIndexPath indexPathForRow:i+1 inSection:0]];
        }
    }
    
    if (indexPathsToDelete || indexPathsToAdd) {
        DLog(@"updating");
        [self.tableView beginUpdates];
        if (indexPathsToDelete) {
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationBottom];
        }
        if (indexPathsToAdd) {
            [self.tableView insertRowsAtIndexPaths:indexPathsToAdd withRowAnimation:UITableViewRowAnimationBottom];
        }
        [self.tableView endUpdates];
    }

    [self setActivity:NO];
}

#pragma mark - SKProductsRequestDelegate

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [self setActivity:NO];
}

- (void)requestDidFinish:(SKRequest *)request {
    [self setActivity:NO];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        TileSetViewController *vc = [[TileSetViewController alloc] initWithNibName:@"TileSetViewController" bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor darkGrayColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    tableView.backgroundColor = [UIColor darkGrayColor];
}

#pragma mark - Helpers

- (void)setActivity:(BOOL)active {
    if (active) {
        if (!self.tableView.tableHeaderView) {
            CGRect bounds = self.tableView.bounds;
            CGFloat height = 40.f;
            bounds.origin.y = bounds.size.height-height;
            bounds.size.height = height;
            toolbar = [[UIToolbar alloc] initWithFrame:bounds];
            UIBarButtonItem	*flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem	*flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            UIBarButtonItem	*spinner = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
            
            [toolbar setItems:[NSArray arrayWithObjects:flex1, spinner, flex2, nil]];
            self.tableView.tableHeaderView = toolbar;
            [toolbar release];
            
            [flex1 release];
            [flex2 release];
            [spinner release];
        }
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
        toolbar = nil;
        self.tableView.tableHeaderView = nil;
    }
}

#pragma mark - Properties

- (UIActivityIndicatorView *)activityIndicator {
    if (!activityIndicator) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return activityIndicator;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [skProducts release];
    [activityIndicator release];
    [super dealloc];
}

@end
