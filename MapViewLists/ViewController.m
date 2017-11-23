//
//  ViewController.m
//  MapViewLists
//
//  Created by Macx on 2017/11/23.
//  Copyright © 2017年 Macx. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MyAnnotation.h"
#import "CustomPinAnnotationView.h"

#define LAT_OFFSET_0(x,y) -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x))
#define LAT_OFFSET_1 (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
#define LAT_OFFSET_2 (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0
#define LAT_OFFSET_3 (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0

#define LON_OFFSET_0(x,y) 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x))
#define LON_OFFSET_1 (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
#define LON_OFFSET_2 (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0
#define LON_OFFSET_3 (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0

#define RANGE_LON_MAX 137.8347
#define RANGE_LON_MIN 72.004
#define RANGE_LAT_MAX 55.8271
#define RANGE_LAT_MIN 0.8293

#define jzA 6378245.0
#define jzEE 0.00669342162296594323

@interface ViewController ()<MKMapViewDelegate>
{
    CLLocationManager *_locationManager;
    
    MKMapView *_mapView;
}

@property (nonatomic,retain) NSMutableArray *locationArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //    定位授权
    
    _locationManager = [[CLLocationManager alloc]init];
    [_locationManager requestWhenInUseAuthorization];
    
    
    //    地图视图
    _mapView = [[MKMapView alloc]initWithFrame:self.view.frame];
    _mapView.showsUserLocation = YES;
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    //    如果在ViewDidLoad中调用  添加大头针的话会没有掉落效果  定位结束后再添加大头针才会有掉落效果
    [self loadData];
    [self addGesture];
}

- (void) addGesture
{
    UILongPressGestureRecognizer *lpress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    lpress.minimumPressDuration = 0.3;//按0.5秒响应longPress方法
    lpress.allowableMovement = 10.0;
    //给MKMapView加上长按事件
    [_mapView addGestureRecognizer:lpress];//mapView是MKMapView的实例
}

- (void)loadData{
    CLLocationCoordinate2D  a = CLLocationCoordinate2DMake(22.647795, 113.963037);
    a =  [self WGS84ToGCJ02:a];
    NSDictionary * dict1 = @{@"coordinate" : @{@"latitude" : @(a.latitude),
                                     @"longitude" : @(a.longitude)},
                             @"detail" : @"1",
                             @"name" : @"哈哈",
                             @"type" : @(0)};
    NSDictionary * dict2 = @{@"coordinate" : @{@"latitude" : @"39.368279",
                                               @"longitude" : @"116.542969"},
                             @"detail" : @"1",
                             @"name" : @"哈哈",
                             @"type" : @(1)};
    NSDictionary * dict3 = @{@"coordinate" : @{@"latitude" : @"23.644524",
                                               @"longitude" : @"114.257813"},
                             @"detail" : @"1",
                             @"name" : @"哈哈",
                             @"type" : @(0)};
    NSArray *tempArray = @[dict1,dict2,dict3];
    //    把plist数据转换成大头针model
    for (NSDictionary *dict in tempArray) {
        MyAnnotation *myAnnotationModel = [[MyAnnotation alloc]initWithAnnotationModelWithDict:dict];
        
        [self.locationArray addObject:myAnnotationModel];
    }
    //    核心代码
    [_mapView addAnnotations:self.locationArray];
    
}

#pragma mark ------ delegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
//    userLocation.title  = @"当前位置";
//    _mapView.centerCoordinate = userLocation.coordinate;
//    [_mapView setRegion:MKCoordinateRegionMake(userLocation.coordinate, MKCoordinateSpanMake(0.01, 0.01)) animated:YES];
   [self zoomToFitMapAnnotations:_mapView];
    //    如果在ViewDidLoad中调用  添加大头针的话会没有掉落效果  定位结束后再添加大头针才会有掉落效果
   //[self loadData];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    
    /*
     
     * 大头针分两种
     
     * 1. MKPinAnnotationView：他是系统自带的大头针，继承于MKAnnotationView，形状跟棒棒糖类似，可以设置糖的颜色，和显示的时候是否有动画效果
     
     * 2. MKAnnotationView：可以用指定的图片作为大头针的样式，但显示的时候没有动画效果，如果没有给图片的话会什么都不显示
     
     * 3. mapview有个代理方法，当大头针显示在试图上时会调用，可以实现这个方法来自定义大头针的动画效果，我下面写有可以参考一下
     
     * 4. 在这里我为了自定义大头针的样式，使用的是MKAnnotationView
     
     */
    
    //    判断是不是用户的大头针数据模型
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        MKAnnotationView *annotationView = [[MKAnnotationView alloc]init];
        annotationView.image = [UIImage imageNamed:@"address"];
        
        //        是否允许显示插入视图*********
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    
    CustomPinAnnotationView *annotationView = (CustomPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"otherAnnotationView"];
    if (annotationView == nil) {
        annotationView = [[CustomPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"otherAnnotationView"];
    }
    MyAnnotation *myAnnotation = annotation;
    switch ([myAnnotation.type intValue]) {
        case SUPER_MARKET:
            annotationView.image = [UIImage imageNamed:@"address"];
            //annotationView.label.text = @"超市";
            break;
        case CREMATORY:
            annotationView.image = [UIImage imageNamed:@"address"];
            //annotationView.label.text = @"火场";
            break;
        case INTEREST:
            annotationView.image = [UIImage imageNamed:@"address"];
            //annotationView.label.text = @"风景区";
            break;
            
        default:
            break;
    }
    return annotationView;
}


