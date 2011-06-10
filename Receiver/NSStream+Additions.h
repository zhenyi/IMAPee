//
//  NSStream+Additions.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/23/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream (StreamsToHost)

+ (void) getStreamsToHostNamed:(NSString *)hostName
                          port:(NSInteger)port
                   inputStream:(NSInputStream **)inputStreamPtr
                  outputStream:(NSOutputStream **)outputStreamPtr;

@end