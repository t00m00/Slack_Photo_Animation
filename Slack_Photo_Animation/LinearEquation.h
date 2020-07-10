//
//  LinearEquation.h
//  Test_CollectionView
//
//  Created by toomoo on 2019/11/21.
//  Copyright © 2019 toomoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LinearEquation : NSObject

+ (instancetype)createWithPoint:(CGPoint)p1 p2:(CGPoint)p2;

- (CGFloat)calcY:(CGFloat)x;    // とあるx座標からy座標を求める
- (CGFloat)calcX:(CGFloat)y;    // とあるy座標からx座標を求める


@end

NS_ASSUME_NONNULL_END
