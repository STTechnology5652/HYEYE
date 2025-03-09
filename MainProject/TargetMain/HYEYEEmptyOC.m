//
//  HYEYEEmptyOC.m
//  HYEYE_Pro
//
//  Created by stephenchen on 2025/01/27.
//

#import "HYEYEEmptyOC.h"

@implementation HYEYEEmptyOC
+ (void)load {
#ifdef K_BETA
    NSLog(@"has kEnterprise:%d", K_BETA);
#else
    NSLog(@"no kEnterprise");
#endif
}
@end
