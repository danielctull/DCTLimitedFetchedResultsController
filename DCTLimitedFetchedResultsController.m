//
//  DCTLimitedFetchedResultsController.m
//  DCTLimitedFetchedResultsController
//
//  Created by Daniel Tull on 13.07.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTLimitedFetchedResultsController.h"

@interface DCTLimitedFetchedResultsController () <NSFetchedResultsControllerDelegate>
@end

@implementation DCTLimitedFetchedResultsController {
    __strong NSArray *fetchedObjects;
	__strong NSFetchedResultsController *fetchedResultsController;
}

@synthesize limit;

#pragma mark - NSFetchedResultsController

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest
      managedObjectContext:(NSManagedObjectContext *)context
        sectionNameKeyPath:(NSString *)sectionNameKeyPath 
                 cacheName:(NSString *)name {
    
	if (!(self = [self initWithFetchRequest:fetchRequest
                       managedObjectContext:context
                         sectionNameKeyPath:nil
                                  cacheName:nil])) return nil;
	
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																   managedObjectContext:context
																	 sectionNameKeyPath:nil
																			  cacheName:name];
	fetchedResultsController.delegate = self;
	
	return self;
}

- (BOOL)performFetch:(NSError **)error {
	
	if (![fetchedResultsController performFetch:error]) return NO;
	
	fetchedObjects = [fetchedResultsController.fetchedObjects subarrayWithRange:NSMakeRange(0, self.limit)];
	
	return YES;	
}

- (NSIndexPath *)indexPathForObject:(id)object {
    NSUInteger row = [self.fetchedObjects indexOfObject:object];
    return [NSIndexPath indexPathForRow:row inSection:0];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.fetchedObjects objectAtIndex:indexPath.row];
}

- (NSArray *)fetchedObjects {
    return fetchedObjects;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.delegate controllerWillChangeContent:self];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.delegate controllerDidChangeContent:self];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)object
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
	if (type == NSFetchedResultsChangeInsert) {
		
		if (newIndexPath.row >= self.limit) return;
		
		NSMutableArray *array = [self.fetchedObjects mutableCopy];
		[array insertObject:object atIndex:indexPath.row];
		fetchedObjects = [array copy];
		
		[self.delegate controller:self
				  didChangeObject:object
					  atIndexPath:nil
					forChangeType:NSFetchedResultsChangeInsert
					 newIndexPath:newIndexPath];
			
		if ([self.fetchedObjects count] <= self.limit) return;
		
		id lastObject = [self.fetchedObjects lastObject];
		
		array = [self.fetchedObjects mutableCopy];
		[array removeObject:lastObject];
		fetchedObjects = [array copy];
		
		[self.delegate controller:self
				  didChangeObject:lastObject
					  atIndexPath:[NSIndexPath indexPathForRow:(self.limit-1) inSection:0]
					forChangeType:NSFetchedResultsChangeDelete
					 newIndexPath:nil];
		
		
	} else if (type == NSFetchedResultsChangeDelete) {
		
		if (indexPath.row >= self.limit) return;
		
		NSMutableArray *array = [self.fetchedObjects mutableCopy];
		[array removeObject:object];
		fetchedObjects = [array copy];
		
		[self.delegate controller:self
				  didChangeObject:object
					  atIndexPath:indexPath
					forChangeType:NSFetchedResultsChangeDelete
					 newIndexPath:nil];
		
		NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.limit-1 inSection:0];
		id newObject = [fetchedResultsController objectAtIndexPath:lastIndexPath];
		
		[self controller:controller
		 didChangeObject:newObject
			 atIndexPath:nil
		   forChangeType:NSFetchedResultsChangeInsert
			newIndexPath:lastIndexPath];
				
	} else if (type == NSFetchedResultsChangeUpdate) {
		
		if (indexPath.row >= self.limit) return;
		
		[self.delegate controller:self
				  didChangeObject:object
					  atIndexPath:indexPath
					forChangeType:NSFetchedResultsChangeUpdate
					 newIndexPath:newIndexPath];
		
	} else if (type == NSFetchedResultsChangeMove) {
		
		if (indexPath.row >= self.limit && newIndexPath.row >= self.limit) return;
		
		if (indexPath.row >= self.limit) {

			// INSERTION -- Call self with the change type set to insert
			
			[self controller:controller
			 didChangeObject:object
				 atIndexPath:indexPath
			   forChangeType:NSFetchedResultsChangeInsert
				newIndexPath:newIndexPath];
			
		} else if (newIndexPath.row >= self.limit) {

			// DELETION -- Call self with the change type set to delete
			
			[self controller:controller
			 didChangeObject:object
				 atIndexPath:indexPath
			   forChangeType:NSFetchedResultsChangeDelete
				newIndexPath:newIndexPath];
			
		} else {
			
			// ACTUAL MOVE -- Within our subset of objects
			
			[self.delegate controller:self
					  didChangeObject:object
						  atIndexPath:indexPath
						forChangeType:NSFetchedResultsChangeMove
						 newIndexPath:newIndexPath];
		}
		
		
		
		
	}
}


@end
