//
//  NSString+Regexp.h
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

#import <Foundation/Foundation.h>

@interface NSString (Z)

- (BOOL) containsString:(NSString *)s;
- (BOOL) startsWithString:(NSString *)s;
- (BOOL) containsChar:(char)c;
- (BOOL) endsWithString:(NSString *)s;
- (NSString *) substringBetweenDelimiters:(NSString *)del;
- (NSString *) substringStartingWithString:(NSString *)start;
- (NSString *) stringWithTrimmedWhitespaces;

@end
