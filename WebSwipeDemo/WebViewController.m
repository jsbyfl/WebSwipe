//
//  WebViewController.m
//  WebSwipeDemo
//
//  Created by lpc on 2018/12/18.
//  Copyright © 2018 lpc. All rights reserved.
//

#import "WebViewController.h"
#import "PcWebViewSwipeManager.h"

@interface WebViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic,weak) id<WebViewSwipeDelegate> swipeDelegate;
@property (nonatomic,strong) PcWebViewSwipeManager *swipeManager;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView.delegate = self;
    
    [self customWebViewSwipe];
    
    [self loadUrl:@"https://news.163.com/18/1218/08/E3A17E800001875P.html"];
}

//添加右滑返回管理
- (void)customWebViewSwipe
{
    self.swipeDelegate = self.swipeManager;
    [self.swipeManager configWithController:self webView:self.webView];
}

- (void)loadUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}


#pragma mark - UIWebViewDelegate method
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //设置右滑手势回调
    if (_swipeDelegate && [_swipeDelegate respondsToSelector:@selector(swipeWebView:shouldStartLoadWithRequest:navigationType:)]) {
        [self.swipeDelegate swipeWebView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"加载完成网页: %@", [webView.request.URL absoluteString]);
    if (_swipeDelegate && [_swipeDelegate respondsToSelector:@selector(swipeWebViewDidFinishLoad:)]) {
        [self.swipeDelegate swipeWebViewDidFinishLoad:webView];
    }
}


#pragma mark - getters
- (PcWebViewSwipeManager *)swipeManager{
    if (!_swipeManager) {
        _swipeManager = [PcWebViewSwipeManager new];
    }
    return _swipeManager;
}

@end
