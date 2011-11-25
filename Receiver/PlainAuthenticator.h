//
//  PlainAuthenticator.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PlainAuthenticator : NSObject {
    
    NSString *user;
    NSString *password;
    
}

@property (copy) NSString *user;
@property (copy) NSString *password;

- (id) initWithUser:(NSString *)aUser password:(NSString *)aPassword;
- (NSString *) process:(NSString *)data;

@end
