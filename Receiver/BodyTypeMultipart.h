//
//  BodyTypeMultipart.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentDisposition.h"

@interface BodyTypeMultipart : NSObject {
    
    NSString *mediaType;
    NSString *subtype;
    NSArray *parts;
    NSDictionary *param;
    ContentDisposition *disposition;
    NSArray *languages;
    NSArray *extentions;
    
}

@property (copy) NSString *mediaType;
@property (copy) NSString *subtype;
@property (copy) NSArray *parts;
@property (copy) NSDictionary *param;
@property (retain) ContentDisposition *disposition;
@property (copy) NSArray *languages;
@property (copy) NSArray *extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype parts:(NSArray *)someParts param:(NSDictionary *)aParam disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions;
- (BOOL) isMultipart;

@end