//
//  FlyPlayer.h
//  flyplayer
//
//  Created by feng on 16/7/19.
//  Copyright © 2016年 feng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlyPlayer : UIView

-(void)preparePlayWithUrlStr:(NSString *)urlStr;

-(void)play;

-(void)pause;

@end
