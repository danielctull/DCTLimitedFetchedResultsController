//
//  DCTLimitedFetchedResultsController.h
//  DCTLimitedFetchedResultsController
//
//  Created by Daniel Tull on 13.07.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface DCTLimitedFetchedResultsController : NSFetchedResultsController

@property (nonatomic, assign) NSUInteger limit;

@end
