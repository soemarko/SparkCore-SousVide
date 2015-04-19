//
//  MainViewController.m
//  Sous Vide
//
//  Created by Soemarko Ridwan on 3/15/15.
//  Copyright (c) 2015 Soemarko Ridwan. All rights reserved.
//

#import "MainViewController.h"
#import "EventSource.h"
#import "NSMutableURLRequest+Spark.h"
#import "FCActionSheet.h"
#import "FCAlertView.h"
#import "ALActionBlocks.h"

@implementation MainViewController {
	NSString *p, *i, *d;
}

- (id)init {
	self = [super init];
	if (self) {
		_currentTemp = [NSMutableArray arrayWithObject:@0];
		_targetTemp = [NSMutableArray arrayWithObject:@0];
		p = i = d = @"0.0";
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.navigationItem.title = @"Sous Vide";

	_chartView = [[JBLineChartView alloc] init];
	_chartView.frame = CGRectMake(5, 69, self.view.bounds.size.width-10, 200);
	_chartView.delegate = self;
	_chartView.dataSource = self;
	_chartView.headerPadding = 10.0f;
	_chartView.backgroundColor = [UIColor colorWithWhite:0.1f alpha:0.1f];

	_pidLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, _chartView.frame.size.height+5, self.view.bounds.size.width/2-5, 200)];
	_pidLabel.numberOfLines = 0;

	_tuneLabel = [[UILabel alloc] initWithFrame:CGRectMake(_pidLabel.frame.size.width+10, _chartView.frame.size.height+5, self.view.bounds.size.width/2-5, 200)];
	_tuneLabel.numberOfLines = 0;

	[self.view addSubview:_chartView];
	[self.view addSubview:_pidLabel];
	[self.view addSubview:_tuneLabel];

	[_chartView reloadData];

	UIButton *aBtn = [UIButton buttonWithType:UIButtonTypeSystem];
	[aBtn.titleLabel setFont:[UIFont systemFontOfSize:25.0f weight:UIFontWeightSemibold]];
	[aBtn setTitle:@"Set target" forState:UIControlStateNormal];
	[aBtn setExclusiveTouch:YES];
	[aBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
	[aBtn handleControlEvents:UIControlEventTouchUpInside withBlock:^(id weakSender) {
		// set target temperature
		FCAlertView *av = [[FCAlertView alloc] initWithTitle:@"Temperature" message:@"Target:" cancelButtonTitle:@"Cancel" cancelBlock:nil];

		__unsafe_unretained FCAlertView *weakAV = av;
		[av addButtonWithTitle:@"Set" action:^{
			NSString *str = [weakAV textFieldAtIndex:0].text;
			[self sendCommand:@"setPoint" withArgs:str];
		}];

		av.alertViewStyle = UIAlertViewStylePlainTextInput;
		[av textFieldAtIndex:0].text = [_targetTemp lastObject];
		[av textFieldAtIndex:0].keyboardType = UIKeyboardTypeDecimalPad;
		[av show];
	}];



	UIButton *bBtn = [UIButton buttonWithType:UIButtonTypeSystem];
	[bBtn.titleLabel setFont:[UIFont systemFontOfSize:25.0f weight:UIFontWeightSemibold]];
	[bBtn setTitle:@"Set tuning" forState:UIControlStateNormal];
	[bBtn setExclusiveTouch:YES];
	[bBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
	[bBtn handleControlEvents:UIControlEventTouchUpInside withBlock:^(id weakSender) {
		// set kP, kI, and kD
		FCAlertView *av = [[FCAlertView alloc] initWithTitle:@"Tunings" message:@"kP,kI,kD:" cancelButtonTitle:@"Cancel" cancelBlock:nil];

		__unsafe_unretained FCAlertView *weakAV = av;
		[av addButtonWithTitle:@"Set" action:^{
			NSString *str = [weakAV textFieldAtIndex:0].text;
			[self sendCommand:@"setTunings" withArgs:str];
		}];

		av.alertViewStyle = UIAlertViewStylePlainTextInput;
		[av textFieldAtIndex:0].text = [NSString stringWithFormat:@"%@,%@,%@", p, i, d];
		[av textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumbersAndPunctuation;
		[av show];
	}];

	UIButton *cBtn = [UIButton buttonWithType:UIButtonTypeSystem];
	[cBtn.titleLabel setFont:[UIFont systemFontOfSize:25.0f weight:UIFontWeightSemibold]];
	[cBtn setTitle:@"Auto tune" forState:UIControlStateNormal];
	[cBtn setExclusiveTouch:YES];
	[cBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
	[cBtn handleControlEvents:UIControlEventTouchUpInside withBlock:^(id weakSender) {
		// do auto tune (noise, step, lookback)
		FCAlertView *av = [[FCAlertView alloc] initWithTitle:@"Auto tune" message:@"noise,step,lookback:" cancelButtonTitle:@"Cancel" cancelBlock:nil];

		__unsafe_unretained FCAlertView *weakAV = av;
		[av addButtonWithTitle:@"Set" action:^{
			NSString *str = [weakAV textFieldAtIndex:0].text;
			[self sendCommand:@"autoTune" withArgs:str];
		}];

		av.alertViewStyle = UIAlertViewStylePlainTextInput;
		[av textFieldAtIndex:0].text = [NSString stringWithFormat:@"1,500,20"];
		[av textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumbersAndPunctuation;
		[av show];
	}];

	[self.view addSubview:aBtn];
	[self.view addSubview:bBtn];
	[self.view addSubview:cBtn];

	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[aBtn]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(aBtn)]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bBtn]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(bBtn)]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cBtn]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(cBtn)]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[aBtn]-[bBtn]-[cBtn]-64-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(aBtn, bBtn, cBtn)]];

