//
//  FetchData.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FetchData : NSObject {
    
    int seqno;
    NSDictionary *attr;
    
}

@property (assign) int seqno;
@property (copy) NSDictionary *attr;

@end