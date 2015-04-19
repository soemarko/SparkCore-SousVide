//
//  MainViewController.h
//  Sous Vide
//
//  Created by Soemarko Ridwan on 3/15/15.
//  Copyright (c) 2015 Soemarko Ridwan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JBLineChartView.h"

@interface MainViewController : UIViewController <JBLineChartViewDataSource, JBLineChartViewDelegate>

@property (nonatomic, retain) JBLineChartView *chartView;
@property (nonatomic, retain) NSMutableArray *currentTemp;
@property (nonatomic, retain) NSMutableArray *targetTemp;

@property (nonatomic, retain) UILabel *pidLabel;
@property (nonatomic, retain) UILabel *tuneLabel;

@end
