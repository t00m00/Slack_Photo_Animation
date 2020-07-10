//
//  ViewController.m
//  Test_CollectionView
//
//  Created by toomoo on 2019/09/22.
//  Copyright © 2019 toomoo. All rights reserved.
//

#import "ViewController.h"
#import "zoomViewController.h"

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *myCollectionView;

@property (strong, nonatomic) NSArray <NSString *> *stamp;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.myCollectionView.delegate = self;
    self.myCollectionView.dataSource = self;
    
    
    self.stamp = @[@"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶",
                   @"😆", @"🤔", @"😁", @"😏", @"😷", @"👍", @"🐱", @"🤗", @"🤡", @"🥶"];


}


#pragma mark --- UICollectionViewDataSource ---

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [self.stamp count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell * const cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"myCollectionViewCell" forIndexPath:indexPath];
    
    UILabel *label = [cell.contentView viewWithTag:1];
    label.text = self.stamp[indexPath.row];
    
    
    // 確認しやすくなるよう背景色の切り替え
    if (indexPath.row % 2 == 0) {
    
//        label.backgroundColor = UIColor.lightGrayColor;
    } else {
        
//        label.backgroundColor = UIColor.brownColor;
    }
    
    return cell;
}

/**
 *  対象セルのサイズを設定します
 *
 *  @param collectionView       対象CollectionView
 *  @param collectionViewLayout 対象CollectionViewLayout
 *  @param indexPath            対象IndexPath
 *
 *  @return 設定サイズ
 */
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
//    return CGSizeMake(44, 44);
    
    
    if (indexPath.row % 2 == 0) {
        
        return CGSizeMake(44, 44);
    }
    
    return CGSizeMake(44, 80);
    
}


// 選択された
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"selected row = %ld", indexPath.row);
    
    NSString *text = [self.stamp objectAtIndex:indexPath.row];
    
    // 画面遷移
    [self performSegueWithIdentifier:@"mySegue" sender:text];
    
    
}


// 画面遷移準備
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"mySegue" ]) {
     
        zoomViewController *zoomVC = segue.destinationViewController;
        zoomVC.targetText = sender;
    }
}


// Unwind Segueが有効かどうかを返却する。このメソッドは戻り先に記載する。また iOS6.0からdeprecatedのようだ
// ⬇️を使用すべきのようだ。記載先は、元なのか先なのかは調べていない。
// - (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender;
/*
- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    
    return  YES;
}
 */


// モーダルから戻る際に呼び出される
-(IBAction)myUnwindAction:(UIStoryboardSegue *)unwindSegue towardsViewController:(UIViewController *)subsequentVC
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
}

@end
