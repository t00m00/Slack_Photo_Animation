//
//  zoomViewController.m
//  Test_CollectionView
//
//  Created by toomoo on 2019/09/22.
//  Copyright © 2019 toomoo. All rights reserved.
//

#import "zoomViewController.h"
#import "LinearEquation.h"


@interface zoomViewController ()

@property (weak, nonatomic) IBOutlet UILabel *zoomLabel;

// 初期位置情報
@property (assign, nonatomic) CGPoint iPt;
@property(nonatomic) CGAffineTransform iTransform;

// 座標
@property (assign, nonatomic) CGPoint currentPt;
@property (assign, nonatomic) CGPoint prevPt;

@end

// ラベルを表示しているセンターを原点とした、仮座標空間の座標系の最大、最小の座標値
static CGFloat V_COOR_MAX_X, V_COOR_MIN_X,
               V_COOR_MAX_Y, V_COOR_MIN_Y;

// 画面クローズのためのスワイプ閾値
static const CGFloat kSPEEDTHRESHOLD  = 15.f;

// 画面外へ確実に飛ばすための座標のオフセット
static const CGFloat kOFFSET = 100.f;


//------------------------------------------------------------------------------
// 座標、角度計算関数郡
// 角度をラジアンに変換する
static inline double radians (double degrees) {return degrees * M_PI / 180;}

// 画面から指を離したか判定する
static inline BOOL isTouchStateEnded (UIGestureRecognizerState state) {
    //    NSLog(@"Gesture State : %d", (int)state);    // 3 が End. 指を離した
    return (state == UIGestureRecognizerStateEnded);
}
// 2点の距離の計算
static inline CGFloat calcDisntace (CGPoint pointA, CGPoint pointB) {
    CGFloat xDistance = pointA.x - pointB.x;
    CGFloat yDistance = pointA.y - pointB.y;
    CGFloat distance = sqrtf(xDistance*xDistance + yDistance*yDistance);
    return distance;
}


// 2点から角度（度）を求める
static inline NSInteger calcDegrees (CGPoint pOrigin, CGPoint pCurrent) {
    
    int xSign = 1;
    int ySign = 1;
    
    
    if (signbit(pCurrent.x) == signbit(pOrigin.x)) {
        
        // 同じ象限にいる場合は引く（２点の距離は縮める）
        xSign = -1;
    } else if ( pCurrent.x < 0 && 0 < pOrigin.x) {
        
        // 引くことで２点の距離を離す
        xSign = -1;
    } else if ( 0 < pCurrent.x && pOrigin.x < 0) {
        
        // 引くことで２点の距離を離す
        xSign = -1;
    }
    
    if (signbit(pCurrent.y) == signbit(pOrigin.y)) {
        
        // 同じ象限にいる場合は引く（２点の距離は縮める）
        ySign = -1;
    } else if ( pCurrent.y < 0 && 0 < pOrigin.y) {
        
        // 引くことで２点の距離を離す
        ySign = -1;
    } else if ( 0 < pCurrent.y && pOrigin.y < 0) {
        
        // 引くことで２点の距離を離す
        ySign = -1;
    }
    
    
    // 座標系の原点をpOriginへと移動
    CGFloat x = pCurrent.x + (xSign * pOrigin.x);           // 単位円内の三角形の底辺
    CGFloat y = pCurrent.y + (ySign * pOrigin.y);           // 単位円内の三角形の高さ
    CGFloat distance = calcDisntace(CGPointMake(0, 0),
                                    CGPointMake(x, y));     // 単位円内の三角形の斜辺
    CGFloat cos = x / distance;                             // コサイン
    
    
    const double radian = acos(cos);                        // 逆関数アークコサインで角度（ラジアン）を求める
    double angle = ( radian / M_PI ) * 180.0;               // 角度に戻す

    // コサインは０からπまでは減少し続け、π（１８０°）で最小（ー１）になった後また増加していくので、
    // 角度がπより大きい（今回の場合は|pCurrent.y - pOrigin.y|<0）場合は、
    // ２π（３６０°）から角度を引いた値のコサインを求めています。
    angle = (y < 0) ? (360 - angle) : angle;
    const NSInteger degrees = (NSInteger)round(angle);                  // 四捨五入
    
    NSLog(@"degrees = %ld", degrees);
    return degrees;
}


