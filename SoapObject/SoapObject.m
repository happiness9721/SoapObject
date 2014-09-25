//
//  SoapObject.m
//  SoapObject
//
//  Created by 江承諭 on 9/24/14.
//  Copyright (c) 2014 happiness9721. All rights reserved.
//

#import "SoapObject.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "XMLReader requires ARC support."
#endif

NSString *const kXMLReaderTextNodeKey		= @"text";
NSString *const kXMLReaderAttributePrefix	= @"@";

@interface SoapObject () <NSURLConnectionDataDelegate, NSXMLParserDelegate>
{
    NSMutableData *receivedData;
    BOOL isFinished;
    BOOL isStartSaveData;
}

@property (nonatomic, strong) NSMutableArray *dictionaryStack;
@property (nonatomic, strong) NSMutableString *textInProgress;
@property (nonatomic, strong) NSError *errorPointer;

@end

@implementation SoapObject

- (id)init
{
    self = [super init];
    isFinished = YES;
    return self;
}

- (void)connectionWithDictionary:(NSDictionary *)dictionary version:(CGFloat)version;
{
    if (isFinished)
    {
        isFinished = NO;
        NSString *soapMsg = [NSString stringWithFormat:
                             @"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "<soap:Body>"
                             "<%@ xmlns=\"%@\">", self.functionName, (self.domainName ? self.domainName : @"http://tempuri.org/")];
        for (NSString *key in [dictionary allKeys])
        {
            soapMsg = [soapMsg stringByAppendingFormat:@"<%@>%@</%@>", key, [dictionary objectForKey:key], key];
        }
        soapMsg = [soapMsg stringByAppendingFormat:@"</%@>"
                   "</soap:Body>"
                   "</soap:Envelope>", self.functionName];
        
        // 创建URL，内容是前面的请求报文报文中第二行主机地址加上第一行URL字段
        NSURL *url = [NSURL URLWithString:self.url];
        // 根据上面的URL创建一个请求
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        NSString *msgLength = [NSString stringWithFormat:@"%lx", [soapMsg length]];
        // 添加请求的详细信息，与请求报文前半部分的各字段对应
        [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
        // 设置请求行方法为POST，与请求报文第一行对应
        [req setHTTPMethod:@"POST"];
        // 将SOAP消息加到请求中
        [req setHTTPBody: [soapMsg dataUsingEncoding:NSUTF8StringEncoding]];
        // 创建连接
        
        receivedData = [[NSMutableData alloc] initWithData:nil];
        [NSURLConnection connectionWithRequest:req delegate:self];
    }
    else
    {
        NSLog(@"Previous Connection not finish!");
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Clear out any old data
    self.dictionaryStack = [[NSMutableArray alloc] init];
    self.textInProgress = [[NSMutableString alloc] init];
    
    // Initialize the stack with a fresh dictionary
    [self.dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:receivedData];
    [parser setDelegate:self];
    isStartSaveData = NO;
    BOOL success = [parser parse];
    
    // Return the stack's root dictionary on success
    if (success)
    {
        NSDictionary *resultDict = [self.dictionaryStack objectAtIndex:0];
        [self didfinishLoadDictionary:resultDict];
    }
}

#pragma mark -  NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (isStartSaveData)
    {
        // Get the dictionary for the current level in the stack
        NSMutableDictionary *parentDict = [self.dictionaryStack lastObject];
        
        // Create the child dictionary for the new element, and initilaize it with the attributes
        NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
        [childDict addEntriesFromDictionary:attributeDict];
        
        // If there's already an item for this key, it means we need to create an array
        id existingValue = [parentDict objectForKey:elementName];
        if (existingValue)
        {
            NSMutableArray *array = nil;
            if ([existingValue isKindOfClass:[NSMutableArray class]])
            {
                // The array exists, so use it
                array = (NSMutableArray *) existingValue;
            }
            else
            {
                // Create an array if it doesn't exist
                array = [NSMutableArray array];
                [array addObject:existingValue];
                
                // Replace the child dictionary with an array of children dictionaries
                [parentDict setObject:array forKey:elementName];
            }
            
            // Add the new child dictionary to the array
            [array addObject:childDict];
        }
        else
        {
            // No existing value, so update the dictionary
            [parentDict setObject:childDict forKey:elementName];
        }
        
        // Update the stack
        [self.dictionaryStack addObject:childDict];
    }
    if ([elementName isEqualToString:[self.functionName stringByAppendingString:@"Response"]])
    {
        isStartSaveData = YES;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:[self.functionName stringByAppendingString:@"Response"]])
    {
        isStartSaveData = NO;
    }
    if (isStartSaveData)
    {
        // Update the parent dict with text info
        NSMutableDictionary *dictInProgress = [self.dictionaryStack lastObject];
        
        // Set the text property
        if ([self.textInProgress length] > 0)
        {
            // trim after concatenating
            NSString *trimmedString = [self.textInProgress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [dictInProgress setObject:[trimmedString mutableCopy] forKey:kXMLReaderTextNodeKey];
            
            // Reset the text
            self.textInProgress = [[NSMutableString alloc] init];
        }
        
        // Pop the current dict
        [self.dictionaryStack removeLastObject];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (isStartSaveData)
    {
        // Build the text value
        [self.textInProgress appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    // Set the error pointer to the parser's error object
    self.errorPointer = parseError;
}

//override this fuction
- (void)didfinishLoadDictionary:(NSDictionary *)dictionary
{
    [self.delegate soapObject:self didfinishLoadDictionary:dictionary];
}

@end
