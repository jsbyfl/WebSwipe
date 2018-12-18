//
//  PcWebViewSwipeManager.m
//  WebSwipeDemo
//
//  Created by lpc on 2018/12/18.
//  Copyright © 2018 lpc. All rights reserved.
//

#import "PcWebViewSwipeManager.h"

#define k_WebView_Width     (self.webView.bounds.size.width)
#define k_WebView_Height    (self.webView.bounds.size.height)
#define k_PrevSnapShotView_OFF_X    60  //上一张截图的x偏移

static NSString *k_webRequest = @"k_webRequest";
static NSString *k_webSnapShotView = @"k_webSnapShotView";

#pragma mark - UIView+TransitionShadow
@implementation UIView (TransitionShadow)
- (void)addLeftSideShadowWithFading
{
    CGFloat shadowWidth = 4.0f;
    CGFloat shadowVerticalPadding = -1.0f;
    CGFloat shadowHeight = CGRectGetHeight(self.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = [shadowPath CGPath];
    self.layer.shadowOpacity = 0.2f;
}
@end


#pragma mark - WebViewSwipeManager
@interface PcWebViewSwipeManager ()

@property (nonatomic,weak) UIViewController *webController;
@property (nonatomic,weak) UIWebView *webView;

@property (nonatomic,strong) UIPanGestureRecognizer *swipePanGesture;
@property (nonatomic,assign) BOOL isSwipingBack;

@property (nonatomic,strong) NSMutableArray *snapShotsArray;
@property (nonatomic,strong) UIView *currentSnapShotView;
@property (nonatomic,strong) UIView *prevSnapShotView;
@property (nonatomic,strong) UIView *swipingBackgoundView;
@property (nonatomic,strong) UIView *blackBgView;
@end

@implementation PcWebViewSwipeManager

#pragma mark - config
- (void)configWithController:(UIViewController *)controller webView:(UIWebView *)webView
{
    self.webController = controller;
    self.webView = webView;
    [self.webView addGestureRecognizer:self.swipePanGesture];
}

- (void)updateNavigationGesture
{
    self.swipePanGesture.enabled = self.isCanSwipeGoBack;
}


#pragma mark - events handler
-(void)swipePanGestureHandler:(UIPanGestureRecognizer *)panGesture{
    CGPoint translation = [panGesture translationInView:self.webView];
    CGPoint location = [panGesture locationInView:self.webView];
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        if (location.x <= k_WebView_Width*0.4 && translation.x >= 0) {
            //开始动画
            [self startPopSnapshotView];
        }
    }
    else if (panGesture.state == UIGestureRecognizerStateCancelled || panGesture.state == UIGestureRecognizerStateEnded){
        [self endPopSnapShotView];
    }
    else if (panGesture.state == UIGestureRecognizerStateChanged){
        [self popSnapShotViewWithPanGestureDistance:translation.x];
    }
}


#pragma mark - logic of push and pop snap shot views
-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest *)request
{
    //正在右滑 不进行截屏
    if (self.isSwipingBack) {
        return;
    }
    
    //如果url是很奇怪的就不push
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        return;
    }
    
    NSURLRequest *lastRequest = (NSURLRequest*)[[self.snapShotsArray lastObject] objectForKey:k_webRequest];
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    
    UIView *currentSnapShotView = [self.webView snapshotViewAfterScreenUpdates:NO];
    NSDictionary *viewDic = @{k_webRequest:request,k_webSnapShotView:currentSnapShotView};
    [self.snapShotsArray addObject:viewDic];
}

-(void)startPopSnapshotView
{
    if (self.isSwipingBack) {
        return;
    }
    //webView不能返回
    if (!self.webView.canGoBack) {
        return;
    }
    self.isSwipingBack = YES;
    
    self.currentSnapShotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    [self.currentSnapShotView addLeftSideShadowWithFading]; //添加左侧阴影
    
    self.prevSnapShotView = (UIView *)[[self.snapShotsArray lastObject] objectForKey:k_webSnapShotView];
    CGPoint center = CGPointMake(k_WebView_Width/2, k_WebView_Height/2);
    center.x -= k_PrevSnapShotView_OFF_X;
    self.prevSnapShotView.center = center;
    
    for (UIView *view in self.swipingBackgoundView.subviews) {
        [view removeFromSuperview];
    }
    [self.swipingBackgoundView addSubview:self.prevSnapShotView]; //上一个页面的截图
    [self.swipingBackgoundView addSubview:self.blackBgView]; //中间添加黑色阴影View
    [self.swipingBackgoundView addSubview:self.currentSnapShotView]; //当前页面截图
    [self.webView addSubview:self.swipingBackgoundView];
}

