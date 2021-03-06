//
//  NhEvent.h
//  SlashEM
//
//  Created by dirk on 12/31/09.
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

#import <Foundation/Foundation.h>

@interface NhEvent : NSObject {
	
	int key;
	int mod;
	int x;
	int y;

}

@property (nonatomic, readonly) int key;
@property (nonatomic, readonly) int mod;
@property (nonatomic, readonly) int x;
@property (nonatomic, readonly) int y;
@property (nonatomic, readonly) BOOL isKeyEvent;

+ (id) eventWithKey:(int)k mod:(int)m x:(int)i y:(int)j;
+ (id) eventWithX:(int)i y:(int)j;
+ (id) eventWithKey:(int)k;

- (id) initWithKey:(int)k mod:(int)m x:(int)i y:(int)j;
- (id) initWithX:(int)i y:(int)j;
- (id) initWithKey:(int)k;

@end
