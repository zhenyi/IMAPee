//
//  BodyTypeText.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "BodyTypeText.h"

@implementation BodyTypeText

@synthesize mediaType;
@synthesize subtype;
@synthesize param;
@synthesize contentId;
@synthesize description;
@synthesize encoding;
@synthesize size;
@synthesize lines;
@synthesize MD5;
@synthesize disposition;
@synthesize languages;
@synthesize extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId description:(NSString *)aDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize lines:(NSNumber *)aLine MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions {
    if ((self = [super init])) {
        self.mediaType = aMediaType;
        self.subtype = aSubtype;
        self.param = aParam;
        self.contentId = aContentId;
        self.description = aDescription;
        self.encoding = anEncoding;
        self.size = aSize;
        self.lines = aLine;
        self.MD5 = aMD5;
        self.disposition = aDisposition;
        self.languages = someLanguages;
        self.extentions = someExtentions;
    }
    return self;
}

- (BOOL) isMultipart {
    return NO;
}

@end