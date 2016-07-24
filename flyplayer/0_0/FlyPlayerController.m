//
//  FlyPlayerController.m
//  flyplayer
//
//  Created by feng on 16/7/19.
//  Copyright © 2016年 feng. All rights reserved.
//

#import "FlyPlayerController.h"
#import "FlyPlayer.h"

@interface FlyPlayerController ()

@property(nonatomic,strong)UIButton *backButton;
@property(nonatomic,strong)FlyPlayer *flyplayer;

@end

@implementation FlyPlayerController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.flyplayer];
    [self.view addSubview:self.backButton];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cuc_ieschool" ofType:@"flv"];
    
    [self.flyplayer preparePlayWithUrlStr:path];
}


#pragma mark - button response
-(void)backButtonActions{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - setters and getters
-(UIButton *)backButton{
    if (_backButton == nil) {
        _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backButton setTitle:@"返回" forState:UIControlStateNormal];
        _backButton.frame = CGRectMake(0, 20, 60, 30);
        [_backButton addTarget:self action:@selector(backButtonActions) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

-(FlyPlayer *)flyplayer{
    if (_flyplayer == nil) {
        _flyplayer = [[FlyPlayer alloc] initWithFrame:self.view.bounds];
    }
    return _flyplayer;
}

@end
