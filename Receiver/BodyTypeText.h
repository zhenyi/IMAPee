//
//  BodyTypeText.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentDisposition.h"

@interface BodyTypeText : NSObject {
    
    NSString *mediaType;
    NSString *subtype;
    NSDictionary *param;
    NSString *contentId;
    NSString *contentDescription;
    NSString *encoding;
    NSNumber *size;
    NSNumber *lines;
    NSString *MD5;
    ContentDisposition *disposition;
    NSArray *languages;
    NSArray *extentions;
    
}

@property (copy) NSString *mediaType;
@property (copy) NSString *subtype;
@property (copy) NSDictionary *param;
@property (copy) NSString *contentId;
@property (copy) NSString *contentDescription;
@property (copy) NSString *encoding;
@property (retain) NSNumber *size;
@property (retain) NSNumber *lines;
@property (copy) NSString *MD5;
@property (retain) ContentDisposition *disposition;
@property (copy) NSArray *languages;
@property (copy) NSArray *extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId contentDescription:(NSString *)aContentDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize lines:(NSNumber *)aLine MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions;
- (BOOL) isMultipart;

@end