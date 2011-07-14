//
//  MasterViewController.h
//  DCTLimitedFetchedResultsControllerDemo
//
//  Created by Daniel Tull on 14.07.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
