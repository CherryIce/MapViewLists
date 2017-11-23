//
//  MyAnnotation.m
//  MapViewLists
//
//  Created by Macx on 2017/11/23.
//  Copyright © 2017年 Macx. All rights reserved.
//

#import "MyAnnotation.h"

@implementation MyAnnotation

- (instancetype)initWithAnnotationModelWithDict:(NSDictionary *)dict{
    self = [super init];
    if (self) {
        
        
        self.coordinate = CLLocationCoordinate2DMake([dict[@"coordinate"][@"latitute"] doubleValue], [dict[@"coordinate"][@"longitude"] doubleValue]);
        self.title = dict[@"detail"];
        self.name = dict[@"name"];
        self.type = dict[@"type"];
    }
    return self;
}

@end
