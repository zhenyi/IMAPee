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
@synthesize contentDescription;
@synthesize encoding;
@synthesize size;
@synthesize MD5;
@synthesize disposition;
@synthesize languages;
@synthesize extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId contentDescription:(NSString *)aContentDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions {
    if ((self = [super init])) {
        self.mediaType = aMediaType;
        self.subtype = aSubtype;
        self.param = aParam;
        self.contentId = aContentId;
        self.contentDescription = aContentDescription;
        self.encoding = anEncoding;
        self.size = aSize;
        self.MD5 = aMD5;
        self.disposition = aDisposition;
        self.languages = someLanguages;
        self.extentions = someExtentions;
    }
    return self;
}

- (void) dealloc {
    [mediaType release];
    [subtype release];
    [param release];
    [contentId release];
    [contentDescription release];
    [encoding release];
    [size release];
    [MD5 release];
    [disposition release];
    [languages release];
    [extentions release];
    [super dealloc];
}

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype {
    return [self initWithMediaType:aMediaType subtype:aSubtype param:nil contentId:nil contentDescription:nil encoding:nil size:nil MD5:nil disposition:nil languages:nil extentions:nil];
}

- (BOOL) isMultipart {
    return NO;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"BodyTypeBasic:\nmediaType=%@\nsubtype=%@\nparam=%@\ncontentId=%@\ncontentDescription=%@\nencoding=%@\nsize=%@\nMD5=%@\ndisposition=%@\nlanguages=%@\nextentions=%@", self.mediaType, self.subtype, self.param, self.contentId, self.contentDescription, self.encoding, self.size, self.MD5, self.disposition, self.languages, self.extentions];
}

@end