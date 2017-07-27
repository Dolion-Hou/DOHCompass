//
//  ViewController.m
//  DOHCompass
//
//  Created by Dolion.Hou on 2017/7/27.
//  Copyright © 2017年 Dolion.Hou. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController ()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController{
    UIImageView *_compassImageView;
    UIImageView *bgImageView;
    CMMotionManager *_motionManager;
    BOOL isFirst;
    CGFloat vlaue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setConfigure];
    [self addOwnSubviews];
}

- (void)setConfigure{
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DOHBg"]];
    isFirst = YES;
}

- (void)addOwnSubviews{

    CGSize size = [UIScreen mainScreen].bounds.size;
    bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    bgImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:bgImageView];
    bgImageView.frame = CGRectMake(0, 0, 300, 300);
    bgImageView.center = self.view.center;
    bgImageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.75];
    bgImageView.layer.cornerRadius = 150;
    bgImageView.layer.masksToBounds = YES;
    
    _compassImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zhen"]];
    _compassImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_compassImageView];
    _compassImageView.frame = CGRectMake(size.width/2-48, size.height/2-120, 100, 150);
    
    self.locationManager = [[CLLocationManager alloc]init];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        //当用户使用的时候授权
        [self.locationManager requestWhenInUseAuthorization];
    }

    _locationManager.delegate = self;
    //设置定位精度，越高耗电量越大
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //定位频率,每隔多少米定位一次
    CLLocationDistance distance = 10.0;
    //十米定位一次
    _locationManager.distanceFilter = distance;
    //启动跟踪定位
    //    [_locationManager startUpdatingLocation];
    
    [_locationManager startUpdatingHeading];
    
    [self useGyroPush];
}

- (void)useGyroPush{
    //初始化全局管理对象
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    _motionManager = manager;
    //    if([manager isGyroActive] == NO){
    //        [manager startGyroUpdates];
    //    }
    //判断陀螺仪可不可以，判断陀螺仪是不是开启
    if ([manager isGyroAvailable]){
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        //告诉manager，更新频率是100Hz
        manager.gyroUpdateInterval = 0.01;
        //Push方式获取和处理数据
        [manager startGyroUpdatesToQueue:queue withHandler:^(CMGyroData *gyroData, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                //回到主线程对UI进行操作,因为界面上的UI变化都是在主线程中去执行的
                if (gyroData.rotationRate.z*0.1 > 0.002 || gyroData.rotationRate.z*0.1 < -0.002) {
                  [self rotateWithZ:gyroData.rotationRate.z*0.01];
                }
            });
            NSLog(@"%f",gyroData.rotationRate.z*0.1);
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    ///调用分类的方法 旋转图片
    [self rotateWithHeading:newHeading];
}

- (void)rotateWithHeading:(CLHeading *)heading {
    
    //将设备的方向角度换算成弧度
    CGFloat headings = M_PI *heading.magneticHeading / 180.0-0.1;
    if (isFirst) {
        vlaue = -headings;
        //创建不断旋转CALayer的transform属性的动画
        CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        //动画起始值
        CATransform3D fromValue = bgImageView.layer.transform;
        
        rotateAnimation.fromValue = [NSValue valueWithCATransform3D:fromValue];
        //绕Z轴旋转heading弧度的变换矩阵
        CATransform3D toValue = CATransform3DMakeRotation(-headings, 0, 0, 1);
        
        //设置动画结束值
        rotateAnimation.toValue = [NSValue valueWithCATransform3D:toValue];
        
        rotateAnimation.duration = 0.35;
        rotateAnimation.removedOnCompletion = YES;
        //设置动画结束后layer的变换矩阵
        bgImageView.layer.transform = toValue;
        
        //添加动画
        [bgImageView.layer addAnimation:rotateAnimation forKey:nil];
        isFirst = 0;
    }
}

- (void)rotateWithZ:(double)value{
    //将设备的方向角度换算成弧度
    vlaue = vlaue + value;
    //创建不断旋转CALayer的transform属性的动画
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    //动画起始值
    CATransform3D fromValue = bgImageView.layer.transform;
    
    rotateAnimation.fromValue = [NSValue valueWithCATransform3D:fromValue];
    //绕Z轴旋转heading弧度的变换矩阵
    CATransform3D toValue = CATransform3DMakeRotation(vlaue, 0, 0, 1);
    
    //设置动画结束值
    rotateAnimation.toValue = [NSValue valueWithCATransform3D:toValue];
    
    rotateAnimation.duration = 0.099;
    rotateAnimation.removedOnCompletion = YES;
    //设置动画结束后layer的变换矩阵
    bgImageView.layer.transform = toValue;
    
    //添加动画
    [bgImageView.layer addAnimation:rotateAnimation forKey:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