// 最終的にオブジェクトを飛ばす座標を計算する
// 2019/11/22 ２点を通る直線を使用するので「ボツ」にした
static inline CGPoint calcDestination (CGPoint currentPt, CGPoint prevPt) {
    CGFloat distance = calcDisntace(currentPt, prevPt);
    CGFloat x = MAX(currentPt.x, prevPt.x);
    CGFloat y = MAX(currentPt.y, prevPt.y);

    int xSign = 1, ySign = 1;
    // signbit(n) 符号を判定する。負は0以外。つまりYES
    if (signbit(currentPt.x)) {
        x = MIN(currentPt.x, prevPt.x);
        xSign = -1;
    }
    
    if (signbit(currentPt.y)) {
        x = MIN(currentPt.x, prevPt.x);
        ySign = -1;
    }
    
    // 速さが速いほど遠くに飛ばす。4を乗算することで速さによる違いを明確にする
    // 2019/11/18 ToDo：なんとなくスワイプした延長線上へ対象物が移動するようになったが、違和感が残る
    //                  Slackのようにするには、2点を通る１次直線を求め、xまたはyを代入することで
    //                  最終的な目的座標を求める計算をする必要がある。
    //                  なお、テキストラベルのUITapジェスチャーの座標はラベル位置が原点、
    //                  ViewControllerでは左上が原点がとなるため、VCの座標系に変換するためには、
    //                  切片を適切に求める必要がある
    CGPoint distination = CGPointMake(x + distance * xSign * 20,
                                      y + distance * ySign * 20);
    
    return distination;
}


@implementation zoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    NSLog(@" Initial Frame  : %@", NSStringFromCGPoint(self.zoomLabel.frame.origin));
//    NSLog(@" Initial Center : %@", NSStringFromCGPoint(self.zoomLabel.center));

    self.zoomLabel.text = self.targetText;
    
    
    // 傾き、切片の値が正しいか検算→正しい
//    LinearEquation *le = [LinearEquation createWithPoint:CGPointMake(-5, 0)
//                                                       p2:CGPointMake(5, -50)];
    // 角度の計算が正しいか検算
    // ToDo:2019/11/23  計算が合わない。以下の上位２つを同時にみたさなかった。キーは原点(第一引数)を移動させる
//    calcDegrees(CGPointMake(1, 1),  CGPointMake(5, 5));    // 正解：45度
//    calcDegrees(CGPointMake(5, 5),  CGPointMake(4, 6));    // 正解：135度
//    calcDegrees(CGPointMake(6, -6), CGPointMake(-6, 6));   // 正解：135度
//    calcDegrees(CGPointMake(6, -6), CGPointMake(-6, -6));  // 正解：180度

    
   

}


- (void)viewDidAppear:(BOOL)animated {

    // ラベルを表示しているセンターを原点とした、仮座標空間の座標系の最大、最小の座標値
    V_COOR_MAX_X = CGRectGetMaxX(self.view.frame) / 2;
    V_COOR_MIN_X = -1 * V_COOR_MAX_X;
    V_COOR_MAX_Y = CGRectGetMaxY(self.view.frame) / 2;
    V_COOR_MIN_Y = -1 * V_COOR_MAX_Y;

    
    // viewDidLoad 時点では、layout計算が終わっていないため、centerがずれる。
    // このためここで初期座標を取得する
    NSLog(@" Initial Frame  : %@", NSStringFromCGPoint(self.zoomLabel.frame.origin));
    NSLog(@" Initial Center : %@", NSStringFromCGPoint(self.zoomLabel.center));
    
    
    self.iPt = self.zoomLabel.center;
    self.iTransform = self.zoomLabel.transform;
    
    // 境界線の検算
//    [self vectorDirectionWithP1:CGPointZero P2:CGPointZero];
 
    // 最終目的地座標の検算
    CGPoint test_prevPt      = CGPointZero;
//    CGPoint test_currentPt   = CGPointMake(100, 100);  // 正解：Finish Point：(187.500000, 187.500000)
    CGPoint test_currentPt   = CGPointMake(100, 200);    // ？：Finish Point：(166.750000, 333.500000)

    LinearEquation *test_le = [LinearEquation createWithPoint:test_currentPt p2:test_prevPt];
    TCObjectReachesFirst test_orf = [self vectorDirectionWithP1:test_prevPt P2:test_currentPt];
    NSLog(@"TCObjectReachesFirst = %ld", test_orf);
    [self finishPoint:test_le ObjectReachesFirst:test_orf];
    
    
}