//大头针显示在视图上时调用，在这里给大头针设置显示动画
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views{
    //    获得mapView的Frame
    CGRect visibleRect = [mapView annotationVisibleRect];
    
    for (MKAnnotationView *view in views) {
        
        CGRect endFrame = view.frame;
        CGRect startFrame = endFrame;
        startFrame.origin.y = visibleRect.origin.y - startFrame.size.height;
        view.frame = startFrame;
        [UIView beginAnimations:@"drop" context:NULL];
        [UIView setAnimationDuration:1];
        view.frame = endFrame;
        [UIView commitAnimations];
    }
}

#pragma mark lazy load
- (NSMutableArray *)locationArray{
    
    if (_locationArray == nil) {
        
        _locationArray = [NSMutableArray new];
        
    }
    return _locationArray;
}

/**
 点击当前大头针的操作
 */
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view

{
    
    NSArray * array = [NSArray arrayWithArray:_mapView.annotations];
    
    for (int i=0; i<array.count; i++)
        
    {
        
        if (view.annotation.coordinate.latitude ==((MKPointAnnotation*)array[i]).coordinate.latitude)
            
        {
            //获取到当前的大头针  你可以执行一些操作
        }
        
        else
            
        {
            
            //对其余的大头针进行操作  我是删除
            
            //[_mapView removeAnnotation:array[i]];
            
        }
        
    }
}

- (void)longPress:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan){  //这个状态判断很重要
        //坐标转换
        CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
        CLLocationCoordinate2D touchMapCoordinate =
        [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
        
        //这里的touchMapCoordinate.latitude和touchMapCoordinate.longitude就是你要的经纬度，
        NSString *url = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?latlng=%f,%f&sensor=false&region=sh&language=zh-CN", touchMapCoordinate.latitude, touchMapCoordinate.longitude];
        [self loadMapDetailByUrl:url];
    }
}

- (void) loadMapDetailByUrl:(NSString *)url
{
    
}

-(void)zoomToFitMapAnnotations:(MKMapView*)mapView
{
    if([mapView.annotations count] == 0)
        return;
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for(MyAnnotation * annotation in mapView.annotations)
    {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1; // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1; // Add a little extra space on the sides
    
    region = [mapView regionThatFits:region];
    [mapView setRegion:region animated:YES];
}

/**
 火星坐标
 */
- (CLLocationCoordinate2D)WGS84ToGCJ02:(CLLocationCoordinate2D)location {
    return [self GCJ02Encrypt:location.latitude BDLon:location.longitude];
}

- (CLLocationCoordinate2D)GCJ02Encrypt:(double)ggLat BDLon:(double)ggLon
{
    CLLocationCoordinate2D resPoint;
    double mgLat;
    double mgLon;
    if ([self outOfChina:ggLat BDLon:ggLon]) {
        resPoint.latitude = ggLat;
        resPoint.longitude = ggLon;
        return resPoint;
    }
    double dLat = [self transformLat:(ggLon - 105.0)BDLon:(ggLat - 35.0)];
    double dLon = [self transformLon:(ggLon - 105.0) BDLon:(ggLat - 35.0)];
    double radLat = ggLat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - jzEE * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((jzA * (1 - jzEE)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (jzA / sqrtMagic * cos(radLat) * M_PI);
    mgLat = ggLat + dLat;
    mgLon = ggLon + dLon;
    
    resPoint.latitude = mgLat;
    resPoint.longitude = mgLon;
    return resPoint;
}

- (BOOL)outOfChina:(double)lat BDLon:(double)lon {
    if (lon < RANGE_LON_MIN || lon > RANGE_LON_MAX)
        return YES;
    if (lat < RANGE_LAT_MIN || lat > RANGE_LAT_MAX)
        return YES;
    return NO;
}

- (double)transformLat:(double)x BDLon:(double)y {
    double ret = LAT_OFFSET_0(x, y);
    ret += LAT_OFFSET_1;
    ret += LAT_OFFSET_2;
    ret += LAT_OFFSET_3;
    return ret;
}

- (double)transformLon:(double)x BDLon:(double)y {
    double ret = LON_OFFSET_0(x, y);
    ret += LON_OFFSET_1;
    ret += LON_OFFSET_2;
    ret += LON_OFFSET_3;
    return ret;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
