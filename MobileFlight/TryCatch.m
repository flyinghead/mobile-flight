//
//  TryCatch.m
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 07/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#import "TryCatch.h"

@implementation TryCatch

+ (BOOL)tryBlock:(void (^)())tryBlock
           error:(NSError **)error
{
    @try {
        tryBlock ? tryBlock(error) : NO;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.flyinghead"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: exception.name}];
        }
        return NO;
    }
    return YES;
}

@end