-(void)popSnapShotViewWithPanGestureDistance:(CGFloat)distance{
    if (!self.isSwipingBack) {
        return;
    }
    
    if (distance <= 0) {
        return;
    }
    
    //x坐标移动
    CGPoint currentSnapshotViewCenter = CGPointMake(k_WebView_Width/2, k_WebView_Height/2);
    currentSnapshotViewCenter.x += distance;
    self.currentSnapShotView.center = currentSnapshotViewCenter;
    
    CGPoint prevSnapshotViewCenter = CGPointMake(k_WebView_Width/2, k_WebView_Height/2);
    prevSnapshotViewCenter.x -= ((k_WebView_Width - distance)*k_PrevSnapShotView_OFF_X)/k_WebView_Width;
    self.prevSnapShotView.center = prevSnapshotViewCenter;
    self.blackBgView.alpha = (k_WebView_Width - distance)/k_WebView_Width;
}

-(void)endPopSnapShotView{
    if (!self.isSwipingBack) {
        return;
    }
    
    //prevent the user touch for now
    self.view.userInteractionEnabled = NO;
    
    if (self.currentSnapShotView.center.x >= k_WebView_Width) {
        // pop success
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapShotView.center = CGPointMake(k_WebView_Width*3/2, k_WebView_Height/2);
            self.prevSnapShotView.center = CGPointMake(k_WebView_Width/2, k_WebView_Height/2);
            self.blackBgView.alpha = 0;
        }completion:^(BOOL finished) {
            
            [self.webView goBack];
            [self.blackBgView removeFromSuperview];
            [self.currentSnapShotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            
            self.view.userInteractionEnabled = YES;
            self.isSwipingBack = NO;
        }];
    }
    else{
        //pop fail
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapShotView.center = CGPointMake(k_WebView_Width/2, k_WebView_Height/2);
            self.prevSnapShotView.center = CGPointMake(k_WebView_Width/2 - k_PrevSnapShotView_OFF_X, k_WebView_Height/2);
            self.prevSnapShotView.alpha = 1;
        }completion:^(BOOL finished) {
            [self.prevSnapShotView removeFromSuperview];
            [self.blackBgView removeFromSuperview];
            [self.currentSnapShotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            
            self.view.userInteractionEnabled = YES;
            
            self.isSwipingBack = NO;
        }];
    }
}


#pragma mark - WebViewSwipe Delegate
- (void)swipeWebView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    switch (navigationType) {
        case UIWebViewNavigationTypeLinkClicked:
        case UIWebViewNavigationTypeFormSubmitted:
        case UIWebViewNavigationTypeOther: {
            [self pushCurrentSnapshotViewWithRequest:request];
            break;
        }
            
        case UIWebViewNavigationTypeBackForward: {
            [self.snapShotsArray removeLastObject];
            break;
        }
        case UIWebViewNavigationTypeReload: {
            break;
        }
        case UIWebViewNavigationTypeFormResubmitted: {
            break;
        }
        default: {
            break;
        }
    }
}

- (void)swipeWebViewDidFinishLoad:(UIWebView *)webView
{
    [self updateNavigationGesture];
    
    if (_swipingBackgoundView.superview) {
        [_swipingBackgoundView removeFromSuperview];
    }
}


#pragma mark - getter
- (NSMutableArray *)snapShotsArray{
    if (!_snapShotsArray) {
        _snapShotsArray = [NSMutableArray array];
    }
    return _snapShotsArray;
}

-(UIView *)swipingBackgoundView{
    if (!_swipingBackgoundView) {
        _swipingBackgoundView = [[UIView alloc] initWithFrame:self.webView.bounds];
        _swipingBackgoundView.clipsToBounds = YES;
    }
    return _swipingBackgoundView;
}

- (UIView *)blackBgView{
    if (!_blackBgView) {
        _blackBgView = [[UIView alloc] initWithFrame:self.swipingBackgoundView.bounds];
        _blackBgView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.25];
        _blackBgView.alpha = 1;
    }
    return _blackBgView;
}

- (UIPanGestureRecognizer *)swipePanGesture{
    if (!_swipePanGesture) {
        _swipePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipePanGestureHandler:)];
    }
    return _swipePanGesture;
}

- (UIView *)view{
    return self.webController.view;
}

- (BOOL)isCanSwipeGoBack{
    if (self.webView.canGoBack) {
        return YES;
    }
    else{
        return NO;
    }
}

@end
