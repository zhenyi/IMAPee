//
//  BodyTypeMessage.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "BodyTypeMessage.h"

@implementation BodyTypeMessage

@synthesize mediaType;
@synthesize subtype;
@synthesize param;
@synthesize contentId;
@synthesize description;
@synthesize encoding;
@synthesize size;
@synthesize envelope;
@synthesize body;
@synthesize lines;
@synthesize MD5;
@synthesize disposition;
@synthesize languages;
@synthesize extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId description:(NSString *)aDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize envelope:(Envelope *)anEnvelope body:(id)aBody lines:(NSNumber *)aLine MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions {
    if ((self = [super init])) {
        self.mediaType = aMediaType;
        self.subtype = aSubtype;
        self.param = aParam;
        self.contentId = aContentId;
        self.description = aDescription;
        self.encoding = anEncoding;
        self.size = aSize;
        self.envelope = anEnvelope;
        self.body = aBody;
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