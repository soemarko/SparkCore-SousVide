//
//  NSMutableURLRequest+Spark.m
//  Sous Vide
//
//  Created by Soemarko Ridwan on 3/15/15.
//  Copyright (c) 2015 Soemarko Ridwan. All rights reserved.
//

#import "NSMutableURLRequest+Spark.h"

@implementation NSMutableURLRequest (Spark)

+ (NSMutableURLRequest *)requestWithURL:(NSURL *)URL username:(NSString *)username password:(NSString *)password {

	NSString *loginString = [NSString stringWithFormat:@"%@:%@", username, password];
	NSData *loginData = [loginString dataUsingEncoding:NSUTF8StringEncoding];
	NSString *authHeader = [@"Basic " stringByAppendingString:[loginData base64EncodedStringWithOptions:kNilOptions]];

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];
	return request;
}

+ (NSMutableURLRequest *)requestWithURLString:(NSString *)URLString username:(NSString *)username password:(NSString *)password {
	return [self requestWithURL:[NSURL URLWithString:URLString] username:username password:password];
}

+ (NSMutableURLRequest *)requestWithURL:(NSURL *)URL accessToken:(NSString *)token {

	NSString *authHeader = [@"Bearer " stringByAppendingString:token];

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setValue:authHeader forHTTPHeaderField:@"Authorization"];
	[request setValue:@"Feeds (http://feedsapp.com)" forHTTPHeaderField:@"User-Agent"]; // basecamp wants this for instance
	return request;
}

+ (NSMutableURLRequest *)requestWithURLString:(NSString *)URLString accessToken:(NSString *)token {
	return [self requestWithURL:[NSURL URLWithString:URLString] accessToken:token];
}

@end