- (IBAction)panGesture:(UIPanGestureRecognizer *)sender {
    

    [self myTouchesChanged:sender];
    
    if (isTouchStateEnded(sender.state)) {
    
        // 指を離した
        [self myTouchesEnded:sender];
        return;
    }
    
    
    /*
    CGPoint pt = [sender translationInView:self.view];
    NSLog(@"-------");
    NSLog(@"PT : %@", NSStringFromCGPoint(pt));

    // ラベルを指に合わせて移動させる
    [self moveLabelToPanPoint:pt];
    
    // 現在のViewの状態から回転させる
    [self rotateLabel:pt];

    // 指を離した場合に初期位置に戻るようにする
    if ( [[self class] isTouchStateEnded:sender.state] ) {
        
        [self resetPosition:YES];
    }
        
    // 19/11/16 勢いよくスワイプした際に画面を閉じる処理が必要
    // UIPanGestureRecogに時間の概念もあるので、閾値の時間内に特定の移動量を検知したら閉じれば良さそう
    [self exitAtBigSwipeWithPoint:pt state:sender.state];

     */

}

#pragma mark - Private Method 1
//////// イベントを分離する

// 指をドラッグしている（離した以外）
- (void)myTouchesChanged:(UIPanGestureRecognizer *)sender {

    CGPoint pt = [sender translationInView:self.view];
    NSLog(@"-------");
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"PT : %@", NSStringFromCGPoint(pt));
    
    [self holdPt:pt];
//    NSLog(@"Distance = %f", calcDisntace(self.currentPt, self.prevPt));
    
    // ラベルを指に合わせて移動させる
    [self moveLabelToPanPoint:pt];
    
    // 現在のViewの状態から回転させる
    [self rotateLabel:pt];
    
}

// 指を離した
- (void)myTouchesEnded:(UIPanGestureRecognizer *)sender {

    CGPoint pt = [sender translationInView:self.view];
    NSLog(@"-------");
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"PT : %@", NSStringFromCGPoint(pt));
//    NSLog(@" currentPt = %@", NSStringFromCGPoint(self.currentPt));
//    NSLog(@" prevPt    = %@", NSStringFromCGPoint(self.prevPt));
    
    // 19/11/16 勢いよくスワイプした際に画面を閉じる処理が必要
    // UIPanGestureRecogに時間の概念もあるので、閾値の時間内に特定の移動量を検知したら閉じれば良さそう
    BOOL isExit = [self exitAtBigSwipeWithPoint:pt state:sender.state];
    
    // 指を離した場合に初期位置に戻るようにする
    if (isExit == NO) {
        
        [self resetPosition:YES];
    }
}



#pragma mark - Private Method 2
// 絵文字を表示しているラベルを移動する
- (void)moveLabelToPanPoint:(CGPoint)pt {
    
    // Viewが指についていくるようにする
    //    self.zoomLabel.center = CGPointMake(self.initPt.x + pt.x, self.initPt.y + pt.y);
    NSLog(@"initPt : %@", NSStringFromCGPoint(self.iPt));
    NSLog(@"Bf Center : %@", NSStringFromCGPoint(self.zoomLabel.center));
    self.zoomLabel.center = CGPointMake(self.iPt.x + pt.x,
                                        self.iPt.y + pt.y);
    NSLog(@"Af Center : %@", NSStringFromCGPoint(self.zoomLabel.center));
}


// 絵文字を表示しているラベルを回転する
- (void)rotateLabel:(CGPoint)pt {

    // M_PI = π(360度相当)
    //    self.zoomLabel.transform = CGAffineTransformMakeRotation(pt.y / 360);
            
    // 現在のViewの状態から回転させる
    //    CGFloat degree = fmodf(smallY, 360);        // 割り算のあまり。最大で360度までしか回転しないようにする
    // 割り算のあまり。最大でデバイスの画面の高さの約半分までを回転角度とする
    // ※ちょうど半分だと、fmodfの分母を超えた際に急に小さい数字になり、回転がガクつくため猶予を持たせた数値を指定している
    CGFloat degree = fmodf(pt.y, CGRectGetMaxY(self.view.frame) / 1.8);
    NSLog(@"degree = %f", degree);
            
    // 回転実行
    // Affineの計算が累積しないように初期値のCTMに対して毎回実行する
    self.zoomLabel.transform =
        CGAffineTransformRotate(self.iTransform, radians(degree) / 4);  // ラジアンで指定する。(r / x)：xで回転速度を緩やかにする
    
}


