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
- (void)soapObject:(SoapObject *)soapObject didfinishLoadArray:(NSArray *)array;

@end

@interface SoapObject : NSObject

@property NSString *url;
@property NSString *functionName;
@property NSString *domainName;
@property (weak) id<SoapObjectDelegate> delegate;

- (void)connectionWithDictionary:(NSDictionary *)dictionary version:(CGFloat)version;
//customize your function by override this function
- (void)didfinishLoadArray:(NSArray *)array;

@end