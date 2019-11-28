//
//  AppDelegate.m
//  GetRequest
//
//  Created by Collin B Stuart on 2014-04-25.
//  Copyright (c) 2014 Collin B Stuart. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

void LogResponseData(CFDataRef responseData)
{
    CFIndex dataLength = CFDataGetLength(responseData);
    UInt8 *bytes = (UInt8 *)malloc(dataLength);
    CFDataGetBytes(responseData, CFRangeMake(0, CFDataGetLength(responseData)), bytes);
    CFStringRef responseString = CFStringCreateWithBytes(kCFAllocatorDefault, bytes, dataLength, kCFStringEncodingUTF8, TRUE);
    CFShow(responseString);
    CFRelease(responseString);
    free(bytes);
}

void GetRequestCallBack(CFReadStreamRef readStream, CFStreamEventType type, void *clientCallBackInfo)
{
    CFMutableDataRef responseBytes = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CFIndex numberOfBytesRead = 0;
    do
    {
        UInt8 buf[1024];
        numberOfBytesRead = CFReadStreamRead(readStream, buf, sizeof(buf));
        if (numberOfBytesRead > 0)
        {
            CFDataAppendBytes(responseBytes, buf, numberOfBytesRead);
        }
    } while (numberOfBytesRead > 0);
    
    CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertyHTTPResponseHeader);
    if (responseBytes)
    {
        if (response)
        {
            CFHTTPMessageSetBody(response, responseBytes);
        }
        CFRelease(responseBytes);
    }
    
    //close and cleanup
    CFReadStreamClose(readStream);
    CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFRelease(readStream);
    
    //print response
    if (response)
    {
        CFDataRef responseBodyData = CFHTTPMessageCopyBody(response);
        CFRelease(response);
        
        LogResponseData(responseBodyData);
        CFRelease(responseBodyData);
    }
}

void GetRequest()
{
    CFURLRef theURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("https://httpbin.org/get"), NULL);
    CFHTTPMessageRef requestMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("GET"), theURL, kCFHTTPVersion1_1);
    CFRelease(theURL);
    
    CFReadStreamRef readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, requestMessage);
    CFRelease(requestMessage);
    
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    CFOptionFlags flags = (kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered);
    CFStreamClientContext context = {0, NULL, NULL, NULL, NULL};
    CFReadStreamSetClient(readStream, flags, GetRequestCallBack, &context);
    CFReadStreamOpen(readStream);
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    GetRequest();
    
    return YES;
}

@end