// 指を素早く動かした場合に画面を１つ戻る。戻り値：YES → exitする　　NO → exitしない
- (BOOL)exitAtBigSwipeWithPoint:(CGPoint)pt
                          state:(UIGestureRecognizerState)state {
    
//    static CGPoint prevPt;
//
//    CGFloat diffY = pt.y - prevPt.y;
//    NSLog(@"diffY = %f", diffY);
//    NSLog(@"Gesture State : %d", (int)state);    // 3 が End. 指を離した
    
    CGFloat distance = calcDisntace(self.currentPt, self.prevPt);
    NSLog(@"Distance = %f", distance);
    
    // 厳密には「速さ(距離÷時間)」である。時間の分母を１としているため、距離(distance)と比較している
    // 速さとすることで、Slackのように滑らかになってきた
    if (distance > kSPEEDTHRESHOLD) {
        // 画面端へ行くアニメーションの後、画面を一つ戻す
        [self moveLabelToEdge:YES point:pt completion:^(BOOL finished) {
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        return YES;
    }
    
    return NO;
}



// 画面から指を離したか判定する
//+ (BOOL)isTouchStateEnded:(UIGestureRecognizerState)state {
    
//    NSLog(@"Gesture State : %d", (int)state);    // 3 が End. 指を離した
//    return (state == UIGestureRecognizerStateEnded);
//}



// 初期値に戻す
- (void)resetPosition:(BOOL)animated {
    
    CGFloat duration = 0.f;
    if (animated) {
        duration = 0.3f;
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
        //アニメーションで変化させたい値を設定する（最終的に変更したい値）
        self.zoomLabel.center = self.iPt;
        self.zoomLabel.transform = self.iTransform;
        
    } completion:^(BOOL finished) {
        //完了時のコールバック
    }];
    
}



// 画面端へ行くアニメーションを行う
- (void)moveLabelToEdge:(BOOL)animated
                  point:(CGPoint)pt
             completion:(void (^ __nullable)(BOOL finished))completion {
    

    // 投擲方向の判定
    TCObjectReachesFirst orf = [self vectorDirectionWithP1:self.prevPt P2:self.currentPt];
    NSLog(@"TCObjectReachesFirst = %ld", orf);
    
    // 2点を通る直線を求める
    LinearEquation *le = [LinearEquation createWithPoint:self.currentPt p2:self.prevPt];
    
    CGPoint tmpDistination = [self finishPoint:le ObjectReachesFirst:orf];

    
    const CGFloat duration = animated ? 0.4 : 0.f;
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^ {
        //アニメーションで変化させたい値を設定する（最終的に変更したい値）
//        self.zoomLabel.center =
//            CGPointMake(self.zoomLabel.center.x, cy);
        
        const CGFloat yDistination = self.iPt.y + tmpDistination.y;
        self.zoomLabel.center = CGPointMake(self.iPt.x + tmpDistination.x,
                                            yDistination);
        
        
        // 投擲時の回転方向を制御
        NSInteger sign = (yDistination < 0) ? -1 : 1;
//        if (self.currentPt.y < 0 && 0 <= yDistination) { sign = 1;}      // y軸方向の象限をまたいだ場合(負→正への投擲)
//        else if (0 < self.currentPt.y && yDistination < 0) { sign = -1;}   // y軸方向の象限をまたいだ場合(正→負への投擲)
        NSLog(@"sign = %ld", sign);
        
        self.zoomLabel.transform =
            CGAffineTransformRotate(self.zoomLabel.transform, sign * radians(180));  // 3は180度を何回回すかを表す

        
    } completion:^(BOOL finished) {
        
        //完了時のコールバック
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(0.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            
            self.zoomLabel.hidden = YES;
            completion(finished);
        });
    }];
    
}


