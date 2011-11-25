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

- (void) dealloc {
    [mediaType release];
    [subtype release];
    [parts release];
    [param release];
    [disposition release];
    [languages release];
    [extentions release];
    [super dealloc];
}

- (BOOL) isMultipart {
    return YES;
}

- (NSString *) description {
    NSMutableString *partDescription = [NSMutableString string];
    for (id part in self.parts) {
        [partDescription appendString:[NSString stringWithFormat:@"%@\n\n", [part description]]];
    }
    return [NSString stringWithFormat:@"BodyTypeMultipart:\nmediaType=%@\nsubtype=%@\nparam=%@\ndisposition=%@\nlanguages=%@\nextentions=%@\n\nparts=%@", self.mediaType, self.subtype, self.param, self.disposition, self.languages, self.extentions, partDescription];
}

@end