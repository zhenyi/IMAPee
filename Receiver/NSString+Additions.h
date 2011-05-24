//
//  NSString+Additions.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (EncodeDecode)

+ (NSString *) base64StringFromString:(NSString *)string;
+ (NSString *) stringFromBase64String:(NSString *)string;
- (NSString *) MD5Digest;
- (NSString *) MD5HexDigest;

@end