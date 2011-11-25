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
@synthesize contentDescription;
@synthesize encoding;
@synthesize size;
@synthesize lines;
@synthesize MD5;
@synthesize disposition;
@synthesize languages;
@synthesize extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype param:(NSDictionary *)aParam contentId:(NSString *)aContentId contentDescription:(NSString *)aContentDescription encoding:(NSString *)anEncoding size:(NSNumber *)aSize lines:(NSNumber *)aLine MD5:(NSString *)aMD5 disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions {
    if ((self = [super init])) {
        self.mediaType = aMediaType;
        self.subtype = aSubtype;
        self.param = aParam;
        self.contentId = aContentId;
        self.contentDescription = aContentDescription;
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

- (void) dealloc {
    [mediaType release];
    [subtype release];
    [param release];
    [contentId release];
    [contentDescription release];
    [encoding release];
    [size release];
    [lines release];
    [MD5 release];
    [disposition release];
    [languages release];
    [extentions release];
    [super dealloc];
}

- (BOOL) isMultipart {
    return NO;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"BodyTypeText:\nmediaType=%@\nsubtype=%@\nparam=%@\ncontentId=%@\ncontentDescription=%@\nencoding=%@\nsize=%@\nlines=%@\nMD5=%@\ndisposition=%@\nlanguages=%@\nextentions=%@", self.mediaType, self.subtype, self.param, self.contentId, self.contentDescription, self.encoding, self.size, self.lines, self.MD5, self.disposition, self.languages, self.extentions];
}

@end