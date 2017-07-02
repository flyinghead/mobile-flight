//
//  TryCatch.m
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

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