//
//  IMAPee.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "IMAPee.h"

@implementation IMAPee

+ (NSString *) decodeUTF7:(NSString *)aString {
    NSError *error = NULL;
    NSRegularExpression *decodeUTF7Regex = [NSRegularExpression regularExpressionWithPattern:@"&(.*?)-"
                                                                                     options:0
                                                                                       error:&error];
    NSTextCheckingResult *match = [decodeUTF7Regex firstMatchInString:aString options:0 range:NSMakeRange(0, [aString length])];
    NSString *matchedString = nil;
    if (match) {
        NSRange matchedRange = [match rangeAtIndex:1];
        if (!NSEqualRanges(matchedRange, NSMakeRange(NSNotFound, 0))) {
            matchedString = [aString substringWithRange:matchedRange];
        }
        if ([matchedString length] == 0) {
            return @"&";
        } else {
            NSString *base64 = [matchedString stringByReplacingOccurrencesOfString:@"," withString:@"/"];
            int x = [base64 length] % 4;
            if (x > 0) {
                base64 = [base64 stringByPaddingToLength:([base64 length] + 4 - x) withString:@"=" startingAtIndex:0];
            }
            NSString *decoded = [NSString stringFromBase64String:base64];
            NSString *u16tou8 = [NSString stringWithCString:[decoded cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSUTF16BigEndianStringEncoding];
            return u16tou8;
        }
    } else {
        return aString;
    }
}

+ (NSString *) encodeUTF7:(NSString *)aString {
    NSError *error = NULL;
    NSRegularExpression *encodeUTF7Regex = [NSRegularExpression regularExpressionWithPattern:@"(&)|([^\\x20-\\x25\\x27-\\x7e]+)"
                                                                                     options:0
                                                                                       error:&error];
    NSTextCheckingResult *match = [encodeUTF7Regex firstMatchInString:aString options:0 range:NSMakeRange(0, [aString length])];
    NSString *ampersand = nil;
    if (match) {
        NSRange ampersandRange = [match rangeAtIndex:1];
        if (!NSEqualRanges(ampersandRange, NSMakeRange(NSNotFound, 0))) {
            ampersand = [aString substringWithRange:ampersandRange];
        }
        if (ampersand) {
            return @"&-";
        } else {
            NSString *matchedString = [aString substringWithRange:[match range]];
            NSString *u8tou16 = [NSString stringWithCString:[matchedString cStringUsingEncoding:NSUTF16BigEndianStringEncoding]
                                                   encoding:NSUTF8StringEncoding];
            NSString *base64 = [NSString base64StringFromString:u8tou16];
            NSString *stringWithoutEquals = [base64 stringByReplacingOccurrencesOfString:@"=" withString:@""];
            NSString *stringWithoutEqualsAndNewLines = [stringWithoutEquals stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            NSString *utf7 = [stringWithoutEqualsAndNewLines stringByReplacingOccurrencesOfString:@"/" withString:@","];
            return [NSString stringWithFormat:@"&%@-", utf7];
        }
    } else {
        return aString;
    }
}

+ (NSString *) formatDate:(NSDate *)someDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MMM-yyyy"];
    NSString *formatted = [dateFormatter stringFromDate:someDate];
    [dateFormatter release];
    return formatted;
}

+ (NSString *) formatDateTime:(NSDate *)someDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MMM-yyyy HH:mm Z"];
    NSString *formatted = [dateFormatter stringFromDate:someDate];
    [dateFormatter release];
    return formatted;
}

@end