//
//  NSMutableURLRequest+Spark.h
//  Sous Vide
//
//  Created by Soemarko Ridwan on 3/15/15.
//  Copyright (c) 2015 Soemarko Ridwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (Spark)

+ (NSMutableURLRequest *)requestWithURL:(NSURL *)URL username:(NSString *)username password:(NSString *)password;
+ (NSMutableURLRequest *)requestWithURLString:(NSString *)URLString username:(NSString *)username password:(NSString *)password;

+ (NSMutableURLRequest *)requestWithURL:(NSURL *)URL accessToken:(NSString *)token;
+ (NSMutableURLRequest *)requestWithURLString:(NSString *)URLString accessToken:(NSString *)token;

@end
