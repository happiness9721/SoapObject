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

@property (weak) id<SoapObjectDelegate> delegate;
@property NSString *url;
@property NSString *functionName;

- (void)connectionWithDictionary:(NSDictionary *)dictionary version:(CGFloat)version;

@end