// PanGestureの直近２回分の座標を保持する
- (void)holdPt:(CGPoint)newPt {
    
    if (CGPointEqualToPoint(newPt, self.currentPt)) {
        
        // 直近と同じ場合は更新しない
        return;
    }
    
    self.prevPt = self.currentPt;
    self.currentPt = newPt;

    NSLog(@"currentPt = %@", NSStringFromCGPoint(self.currentPt));
    NSLog(@"prevPt    = %@", NSStringFromCGPoint(self.prevPt));

}


// ラベルが到達する方向
typedef NS_ENUM(NSInteger, TCObjectReachesFirst) {
    TCObjectReachesFirstTop    = 0,     // 座標系が数学と異なるので、iPhone上だとホームボタン側
    TCObjectReachesFirstLeft   = 1,
    TCObjectReachesFirstBottom = 2,     // 座標系が数学と異なるので、iPhone上だとカメラ側
    TCObjectReachesFirstRight  = 3,
};

// ラベルが最初に到達する方向を返却する
- (TCObjectReachesFirst)vectorDirectionWithP1:(CGPoint)prevPt P2:(CGPoint)currntPt {
    
    // ラベルを放り投げた際に、x座標、y座標のどちらが先に到達するかの境界線（角度）
    static NSInteger borderRightTop, borderTopLeft,
                borderLeftBottom, borderBottomRigt;
    
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 境界となる角度を求める
        borderRightTop   = calcDegrees(CGPointZero, CGPointMake(V_COOR_MAX_X, V_COOR_MAX_Y));
        borderTopLeft    = calcDegrees(CGPointZero, CGPointMake(V_COOR_MIN_X, V_COOR_MAX_Y));
        borderLeftBottom = calcDegrees(CGPointZero, CGPointMake(V_COOR_MIN_X, V_COOR_MIN_Y));
        borderBottomRigt = calcDegrees(CGPointZero, CGPointMake(V_COOR_MAX_X, V_COOR_MIN_Y));
        
//        NSLog(@"borderRightTop   = %ld", borderRightTop);
//        NSLog(@"borderTopLeft    = %ld", borderTopLeft);
//        NSLog(@"borderLeftBottom = %ld", borderLeftBottom);
//        NSLog(@"borderBottomRigt = %ld", borderBottomRigt);
    });
    
    const NSInteger crrentDegree = calcDegrees(prevPt, currntPt);
    
    
    if (borderRightTop < crrentDegree && crrentDegree < borderTopLeft)  {             // TOP

        return TCObjectReachesFirstTop;
    } else if (borderTopLeft < crrentDegree && crrentDegree < borderLeftBottom) {     // Left
        
        return TCObjectReachesFirstLeft;
    } else if (borderLeftBottom < crrentDegree && crrentDegree < borderBottomRigt) {  // Bottom
        
        return TCObjectReachesFirstBottom;
    }
    
    // どれでもない場合はRight
    return TCObjectReachesFirstRight;
    
}

// 飛ばされたオブジェクトの最終目的地の座標を計算し返却する
- (CGPoint)finishPoint:(LinearEquation *)le ObjectReachesFirst:(TCObjectReachesFirst)orf  {

    // スワイプスピードが速い場合は、より遠くに飛ばす
    CGFloat speed = calcDisntace(self.currentPt, self.prevPt);

    // 画面外へ確実に飛ばすためのオフセット
    const CGFloat OFFSET = kOFFSET * (speed / kSPEEDTHRESHOLD);
    
    
    CGFloat x = 0, y = 0;
    
    if ( orf == TCObjectReachesFirstTop ) {
        
        // y軸の正の方向に先に到達する
        y = V_COOR_MAX_Y + OFFSET;
        x = [le calcX:y];
        
    } else if ( orf == TCObjectReachesFirstLeft ) {
        
        // x軸の負の方向に先に到達する
        x = V_COOR_MIN_X - OFFSET;
        y = [le calcY:x];
        
    } else if ( orf == TCObjectReachesFirstBottom ) {
        
        // y軸の負の方向に先に到達する
        y = V_COOR_MIN_Y - OFFSET;
        x = [le calcX:y];
        
    } else {    // Right
        
        // x軸の正の方向に先に到達する
        x = V_COOR_MAX_X + OFFSET;
        y = [le calcY:x];
        
    }
    
    
    NSLog(@"Finish Point：(%f, %f)", x, y);
    return CGPointMake(x, y);
}




#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
