//
//  TryCatch.h
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

#ifndef TryCatch_h
#define TryCatch_h

#import <Foundation/Foundation.h>

@interface TryCatch : NSObject

+ (BOOL)tryBlock:(void (^)())tryBlock error:(NSError **)error;

@end

#endif /* TryCatch_h */
