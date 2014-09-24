//
//  SoapObject.m
//  SoapObject
//
//  Created by 江承諭 on 9/24/14.
//  Copyright (c) 2014 happiness9721. All rights reserved.
//

#import "SoapObject.h"

@interface SoapObject () <NSURLConnectionDataDelegate, NSXMLParserDelegate>
{
    NSMutableData *receivedData;
    NSXMLParser *parser;
    NSString *parserCurrent;
    NSString *parserCharacters;
    NSMutableArray *parserArray;
    BOOL isFinished;
    BOOL isStartSaveData;
}

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
    isStartSaveData = NO;
    parserArray = [[NSMutableArray alloc] init];
    //NSXMLParser init
    parser = [[NSXMLParser alloc] initWithData:receivedData];
    //設定Delegate
    [parser setDelegate:self];
    //開始parser
    [parser parse];
}

//parser <XXXX>
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (isStartSaveData)
    {
        parserCurrent = elementName;
        parserCharacters = @"";
    }
    if ([elementName isEqualToString:[self.functionName stringByAppendingString:@"Response"]])
    {
        isStartSaveData = YES;
    }
}

//parser <>XXXXXX
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (parserCurrent.length)
    {
        parserCharacters = [parserCharacters stringByAppendingString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (parserCurrent.length)
    {
        NSDictionary *dictionary = @{ parserCurrent: parserCharacters};
        [parserArray addObject:dictionary];
        parserCurrent = @"";
    }
}

//parser結束
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [self didfinishLoadArray:parserArray];
}

//override this fuction
- (void)didfinishLoadArray:(NSArray *)array
{
    [self.delegate soapObject:self didfinishLoadArray:array];
}

@end
