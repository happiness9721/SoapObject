//
//  SoapObject.h
//  SoapObject
//
//  Created by 江承諭 on 9/24/14.
//  Copyright (c) 2014 happiness9721. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SoapObject;
@protocol SoapObjectDelegate <NSObject>

@optional
- (void)soapObject:(SoapObject *)soapObject didfinishLoadDictionary:(NSDictionary *)dictionary;

@end

@interface SoapObject : NSObject

@property NSString *url;
@property NSString *functionName;
@property NSString *domainName;
@property NSDictionary *parameterDictionary;
@property NSUInteger tag;
@property (weak) id<SoapObjectDelegate> delegate;

- (void)connectionWithVersion:(CGFloat)version;

@end