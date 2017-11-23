//
//  CustomPinAnnotationView.m
//  MapViewLists
//
//  Created by Macx on 2017/11/23.
//  Copyright © 2017年 Macx. All rights reserved.
//

#import "CustomPinAnnotationView.h"

@implementation CustomPinAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        
        //        在大头针旁边加一个label
        self.label = [[UILabel alloc]initWithFrame:CGRectMake(0, -15, 50, 20)];
        self.label.textColor = [UIColor redColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.font = [UIFont systemFontOfSize:20];
        [self addSubview:self.label];
        
    }
    return self;
    
}

@end
