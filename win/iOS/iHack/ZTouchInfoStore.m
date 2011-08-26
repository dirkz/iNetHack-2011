//
//  TouchInfoStore.m
//  SlashEM
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

//
// iNetHack
// Copyright (C) 2011  Dirk Zimmermann (me AT dirkz DOT com)
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//

#import "ZTouchInfoStore.h"
#import "ZTouchInfo.h"

@implementation ZTouchInfoStore

@synthesize singleTapTimestamp;

- (id)init {
	if (self = [super init]) {
		currentTouchInfos = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (int) count {
	return currentTouchInfos.count;
}

- (void)storeTouches:(NSSet *)touches {
	for (UITouch *t in touches) {
		ZTouchInfo *ti = [[ZTouchInfo alloc] initWithTouch:t];
		NSValue *k = [NSValue valueWithPointer:t];
		[currentTouchInfos setObject:ti forKey:k];
		[ti release];
	}
}

- (ZTouchInfo *)touchInfoForTouch:(UITouch *)t {
	NSValue *k = [NSValue valueWithPointer:t];
	ZTouchInfo *ti = [currentTouchInfos objectForKey:k];
	return ti;
}

- (void)removeTouches:(NSSet *)touches {
	for (UITouch *t in touches) {
		NSValue *k = [NSValue valueWithPointer:t];
		[currentTouchInfos removeObjectForKey:k];
	}
}

- (void)dealloc {
	[currentTouchInfos release];
	[super dealloc];
}

@end
