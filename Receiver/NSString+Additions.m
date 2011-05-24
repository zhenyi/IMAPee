//
//  NSString+Additions.m
//  Receiver
//
//  Created by Zhenyi Tan on 5/24/11.
//  Copyright 2011 And a Dinosaur. All rights reserved.
//

#import "NSString+Additions.h"

static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

@implementation NSString (EncodeDecode)

+ (NSString *) base64StringFromString:(NSString *)string {
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    int lentext = [data length];
    if (lentext < 1) return @"";
    char *outbuf = malloc(lentext*4 / 3+4);
    if (!outbuf) return nil;
    const unsigned char *raw = [data bytes];
    int inp = 0;
    int outp = 0;
    int do_now = lentext - (lentext % 3);
    
    for (outp = 0, inp = 0; inp < do_now; inp += 3) {
        outbuf[outp++] = base64EncodingTable[(raw[inp] & 0xFC) >> 2];
        outbuf[outp++] = base64EncodingTable[((raw[inp] & 0x03) << 4) | ((raw[inp+1] & 0xF0) >> 4)];
        outbuf[outp++] = base64EncodingTable[((raw[inp+1] & 0x0F) << 2) | ((raw[inp+2] & 0xC0) >> 6)];
        outbuf[outp++] = base64EncodingTable[raw[inp+2] & 0x3F];
    }
    
    if (do_now < lentext) {
        unsigned char tmpbuf[3] = {0, 0, 0};
        int left = lentext % 3;
        for (int i = 0; i < left; i++) {
            tmpbuf[i] = raw[do_now+i];
        }
        raw = tmpbuf;
        inp = 0;
        outbuf[outp++] = base64EncodingTable[(raw[inp] & 0xFC) >> 2];
        outbuf[outp++] = base64EncodingTable[((raw[inp] & 0x03) << 4) | ((raw[inp+1] & 0xF0) >> 4)];
        if (left == 2) {
            outbuf[outp++] = base64EncodingTable[((raw[inp+1] & 0x0F) << 2) | ((raw[inp+2] & 0xC0) >> 6)];
        } else {
            outbuf[outp++] = '=';
        }
        outbuf[outp++] = '=';
    }
    
    NSString *ret = [[[NSString alloc] initWithBytes:outbuf length:outp encoding:NSASCIIStringEncoding] autorelease];
    free(outbuf);
    return ret;
}

+ (NSString *) stringFromBase64String:(NSString *)string {
    unsigned long ixtext, lentext;
    unsigned char ch, input[4], output[3];
    short i, ixinput;
    Boolean flignore, flendtext = false;
    const char *temporary;
    NSMutableData *result;
    if (!string) {
        return @"";
    }
    ixtext = 0;
    temporary = [string UTF8String];
    lentext = [string length];
    result = [NSMutableData dataWithCapacity: lentext];
    ixinput = 0;
    while (true) {
        if (ixtext >= lentext) {
            break;
        }
        ch = temporary[ixtext++];
        flignore = false;
        if ((ch >= 'A') && (ch <= 'Z')) {
            ch = ch - 'A';
        } else if ((ch >= 'a') && (ch <= 'z')) {
            ch = ch - 'a' + 26;
        } else if ((ch >= '0') && (ch <= '9')) {
            ch = ch - '0' + 52;
        } else if (ch == '+') {
            ch = 62;
        } else if (ch == '=') {
            flendtext = true;
        } else if (ch == '/') {
            ch = 63;
        } else {
            flignore = true;
        }
        if (!flignore) {
            short ctcharsinput = 3;
            Boolean flbreak = false;
            if (flendtext) {
                if (ixinput == 0) {
                    break;              
                }
                if ((ixinput == 1) || (ixinput == 2)) {
                    ctcharsinput = 1;
                } else {
                    ctcharsinput = 2;
                }
                ixinput = 3;
                flbreak = true;
            }
            input[ixinput++] = ch;
            if (ixinput == 4) {
                ixinput = 0;
                output[0] = (input[0] << 2) | ((input[1] & 0x30) >> 4);
                output[1] = ((input[1] & 0x0F) << 4) | ((input[2] & 0x3C) >> 2);
                output[2] = ((input[2] & 0x03) << 6) | (input[3] & 0x3F);
                for (i = 0; i < ctcharsinput; i++) {
                    [result appendBytes: &output[i] length: 1];
                }
            }
            if (flbreak) {
                break;
            }
        }
    }
    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
}

- (NSString *) MD5Digest {
    const char *str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%c", result[i]];
    }
    return ret;
}

- (NSString *) MD5HexDigest {
    const char *str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}

@end