//
//  ViewController.m
//  SoapObject
//
//  Created by 江承諭 on 9/24/14.
//  Copyright (c) 2014 happiness9721. All rights reserved.
//

#import "ViewController.h"
#import "SoapObject.h"

@interface ViewController () <SoapObjectDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SoapObject *object = [[SoapObject alloc] init];
    object.url = @"http://www.mojotaiwan.com.tw/mojoitravelsvc/itemIDAt.asmx";
    object.functionName = @"WhereAreYouAt";
    object.delegate = self;
    NSDictionary *dictionary = @{
                                 @"DB_Name": @"TTN_GO_B2B",
                                 @"Table_Name": @"coverstorydata",
                                 @"Field_Name": @"articleid_dt_f"
                                 };
    [object connectionWithDictionary:dictionary version:1.1];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)soapObject:(SoapObject *)soapObject didfinishLoadArray:(NSArray *)array {
    NSLog(@"%@", array);
}

@end
