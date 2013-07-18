//
//  ViewController.mm
//  OpenCVTest
//
//  Created by James Robertson on 6/13/13.
//  Copyright (c) 2013 James Robertson. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;
@synthesize button;
@synthesize videoCamera;
@synthesize typeOfDraw;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:@"Welcome to OpenCV" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil];
//    [alert show];
    
    //delegate
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.delegate = self;
    
    //camera options
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    self.isOn = FALSE;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma detect rectangle methods


int thresh = 50, N = 11;
const char* wndname = "Square Detection Demo";

// helper function:
// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
static double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

// returns sequence of squares detected on the image.
// the sequence is stored in the specified memory storage
static void findSquares( const cv::Mat& image, cv::vector<cv::vector<cv::Point> >& squares )
{
    squares.clear();
    
    cv::Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    
    // down-scale and upscale the image to filter out the noise
    pyrDown(image, pyr, cv::Size(image.cols/2, image.rows/2));
    pyrUp(pyr, timg, image.size());
    cv::vector<cv::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for( int c = 0; c < 3; c++ )
    {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        for( int l = 0; l < N; l++ )
        {
            // hack: use Canny instead of zero threshold level.
            // Canny helps to catch squares with gradient shading
            if( l == 0 )
            {
                // apply Canny. Take the upper threshold from slider
                // and set the lower to 0 (which forces edges merging)
                Canny(gray0, gray, 0, thresh, 5);
                // dilate canny output to remove potential
                // holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else
            {
                // apply threshold if l!=0:
                //     tgray(x,y) = gray(x,y) < (l+1)*255/N ? 255 : 0
                gray = gray0 >= (l+1)*255/N;
            }
            
            // find contours and store them all as a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            cv::vector<cv::Point> approx;
            
            // test each contour
            for( size_t i = 0; i < contours.size(); i++ )
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                
                // square contours should have 4 vertices after approximation
                // relatively large area (to filter out noisy contours)
                // and be convex.
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if( approx.size() == 4 &&
                   fabs(contourArea(cv::Mat(approx))) > 1000 &&
                   isContourConvex(cv::Mat(approx)) )
                {
                    double maxCosine = 0;
                    
                    for( int j = 2; j < 5; j++ )
                    {
                        // find the maximum cosine of the angle between joint edges
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    // if cosines of all angles are small
                    // (all angles are ~90 degree) then write quandrange
                    // vertices to resultant sequence
                    if( maxCosine < 0.3 )
                        squares.push_back(approx);
                }
            }
        }
    }
}


// the function draws all the squares in the image
static void drawSquares( cv::Mat& image, const cv::vector<cv::vector<cv::Point> >& squares )
{
    for( size_t i = 0; i < squares.size(); i++ )
    {
        const cv::Point* p = &squares[i][0];
        int n = (int)squares[i].size();
        polylines(image, &p, &n, 1, true, cv::Scalar(0,255,0), 3, CV_AA);
    }
    
    //imshow(wndname, image);
}


#pragma show on screen

- (IBAction)actionStart:(id)sender {
    if (self.isOn) {
        [self.videoCamera stop];
        self.isOn = FALSE;
        [self.button setTitle:@"On" forState:UIControlStateNormal];
    }
    else{
        [self.videoCamera start];
        self.isOn = TRUE;
        [self.button setTitle:@"Off" forState:UIControlStateNormal];
    }
}

- (void)processImage:(cv::Mat&)image;
{
    cv::Mat image_copy;

    
    /*---------------------------------------------------------STANDARD HLT-------------------------------------------------------------------------------------------*/
    if(typeOfDraw.selectedSegmentIndex == 0){

        //blurry
        cv::GaussianBlur(image, image_copy, cv::Size(5, 5), 1.2, 1.2);
        cv::bitwise_not(image_copy, image_copy);
        //chalk
        cv::Canny(image_copy, image_copy, 50, 70);

        
        cv::vector<cv::Vec2f> lines;
        HoughLines(image_copy, lines, 1, CV_PI/180, 100, 0, 0 );
        
        //Convert to correct image type
        cvtColor(image_copy, image_copy, CV_GRAY2BGR);
        
        //image_copy.copyTo(image);
        
        for( size_t i = 0; i < lines.size(); i++ )
        {
            float rho = lines[i][0], theta = lines[i][1];
            cv::Point pt1, pt2;
            double a = cos(theta), b = sin(theta);
            double x0 = a*rho, y0 = b*rho;
            pt1.x = cvRound(x0 + 1000*(-b));
            pt1.y = cvRound(y0 + 1000*(a));
            pt2.x = cvRound(x0 - 1000*(-b));
            pt2.y = cvRound(y0 - 1000*(a));
            line(image, pt1, pt2, cv::Scalar(94, 206, 165), 3, CV_AA);
        }
    }
    
/*---------------------------------------------------------PARABOLIC HLT-------------------------------------------------------------------------------------------*/    
    
    if(typeOfDraw.selectedSegmentIndex == 1){

        //blurry
        cv::GaussianBlur(image, image_copy, cv::Size(5, 5), 1.2, 1.2);
        cv::bitwise_not(image_copy, image_copy);
        //chalk
        cv::Canny(image_copy, image_copy, 50, 70);

        cv::vector<cv::Vec4i> lines;
        HoughLinesP(image_copy, lines, 1, CV_PI/180, 50, 50, 10 );
        //cvtColor(image, image, CV_GRAY2BGR);

        for( size_t i = 0; i < lines.size(); i++ )
        {
            cv::Vec4i l = lines[i];
            line( image, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), cv::Scalar(0,0,255), 3, CV_AA);
        }
    }
    
/*---------------------------------------------------------CORNERS-------------------------------------------------------------------------------------------*/
    
    if(typeOfDraw.selectedSegmentIndex == 2){

        //blurry
        cv::GaussianBlur(image, image, cv::Size(5, 5), 1.2, 1.2);
        //cv::bitwise_not(image, image);
        //chalk
        cv::Canny(image, image, 50, 70);

        /// Detector parameters
        int blockSize = 2;
        int apertureSize = 3;
        double k = 0.04;
                
        /// Detecting corners
        cv::Mat image_norm;
        cv::Mat image_scaled;
        cv::Mat image_copy;
        cv::Mat image_gray;
        cv::Mat image_dst;

        //image = cv::Mat::zeros( image.size(), CV_32FC1 );
        
        cornerHarris( image, image_copy, blockSize, apertureSize, k, cv::BORDER_DEFAULT );

        /// Normalizing
        normalize( image_copy, image_copy, 0, 255, cv::NORM_MINMAX, CV_32FC1, cv::Mat() );
        convertScaleAbs(image_copy, image_copy);
        cvtColor(image_copy, image_copy, CV_GRAY2BGR);

        /// Drawing a circle around corners
        for( int j = 0; j < image_copy.rows ; j++ )
        { for( int i = 0; i < image_copy.cols; i++ )
        {
            if( (int) image_copy.at<float>(j,i) > 200 /*threshold*/ )
            {
                circle( image, cv::Point( i, j ), 5,  cv::Scalar(94, 206, 165), 2, 8, 0 );
            }
        }
        }
    
    }
    
    /*---------------------------------------------------------INVERTED-------------------------------------------------------------------------------------------*/
    
    if(typeOfDraw.selectedSegmentIndex == 3){

        // Do some OpenCV stuff with the image
        cvtColor(image, image_copy, CV_BGRA2BGR);
        
        // invert image
        bitwise_not(image_copy, image_copy);
        cvtColor(image_copy, image, CV_BGR2BGRA);
        
        
        //blurry
        GaussianBlur( image, image, cv::Size(3,3), 0, 0, cv::BORDER_DEFAULT );
        //cv::bitwise_not(image, image);
        //chalk
        //cv::Canny(image, image, 50, 70);
        
    }
    
    /*---------------------------------------------------------LINES-------------------------------------------------------------------------------------------*/
    
    if(typeOfDraw.selectedSegmentIndex == 4){

        // Do some OpenCV stuff with the image
        cvtColor(image, image_copy, CV_BGRA2BGR);

        //blurry
        GaussianBlur( image, image, cv::Size(3,3), 0, 0, cv::BORDER_DEFAULT );
        //chalk
        cv::Canny(image, image, 50, 70);
        
    }
    
    /*---------------------------------------------------------SQUARES-------------------------------------------------------------------------------------------*/
    
    if(typeOfDraw.selectedSegmentIndex == 5){
        cv::vector<cv::vector<cv::Point> > squares;
        findSquares(image, squares);
        drawSquares(image, squares);

    }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}


- (IBAction)changePerspective:(id)sender {
    if(self.perpective.selectedSegmentIndex == 0)
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    if(self.perpective.selectedSegmentIndex == 1)
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
}
@end
