//
//  Token.h
//  Receiver
//
//  Created by Zhenyi Tan on 5/25/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Token : NSObject {
    
    int symbol;
    NSString *value;
    
}

@property (assign) int symbol;
@property (copy) NSString *value;

- (id) initWithSymbol:(int)aSymbol value:(NSString *)aValue;

@end