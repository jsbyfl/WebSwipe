//
//  PcWebViewSwipeManager.h
//  WebSwipeDemo
//
//  Created by lpc on 2018/12/18.
//  Copyright © 2018 lpc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol WebViewSwipeDelegate <NSObject>

- (void)swipeWebView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)swipeWebViewDidFinishLoad:(UIWebView *)webView;

@end


@interface PcWebViewSwipeManager : NSObject<WebViewSwipeDelegate>

@property (nonatomic,assign,readonly) BOOL isCanSwipeGoBack; //是否可以右滑返回上一个H5记录
- (void)configWithController:(UIViewController *)controller webView:(UIWebView *)webView;

@end
