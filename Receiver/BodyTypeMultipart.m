//
//  BodyTypeMultipart.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "BodyTypeMultipart.h"

@implementation BodyTypeMultipart

@synthesize mediaType;
@synthesize subtype;
@synthesize parts;
@synthesize param;
@synthesize disposition;
@synthesize languages;
@synthesize extentions;

- (id) initWithMediaType:(NSString *)aMediaType subtype:(NSString *)aSubtype parts:(NSArray *)someParts param:(NSDictionary *)aParam disposition:(ContentDisposition *)aDisposition languages:(NSArray *)someLanguages extentions:(NSArray *)someExtentions {
    if ((self = [super init])) {
        self.mediaType = aMediaType;
        self.subtype = aSubtype;
        self.parts = someParts;
        self.param = aParam;
        self.disposition = aDisposition;
        self.languages = someLanguages;
        self.extentions = someExtentions;
    }
    return self;
}

- (BOOL) isMultipart {
    return YES;
}

@end