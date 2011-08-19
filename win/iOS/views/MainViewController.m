//
//  MainViewController.m
//  NetHack
//
//  Created by dirk on 2/1/10.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
//

/*
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation, version 2
 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "cocos2d.h"

#import "MainViewController.h"

#import "NhYnQuestion.h"
#import "NSString+Z.h"
#import "NhEventQueue.h"
#import "NhWindow.h"
#import "NhMenuWindow.h"
#import "NhEvent.h"
#import "NhCommand.h"
#import "ActionViewController.h"
#import "InventoryViewController.h"
#import "MenuViewController.h"
#import "TextInputController.h"
#import "TextViewController.h"
#import "ExtendedCommandsController.h"
#import "NhTextInputEvent.h"
#import "MessageView.h"
#import "MapView.h"
#import "MapViewGL.h"
#import "TileSetViewController.h"
#import "ToolsViewController.h"
#import "CommandButtonItem.h"
#import "ActionBar.h"
#import "QuestionViewController.h"
#import "NhStatus.h"
#import "StatusView.h"
#import "EAGLView.h"
#import "winios.h" // ipad_getpos etc.
#include "hack.h" // BUFSZ etc.
#include "GameConfig.h"
#import "MainViewLayer.h"

static MainViewController *s_instance;

@interface MainViewController ()

@property (nonatomic, readonly) MessageView *messageView;
@property (nonatomic, readonly) StatusView *statusView;
@property (nonatomic, readonly) MainViewLayer *mainView;

@end

@implementation MainViewController

@synthesize actionBar;
@synthesize messageView;
@synthesize statusView;
@synthesize mainView;

+ (void)initialize {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								@"kRotationLockNone", kRotationLock,
								nil]];
	
	[pool drain];
}

+ (MainViewController *)instance {
	return s_instance;
}

#pragma mark - UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        s_instance = self;
    }
    return self;
}

- (void)awakeFromNib {
	[super awakeFromNib]; // responsible for viewDidLoad
    s_instance = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//
	// There are 2 ways to support auto-rotation:
	//  - The OpenGL / cocos2d way
	//     - Faster, but doesn't rotate the UIKit objects
	//  - The ViewController way
	//    - A bit slower, but the UiKit objects are placed in the right place
	//
	
#if GAME_AUTOROTATION==kGameAutorotationNone
	//
	// EAGLView won't be autorotated.
	// Since this method should return YES in at least 1 orientation, 
	// we return YES only in the Portrait orientation
	//
	return ( interfaceOrientation == UIInterfaceOrientationPortrait );
	
#elif GAME_AUTOROTATION==kGameAutorotationCCDirector
	//
	// EAGLView will be rotated by cocos2d
	//
	// Sample: Autorotate only in landscape mode
	//
	if( interfaceOrientation == UIInterfaceOrientationLandscapeLeft ) {
		[[CCDirector sharedDirector] setDeviceOrientation: kCCDeviceOrientationLandscapeRight];
	} else if( interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		[[CCDirector sharedDirector] setDeviceOrientation: kCCDeviceOrientationLandscapeLeft];
	}
	
	// Since this method should return YES in at least 1 orientation, 
	// we return YES only in the Portrait orientation
	return ( interfaceOrientation == UIInterfaceOrientationPortrait );
	
#elif GAME_AUTOROTATION == kGameAutorotationUIViewController
	//
	// EAGLView will be rotated by the UIViewController
	//
	// Sample: Autorotate only in landscpe mode
	//
	// return YES for the supported orientations
	
	return YES;
	
#else
#error Unknown value in GAME_AUTOROTATION
	
#endif // GAME_AUTOROTATION
	
	
	// Shold not happen
	return NO;
}

#if GAME_AUTOROTATION == kGameAutorotationUIViewController
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	//
	// Assuming that the main window has the size of the screen
	// BUG: This won't work if the EAGLView is not fullscreen
	///
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGRect rect = CGRectZero;
    
	
	if(toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)		
		rect = screenRect;
	
	else if(toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
		rect.size = CGSizeMake( screenRect.size.height, screenRect.size.width );
	
	CCDirector *director = [CCDirector sharedDirector];
	EAGLView *glView = [director openGLView];
	float contentScaleFactor = [director contentScaleFactor];
	
	if( contentScaleFactor != 1 ) {
		rect.size.width *= contentScaleFactor;
		rect.size.height *= contentScaleFactor;
	}
	glView.frame = rect;
}
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self clipAround];
	[self redrawMap];
	[self.messageView scrollToBottom];
}

- (void)releaseIfDefined:(id *)thing {
	if (*thing) {
		[*thing release];
		*thing = nil;
	}
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    (void) self.actionBar;
}

#pragma mark - Menus/Actions

- (void)inventoryMenuAction:(id)sender {
	[self presentModalViewController:self.inventoryNavigationController animated:YES];
}

- (void)infoMenuAction:(id)sender {
	NSArray *commands = [NSArray arrayWithObjects:
						 [NhCommand commandWithTitle:"What's here" key:':'],
						 [NhCommand commandWithTitle:"What is" key:';'],
						 [NhCommand commandWithTitle:"Discoveries" key:'\\'],
						 [NhCommand commandWithTitle:"Character Info" key:C('X')],
						 [NhCommand commandWithTitle:"Equipment" key:'*'],
						 [NhCommand commandWithTitle:"Help" key:'?'],
						 [NhCommand commandWithTitle:"Options" key:'O'],
						 [NhCommand commandWithTitle:"Toggle Autopickup" key:'@'],
						 [NhCommand commandWithTitle:"Explore mode" key:'X'],
						 [NhCommand commandWithTitle:"Call Monster" key:'C'],
						 nil];
	self.actionViewController.actions = commands;
	[self presentModalViewController:actionViewController animated:YES];
}

- (void)tilesetMenuAction:(id)sender {
	TileSetViewController *tilesetViewController = [[TileSetViewController alloc]
													initWithNibName:@"TileSetViewController" bundle:nil];
	[self presentModalViewController:tilesetViewController animated:YES];
}

- (void)toolsMenuAction:(id)sender {
	ToolsViewController *toolsViewController = [[ToolsViewController alloc]
												initWithNibName:@"ToolsViewController" bundle:nil];
	[self presentModalViewController:toolsViewController animated:YES];
}

- (void)wizardMenuAction:(id)sender {
	NSArray *commands = [NSArray arrayWithObjects:
						 [NhCommand commandWithTitle:"Magic Mapping" key:C('f')],
						 [NhCommand commandWithTitle:"Wish" key:C('w')],
						 [NhCommand commandWithTitle:"Identify" key:C('i')],
						 [NhCommand commandWithTitle:"Special Levels" key:C('o')],
						 [NhCommand commandWithTitle:"Teleport" key:C('t')],
						 [NhCommand commandWithTitle:"Level Teleport" key:C('v')],
						 [NhCommand commandWithTitle:"Create Monster" key:C('g')],
						 [NhCommand commandWithTitle:"Show Attributes" key:C('x')],
						 nil];
	self.actionViewController.actions = commands;
	[self presentModalViewController:actionViewController animated:YES];
}

- (void)moveMenuAction:(id)sender {
	NSArray *commands = [NSArray arrayWithObjects:
						 [NhCommand commandWithTitle:"Just move" key:'m'],
						 [NhCommand commandWithTitle:"Force Attack" key:'F'],
						 [NhCommand commandWithTitle:"Teleport" key:C('T')],
						 nil];
	self.actionViewController.actions = commands;
	[self presentModalViewController:actionViewController animated:YES];
}

- (IBAction)toggleMessageView:(id)sender {
	[self.messageView toggleMessageHistory:sender];
}

#pragma mark - View Controllers

- (ActionViewController *)actionViewController {
	if (!actionViewController) {
		actionViewController = [[ActionViewController alloc] initWithNibName:@"ActionViewController" bundle:nil];
	}
	return actionViewController;
}

- (InventoryViewController *)inventoryViewController {
	if (!inventoryViewController) {
		inventoryViewController = [[InventoryViewController alloc] initWithNibName:@"InventoryViewController" bundle:nil];
	}
	return inventoryViewController;
}

- (UINavigationController *)inventoryNavigationController {
	return [[[UINavigationController alloc] initWithRootViewController:self.inventoryViewController] autorelease];
}

- (MenuViewController *)menuViewController {
	if (!menuViewController) {
		menuViewController = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
	}
	return menuViewController;
}

#pragma mark - Properties

- (ActionBar *)actionBar {
    if (!actionBar) {
        actionBar = [[ActionBar alloc] initWithFrame:CGRectZero];
        actionBar.name = @"ActionBar1";

        NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:5];
        [toolbarItems addObject:[NhCommand commandWithTitle:"Wait" key:'s']];
        [toolbarItems addObject:[NhCommand commandWithTitle:"Search" keys:"9s"]];
        [toolbarItems addObject:[NhCommand commandWithTitle:"Redo" key:C('a')]];
        [toolbarItems addObject:[Action actionWithTitle:@"Inv" target:self action:@selector(inventoryMenuAction:) arg:nil]];
        [toolbarItems addObject:[NhCommand commandWithTitle:"Fire" key:'f']];
        [toolbarItems addObject:[NhCommand commandWithTitle:"Alt" key:'x']];
        [toolbarItems addObject:[NhCommand commandWithTitle:"Cast" key:'Z']];
        [toolbarItems addObject:[NhCommand commandWithTitle:"#Ext" key:'#']];
        [toolbarItems addObject:[Action actionWithTitle:@"Info" target:self action:@selector(infoMenuAction:) arg:nil]];
        [toolbarItems addObject:[Action actionWithTitle:@"Tools" target:self action:@selector(toolsMenuAction:) arg:nil]];
        [toolbarItems addObject:[Action actionWithTitle:@"Move" target:self action:@selector(moveMenuAction:) arg:nil]];
        [toolbarItems addObject:[Action actionWithTitle:@"Tiles" target:self action:@selector(tilesetMenuAction:) arg:nil]];
        
        if (wizard) { // wizard mode
            [toolbarItems addObject:[Action actionWithTitle:@"Wiz" target:self action:@selector(wizardMenuAction:)]];
        }
        
#if 0 // test
        [toolbarItems addObject:[CommandButtonItem buttonWithAction:[NhCommand commandWithTitle:"Drop" key:'D']]];
#endif
        
        [actionBar setActions:toolbarItems];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            actionBar.placement = ActionBarPlacementLeft;
        } else {
            actionBar.placement = ActionBarPlacementBottom;
        }
        
        actionBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

        [self.view addSubview:actionBar];
        [actionBar release];
        
        [actionBar layoutSubviews];

        CGRect actionFrame = actionBar.frame;

        CGRect statusFrame = self.statusView.frame;
        statusFrame.origin.y = actionFrame.origin.y - statusFrame.size.height;
        self.statusView.frame = statusFrame;
    }
    return actionBar;
}

- (MessageView *)messageView {
    if (!messageView) {
        CGFloat buttonHeight = 23;
        
        CGRect frame = self.view.bounds;
        frame.size.height = buttonHeight;
        messageView = [[MessageView alloc] initWithFrame:frame];
        messageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        messageView.backgroundColor = [UIColor blackColor];
        messageView.textColor = [UIColor whiteColor];
        messageView.alpha = .5f;
        messageView.opaque = NO;
        [self.view addSubview:messageView];
        [messageView release];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:[UIImage imageNamed:@"dropdownButton.png"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(toggleMessageView:) forControlEvents:UIControlEventTouchUpInside];
        frame = self.view.bounds;
        frame.origin.y = 0;
        frame.size.width = frame.size.height = buttonHeight;
        frame.origin.x = self.view.bounds.size.width - frame.size.width;
        button.frame = frame;
        [self.view addSubview:button];
    }
    return messageView;
}

- (StatusView *)statusView {
    if (!statusView) {
        CGRect frame = self.view.bounds;
        frame.size.height = 32.f;
        frame.origin.y = self.view.bounds.size.height - self.actionBar.bounds.size.height - frame.size.height;
        statusView = [[StatusView alloc] initWithFrame:frame];
        statusView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        statusView.contentMode = UIViewContentModeRedraw;
        statusView.clearsContextBeforeDrawing = YES;
        [self.view addSubview:statusView];
        [statusView release];
    }
    return statusView;
}

- (MainViewLayer *)mainView {
    if (!mainView) {
        mainView = [MainViewLayer sharedInstance];
    }
    return mainView;
}

#pragma mark - Window API

- (void)nhPoskey {
    [self refreshAllViews];
}

- (void)refreshAllViews {
    [self refreshMessages];
}

- (void)refreshMessages {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.statusView update];
        self.messageView.text = [[NhWindow messageWindow] textWithDelimiter:@" "];
    });
}

- (void)handleDirectionQuestion:(NhYnQuestion *)q {
	directionQuestion = YES;
}

// Parses the stuff in [] (without the brackets) and returns the special characters like $-?* etc.
// examples:
// [$abcdf or ?*]
// [a or ?*]
// [- ab or ?*]
// [- or or ?*]
// [- a or ?*]
// [- a-cw-z or ?*]
// [- a-cW-Z or ?*]
// [* or ,] // this doesn't parse correctly
- (void)parseYnChoices:(NSString *)lets specials:(NSString **)specials items:(NSString **)items {
	char cSpecials[BUFSZ];
	char cItems[BUFSZ];
	char *pSpecials = cSpecials;
	char *pItems = cItems;
	const char *pStr = [lets cStringUsingEncoding:NSASCIIStringEncoding];
	enum eState { start, inv, invInterval, end } state = start;
	char c, lastInv = 0;
	while ((c = *pStr++)) {
		switch (state) {
			case start:
				if (isalpha(c)) {
					state = inv;
					*pItems++ = c;
				} else if (!isalpha(c)) {
					if (c == ' ') {
						state = inv;
					} else {
						*pSpecials++ = c;
					}
				}
				break;
			case inv:
				if (isalpha(c)) {
					*pItems++ = c;
					lastInv = c;
				} else if (c == ' ') {
					state = end;
				} else if (c == '-') {
					state = invInterval;
				}
				break;
			case invInterval:
				if (isalpha(c)) {
					for (char a = lastInv+1; a <= c; ++a) {
						*pItems++ = a;
					}
					state = inv;
					lastInv = 0;
				} else {
					// never lands here
					state = inv;
				}
				break;
			case end:
				// this is supposed to skip 'or' at the end
				if (!isalpha(c) && c != ' ') {
					*pSpecials++ = c;
				}
				break;
			default:
				break;
		}
	}
	*pSpecials = 0;
	*pItems = 0;
	
	*specials = [NSString stringWithCString:cSpecials encoding:NSASCIIStringEncoding];
	*items = [NSString stringWithCString:cItems encoding:NSASCIIStringEncoding];
}

- (void)showYnQuestion:(NhYnQuestion *)q {
    dispatch_async(dispatch_get_main_queue(), ^ {
		if ([q.question containsString:@"direction"] ||
			[q.question containsString:@"Enter Blitz Command"]) {
			[self handleDirectionQuestion:q];
		} else if (q.choices) {
			// simple YN question
			NSString *text = q.question;
			if (text && text.length > 0) {
				if (strlen(q.choices) > 2 || [text isEqual:@"Eat it?"] ||
					[text isEqual:@"Do you want your possessions identified?"]) {
					QuestionViewController *questionViewController = [[QuestionViewController alloc]
																	  initWithNibName:@"QuestionViewController" bundle:nil];
					questionViewController.question = q;
					[questionViewController autorelease];
					[self presentModalViewController:questionViewController animated:YES];
				} else {
					currentYnQuestion = q;
					UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Question" message:q.question
																	delegate:self cancelButtonTitle:nil otherButtonTitles:nil]
										  autorelease];
					const char *pStr = q.choices;
					while (*pStr) {
						[alert addButtonWithTitle:[NSString stringWithFormat:@"%c", *pStr]];
						pStr++;
					}
					[alert show];
				}
			}
		} else {
			// no choices, could be everything
			DLog(@"no-choice question %@", q.question);
			NSString *args = [q.question substringBetweenDelimiters:@"[]"];
			
			NSString *specials = nil, *items = nil;
			[self parseYnChoices:args specials:&specials items:&items];
			
			if (specials) {
				if ([specials containsString:@"?"]) {
					[[NhEventQueue instance] addKey:'?'];
				} else {
					specials = [NSString stringWithFormat:@"%@\033", specials];
					currentYnQuestion = q;
					[currentYnQuestion overrideChoices:specials];
					QuestionViewController *questionViewController = [[QuestionViewController alloc]
																	  initWithNibName:@"QuestionViewController" bundle:nil];
					questionViewController.question = q;
					[questionViewController autorelease];
					[self presentModalViewController:questionViewController animated:YES];
				}
			} else {
				DLog(@"giving up on question %@", q.question);
			}
		}
	});
}

- (void)displayText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^ {
		TextViewController *textViewController = [[[TextViewController alloc]
												   initWithNibName:@"TextViewController" bundle:nil] autorelease];
		textViewController.text = text;
		textViewController.blocking = YES;
		[self presentModalViewController:textViewController animated:YES];
	});
}

- (void)updateTileSet {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.mainView updateTileSet];
        [self redrawMap];
    });
}

- (void)redrawMap {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.mainView drawFrame];
    });
}

- (void)displayWindow:(NhWindow *)w {
    dispatch_async(dispatch_get_main_queue(), ^ {
		if (w == [NhWindow messageWindow]) {
			[self refreshMessages];
		} else if (w.type == NHW_MAP) {
            [self redrawMap];
			if (w.blocking) {
				//todo (though it seems to work)
			}
		} else if (w.type == NHW_MESSAGE || w.type == NHW_MENU || w.type == NHW_TEXT) {
			// display text
			[self displayText:w.text];
		}
    });

    if (w.blocking && w != [NhWindow messageWindow]) {
        // ignore blocking main message window
        [[NhEventQueue instance] nextEvent];
    }
}

- (void)showMenuWindow:(NhMenuWindow *)w {
    dispatch_async(dispatch_get_main_queue(), ^ {
		self.menuViewController.menuWindow = w;
		[self presentModalViewController:menuViewController animated:YES];
	});
}

- (void)clipAround {
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.mainView clipAroundX:clipX y:clipY];
    });
}

- (void)clipAroundX:(int)x y:(int)y {
	clipX = x;
	clipY = y;
    [self clipAround];
}

- (void)updateInventory {
    dispatch_async(dispatch_get_main_queue(), ^ {
		if (inventoryViewController) {
			[self.inventoryViewController updateInventory];
		}
	});
}

- (void)getLine {
    dispatch_async(dispatch_get_main_queue(), ^ {
		TextInputController *textInputController = [[TextInputController alloc]
													initWithNibName:@"TextInputController" bundle:nil];
		[self presentModalViewController:textInputController animated:YES];
		[textInputController release];
	});
}

- (void)showExtendedCommands {
    dispatch_async(dispatch_get_main_queue(), ^ {
		ExtendedCommandsController *extendedCommandsController = [[ExtendedCommandsController alloc]
																  initWithNibName:@"ExtendedCommandsController" bundle:nil];
		[self presentModalViewController:extendedCommandsController animated:YES];
		[extendedCommandsController release];
	});
}

#pragma mark - Touch Handling

- (int)keyFromDirection:(e_direction)d {
	static char keys[] = "kulnjbhy\033";
	return keys[d];
}

- (BOOL)isMovementKey:(char)k {
	if (isalpha(k)) {
		static char directionKeys[] = "kulnjbhy";
		char *pStr = directionKeys;
		char c;
		while ((c = *pStr++)) {
			if (c == k) {
				return YES;
			}
		}
	}
	return NO;
}

- (e_direction)directionFromKey:(char)k {
	switch (k) {
		case 'k':
			return kDirectionUp;
		case 'u':
			return kDirectionUpRight;
		case 'l':
			return kDirectionRight;
		case 'n':
			return kDirectionDownRight;
		case 'j':
			return kDirectionDown;
		case 'b':
			return kDirectionDownLeft;
		case 'h':
			return kDirectionLeft;
		case 'y':
			return kDirectionUpLeft;
	}
	return kDirectionMax;
}

- (void)endDirectionQuestion {
	directionQuestion = NO;
}

- (void)handleMapTapTileX:(int)x y:(int)y forLocation:(CGPoint)p inView:(UIView *)view {
	//DLog(@"tap on %d,%d (u %d,%d)", x, y, u.ux, u.uy);
	if (directionQuestion) {
		if (u.ux == x && u.uy == y) {
			// tap on self
			NSArray *commands = [NhCommand directionCommands];
			for (Action *action in commands) {
				[action addTarget:self action:@selector(endDirectionQuestion) arg:nil];
			}
			self.actionViewController.actions = commands;
			// show direction commands
			[self presentModalViewController:actionViewController animated:YES];
		} else {
			directionQuestion = NO;
			CGPoint delta = CGPointMake(x*32.0f-u.ux*32.0f, y*32.0f-u.uy*32.0f);
			delta.y *= -1;
			//DLog(@"delta %3.2f,%3.2f", delta.x, delta.y);
			e_direction direction = [ZDirection directionFromEuclideanPointDelta:&delta];
			int key = [self keyFromDirection:direction];
			//DLog(@"key %c", key);
			[[NhEventQueue instance] addKey:key];
		}
	} else if (!ios_getpos) {
		if (u.ux == x && u.uy == y) {
			// tap on self
			NSArray *commands = [NhCommand allCurrentCommands];
			self.actionViewController.actions = commands;
			[self presentModalViewController:actionViewController animated:YES];
		} else {
			coord delta = CoordMake(u.ux-x, u.uy-y);
			if (abs(delta.x) <= 1 && abs(delta.y) <= 1 ) {
				// tap on adjacent tile
				NSArray *commands = [NhCommand allCommandsForAdjacentTile:CoordMake(x, y)];
				if (commands.count > 0) {
					self.actionViewController.actions = commands;
					[self presentModalViewController:actionViewController animated:YES];
				} else {
					// movement
					[[NhEventQueue instance] addEvent:[NhEvent eventWithX:x y:y]];
				}
			} else {
				// travel
				[[NhEventQueue instance] addEvent:[NhEvent eventWithX:x y:y]];
			}
		}
	} else {
		[[NhEventQueue instance] addEvent:[NhEvent eventWithX:x y:y]];
	}
}

- (void)handleDirectionTap:(e_direction)direction {
	if (!ios_getpos) {
		if (directionQuestion) {
			directionQuestion = NO;
			int key = [self keyFromDirection:direction];
			[[NhEventQueue instance] addKey:key];
		} else {
			coord tp = CoordMake(u.ux, u.uy);
			switch (direction) {
				case kDirectionLeft:
					tp.x--;
					break;
				case kDirectionUpLeft:
					tp.x--;
					tp.y--;
					break;
				case kDirectionUp:
					tp.y--;
					break;
				case kDirectionUpRight:
					tp.x++;
					tp.y--;
					break;
				case kDirectionRight:
					tp.x++;
					break;
				case kDirectionDownRight:
					tp.x++;
					tp.y++;
					break;
				case kDirectionDownLeft:
					tp.x--;
					tp.y++;
					break;
				case kDirectionDown:
					tp.y++;
					break;
                case kDirectionMax:
                    break;
			}
			int key = [self keyFromDirection:direction];
			if (IS_DOOR(levl[tp.x][tp.y].typ)) {
				char cmd[3] = { ' ', key, '\0' };
				int mask = levl[tp.x][tp.y].doormask;
				if (mask & D_CLOSED) {
					cmd[0] = 'o';
					[[NhEventQueue instance] addKeys:cmd];
				} else if (mask & D_LOCKED) {
					NSArray *commands = [NhCommand allCommandsForAdjacentTile:tp];
					if (commands.count > 0) {
						self.actionViewController.actions = commands;
						[self presentModalViewController:actionViewController animated:YES];
					}
				} else {
					[[NhEventQueue instance] addKey:key];
				}
			} else {
				[[NhEventQueue instance] addKey:key];
			}
		}
	}
}

- (void)handleDirectionDoubleTap:(e_direction)direction {
	if (!ios_getpos) {
		int key = [self keyFromDirection:direction];
		[[NhEventQueue instance] addKey:'g'];
		[[NhEventQueue instance] addKey:key];
		directionQuestion = NO;
	}
}

#pragma mark - Utility

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.numberOfButtons > 1) {
		char c = currentYnQuestion.choices[buttonIndex];
		[[NhEventQueue instance] addKey:c];
		currentYnQuestion = nil;
	} else {
		// add no-event
		[[NhEventQueue instance] addKey:-1];
	}
}

#pragma mark - Memory

- (void)dealloc {
    [super dealloc];
}

@end
