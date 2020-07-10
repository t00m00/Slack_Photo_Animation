//
//  LinearEquation.m
//  Test_CollectionView
//
//  Created by toomoo on 2019/11/21.
//  Copyright © 2019 toomoo. All rights reserved.
//

#import "LinearEquation.h"


// 2点の座標を通る直線を表すクラス
@interface LinearEquation()

//@property (nonatomic, assign) CGPoint p1;      // 1つ目の座標
//@property (nonatomic, assign) CGPoint p2;      // 2つ目の座標

@property (nonatomic, assign) CGFloat inclination;      // 傾き a
@property (nonatomic, assign) CGFloat section;          // 切片 b

@end


@implementation LinearEquation


#pragma mark - Public Method
+ (instancetype)createWithPoint:(CGPoint)p1 p2:(CGPoint)p2 {
    
    if (CGPointEqualToPoint(p1, p2)) {
        // 同じ座標の場合は何もしない
        return nil;
    }

    return [[LinearEquation alloc] initWithPoint:p1 p2:p2];
}


// とあるx座標からy座標を求める
- (CGFloat)calcY:(CGFloat)x {
    
    return (self.inclination * x) + self.section;
}

// とあるy座標からx座標を求める
- (CGFloat)calcX:(CGFloat)y {

    // ToDo:|self.inclination(a)|が0だとクラッシュするので注意
    const CGFloat xPos = (y - self.section) / self.inclination;

    return isinf(xPos) ? 0 : xPos;
}




#pragma mark - Private Method
- (instancetype)initWithPoint:(CGPoint)p1 p2:(CGPoint)p2 {
    
    self = [super init];
    if (self) {
        
        // 2点の座標を通る直線を求める。  y1 = ax1 + b;  y2 = ax2 + b;
        //                           y1 = ax1 + y2 - ax2;
        //                           a = (y1 - y2) / (x1 - x2);
        //                           b = y - ax;

        
        // 傾きa を求める
        // ToDo：a=0の場合はありえるので対応する
//        CGFloat a = (MAX(p1.y, p2.y) - MIN(p1.y, p2.y)) / (MAX(p1.x, p2.x) - MIN(p1.x, p2.x));    // x座標がともにマイナスの場合におかしくなる
//        CGFloat a = (MAX(p1.y, p2.y) - MIN(p1.y, p2.y)) / (MAX(p1.x, p2.x) - MIN(p1.x, p2.x));
        CGFloat a = (p1.y - p2.y) / (p1.x - p2.x);
        a = isinf(a) ? 0 : a;
        CGFloat b = p1.y - (a * p1.x);
        
        self->_inclination = a;
        self->_section = b;
        
        NSLog(@" inclination(傾き) = %f", a);
        NSLog(@" section(切片)     = %f", b);
    }
    return self;
}


@end