#pragma mark Spark
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spark.io/v1/devices/%@/events/?access_token=%@", kSparkDevice, kSparkToken]];
	EventSource *eventSource = [EventSource eventSourceWithURL:url];
	[eventSource addEventListener:@"sousInfo" handler:^(Event *event) {
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[event.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];

		NSArray *arr = [[json objectForKey:@"data"] componentsSeparatedByString:@"|"];
		[_currentTemp addObject:arr[0]];
		[_targetTemp addObject:arr[1]];

		_pidLabel.text = [NSString stringWithFormat:@"Current: %@ºC\nTarget: %@ºC\nPower: %@%%", arr[0], arr[1], arr[2]];
		_tuneLabel.text = [NSString stringWithFormat:@"kP: %@\nkI: %@\nkD: %@", arr[3], arr[4], arr[5]];
		p = arr[3];
		i = arr[4];
		d = arr[5];

		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:[arr[6] boolValue]];

		[_chartView reloadData];
	}];
}

- (void)sendCommand:(NSString *)cmd withArgs:(NSString *)arguments {
	NSString *postStr = [NSString stringWithFormat:@"args=%@", arguments];
	NSData *postData = [postStr dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURLString:[NSString stringWithFormat:@"https://api.spark.io/v1/devices/%@/%@", kSparkDevice, cmd] accessToken:kSparkToken];
	req.HTTPMethod = @"POST";
	[req setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
	req.HTTPBody = postData;

	[[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		NSLog(@"%@", response);
		if (data) {
			NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			NSLog(@"dataStr: %@", dataStr);
		}
		else {
			NSLog(@"no data %@", error.localizedDescription);
		}
	}] resume];
}

#pragma mark - JBLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
	return 2;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
	if (lineIndex == 0) {
		return _targetTemp.count;
	}
	return _currentTemp.count;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
	if (lineIndex == 0) {
		return [[_targetTemp objectAtIndex:horizontalIndex] floatValue];
	}
	return [[_currentTemp objectAtIndex:horizontalIndex] floatValue];
}

#pragma mark - JBLineChartViewDelegate

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
	return YES;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex {
	if (lineIndex == 0) {
		return [UIColor redColor];
	}
	return self.view.tintColor;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex {
	return 2.0f;
}

@end
