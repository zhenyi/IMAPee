//
//  NSStream+Additions.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/23/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "NSStream+Additions.h"

@implementation NSStream (StreamsToHost)

+ (void) getStreamsToHostNamed:(NSString *)hostName 
                          port:(NSInteger)port 
                   inputStream:(NSInputStream **)inputStreamPtr 
                  outputStream:(NSOutputStream **)outputStreamPtr {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
	readStream = NULL;
    writeStream = NULL;
	
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) hostName, port,
                                       ((inputStreamPtr  != nil) ? &readStream : NULL),
                                       ((outputStreamPtr != nil) ? &writeStream : NULL));
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = [NSMakeCollectable(readStream) autorelease];
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = [NSMakeCollectable(writeStream) autorelease];
    }
}

@end