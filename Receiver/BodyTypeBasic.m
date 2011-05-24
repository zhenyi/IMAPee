//
//  BodyTypeBasic.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "BodyTypeBasic.h"

@implementation BodyTypeBasic

@synthesize mediaType;
@synthesize subtype;
@synthesize param;
@synthesize contentId;
@synthesize description;
@synthesize encoding;
@synthesize size;
@synthesize MD5;
@synthesize disposition;
@synthesize languages;
@synthesize extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId description:(NSString *)aDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions {
    if ((self = [super init])) {
        self.mediaType = aMediaType;
        self.subtype = aSubtype;
        self.param = aParam;
        self.contentId = aContentId;
        self.description = aDescription;
        self.encoding = anEncoding;
        self.size = aSize;
        self.MD5 = aMD5;
        self.disposition = aDisposition;
        self.languages = someLanguages;
        self.extentions = someExtentions;
    }
    return self;
}

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype {
    return [self initWithMediaType:aMediaType subtype:aSubtype param:nil contentId:nil description:nil encoding:nil size:nil MD5:nil disposition:nil languages:nil extentions:nil];
}

- (BOOL) isMultipart {
    return NO;
}

@end