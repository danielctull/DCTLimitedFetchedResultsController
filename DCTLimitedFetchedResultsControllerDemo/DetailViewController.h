//
//  DetailViewController.h
//  DCTLimitedFetchedResultsControllerDemo
//
//  Created by Daniel Tull on 14.07.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
