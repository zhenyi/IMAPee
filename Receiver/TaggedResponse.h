//
//  TaggedResponse.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseText.h"

@interface TaggedResponse : NSObject {
    
    NSString *tag;
    NSString *name;
    ResponseText *data;
    NSString *rawData;
    
}

@property (copy) NSString *tag;
@property (copy) NSString *name;
@property (retain) ResponseText *data;
@property (copy) NSString *rawData;

@end