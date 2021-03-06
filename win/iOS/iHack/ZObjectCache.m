//
//  ZObjectCache.m
//  SlashEM
//
//  Created by dirk on 1/20/10.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
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

#import "ZObjectCache.h"

@implementation ZObjectCache

- (id)init {
	if (self = [super init]) {
		cache = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)setObject:(id)anObject forKey:(id)aKey {
	NSValue *vKey = [NSValue valueWithPointer:aKey];
	[cache setObject:anObject forKey:vKey];
}

- (id)objectForKey:(id)aKey {
	NSValue *vKey = [NSValue valueWithPointer:aKey];
	return [cache objectForKey:vKey];
}

- (void)removeAllObjects {
	[cache removeAllObjects];
}

- (NSUInteger)count {
	return cache.count;
}

- (NSEnumerator *)keyEnumerator {
	return cache.keyEnumerator;
}

- (void)dealloc {
	[cache release];
	[super dealloc];
}

@end
