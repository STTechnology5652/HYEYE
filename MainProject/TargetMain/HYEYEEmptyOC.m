//
//  HYEYEEmptyOC.m
//  HYEYE_Pro
//
//  Created by stephenchen on 2025/01/27.
//

#import "HYEYEEmptyOC.h"

@implementation HYEYEEmptyOC
+ (void)load {
#ifdef kENTERPRISE
    NSLog(@"has kEnterprise:%d", kENTERPRISE);
#else
    NSLog(@"no kEnterprise");
#endif
}
@end
