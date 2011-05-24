//
//  MailboxList.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailboxList : NSObject {
    
    NSArray *attr;
    NSString *delim;
    NSString *name;
    
}

@property (copy) NSArray *attr;
@property (copy) NSString *delim;
@property (copy) NSString *name;

@end