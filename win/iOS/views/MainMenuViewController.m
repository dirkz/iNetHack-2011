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
#import "BlockAction.h"

@interface MainMenuViewController ()

@property (nonatomic, readonly) UIActivityIndicatorView *activityIndicator;

- (void)setActivity:(BOOL)active;

@end

@implementation MainMenuViewController

@synthesize activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.title = @"Main Menu";
        
        sections = [[NSMutableArray alloc] init];
        
        NSArray *fixedActions = [NSArray arrayWithObjects:[BlockAction actionWithTitle:@"Tilesets" actionBlock:^(Action *action) {
            TileSetViewController *vc = [[TileSetViewController alloc] initWithNibName:@"TileSetViewController" bundle:nil];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
        }], nil];
        [sections addObject:fixedActions];
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

    if (!request) {
        request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:@"BuyAWish", nil]];
        request.delegate = self;
        [self setActivity:YES];
        [request start];
    }
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
    return sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[sections objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSArray *rows = [sections objectAtIndex:indexPath.section];
    Action *action = [rows objectAtIndex:indexPath.row];
    cell.textLabel.text = action.title;
    if (action.description) {
        cell.detailTextLabel.text = action.description;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

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
    NSMutableArray *products = [[NSMutableArray alloc] initWithCapacity:response.products.count];
    for (SKProduct *product in response.products) {
        BlockAction *action = [[BlockAction alloc] initWithTitle:product.localizedTitle actionBlock:^(Action *a) {
            DLog(@"buy %@", a.context);
            [self.navigationController dismissModalViewControllerAnimated:YES];
        }];
        action.description = product.localizedDescription;
        action.context = product;
        [products addObject:action];
    }
    
    [sections addObject:products];
    [products release];
    [self.tableView reloadData];

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
    NSArray *rows = [sections objectAtIndex:indexPath.section];
    Action *action = [rows objectAtIndex:indexPath.row];
    [action invoke:self];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor darkGrayColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    tableView.backgroundColor = [UIColor darkGrayColor];
}

#pragma mark - Helpers

- (void)setActivity:(BOOL)active {
    if (active) {
        if (!self.navigationItem.rightBarButtonItem) {
            [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator] animated:YES];
            [self.navigationItem.rightBarButtonItem release];
            NSAssert(self.navigationItem.rightBarButtonItem, @"self.navigationController.navigationItem.rightBarButtonItem should exist now");
        }
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
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
    [activityIndicator release];
    [request release];
    [super dealloc];
}

@end
