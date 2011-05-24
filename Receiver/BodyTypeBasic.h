//
//  BodyTypeBasic.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentDisposition.h"

@interface BodyTypeBasic : NSObject {
    
    NSString *mediaType;
    NSString *subtype;
    NSDictionary *param;
    NSString *contentId;
    NSString *description;
    NSString *encoding;
    NSNumber *size;
    NSString *MD5;
    ContentDisposition *disposition;
    NSArray *languages;
    NSArray *extentions;
    
}

@property (copy) NSString *mediaType;
@property (copy) NSString *subtype;
@property (copy) NSDictionary *param;
@property (copy) NSString *contentId;
@property (copy) NSString *description;
@property (copy) NSString *encoding;
@property (retain) NSNumber *size;
@property (copy) NSString *MD5;
@property (retain) ContentDisposition *disposition;
@property (copy) NSArray *languages;
@property (copy) NSArray *extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype;
- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId description:(NSString *)aDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions;
- (BOOL) isMultipart;

@end