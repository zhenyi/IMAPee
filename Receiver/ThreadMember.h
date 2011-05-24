//
//  ThreadMember.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThreadMember : NSObject {
    
    int seqno;
    NSMutableArray *children;
    
}

@property (assign) int seqno;
@property (retain) NSMutableArray *children;

@end