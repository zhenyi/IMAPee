//
//  StatusData.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatusData : NSObject {
    
    NSString *mailbox;
    NSDictionary *attr;
    
}

@property (copy) NSString *mailbox;
@property (copy) NSDictionary *attr;

@end