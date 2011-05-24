//
//  LoginAuthenticator.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginAuthenticator : NSObject {
    
    NSString *user;
    NSString *password;
    int state;
    
}

@property (copy) NSString *user;
@property (copy) NSString *password;
@property (assign) int state;

- (id) initWithUser:(NSString *)aUser password:(NSString *)aPassword;
- (NSString *) process:(NSString *)data;

@end
