//
//  ViewController.h
//  OpenCVTest
//
//  Created by James Robertson on 6/13/13.
//  Copyright (c) 2013 James Robertson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#include "opencv2/core/core.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <iostream>
#include <math.h>
#include <string.h>

@interface ViewController : UIViewController <CvVideoCameraDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (strong, nonatomic) CvVideoCamera* videoCamera;
@property Boolean isOn;
- (IBAction)actionStart:(id)sender;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeOfDraw;
- (IBAction)changePerspective:(id)sender;
@property (strong, nonatomic) IBOutlet UISegmentedControl *perpective;

@end
