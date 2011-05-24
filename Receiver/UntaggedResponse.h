//
//  UntaggedResponse.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UntaggedResponse : NSObject {
    
    NSString *name;
    id data;
    NSString *rawData;
    
}

@property (copy) NSString *name;
@property (retain) id data;
@property (copy) NSString *rawData;

@end