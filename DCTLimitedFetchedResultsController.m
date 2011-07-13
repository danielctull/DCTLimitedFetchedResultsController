//
//  DCTLimitedFetchedResultsController.m
//  DCTLimitedFetchedResultsController
//
//  Created by Daniel Tull on 13.07.2011.
//  Copyright 2011 Daniel Tull. All rights reserved.
//

#import "DCTLimitedFetchedResultsController.h"

@interface DCTLimitedFetchedResultsController ()
- (void)dctInternal_managedObjectContextDidChangeNotification:(NSNotification *)notification;

- (void)dctInternal_deletedObjects:(NSSet *)deletedObjects;
- (void)dctInternal_insertedObjects:(NSSet *)insertedObjects;
- (void)dctInternal_updatedObjects:(NSSet *)updatedObjects;
- (void)dctInternal_refreshedObjects:(NSSet *)refreshedObjects;

- (void)dctInternal_sendInsertionOfObject:(id)object index:(NSUInteger)index;
- (void)dctInternal_sendDeletionOfObject:(id)object index:(NSUInteger)index;

@end

@implementation DCTLimitedFetchedResultsController {
    __strong NSArray *fetchedObjects;
}

@synthesize limit;

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSManagedObjectContextObjectsDidChangeNotification
												  object:self.managedObjectContext];
}

#pragma mark - NSFetchedResultsController

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest
      managedObjectContext:(NSManagedObjectContext *)context
        sectionNameKeyPath:(NSString *)sectionNameKeyPath 
                 cacheName:(NSString *)name {
    
	if (!(self = [self initWithFetchRequest:fetchRequest
                       managedObjectContext:context
                         sectionNameKeyPath:sectionNameKeyPath
                                  cacheName:name])) return nil;
	
	self.limit = fetchRequest.fetchLimit;
	
	return self;
}

- (BOOL)performFetch:(NSError **)error {
	
	NSArray *objects = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:error];
	
	if (!objects) return NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(dctInternal_managedObjectContextDidChangeNotification:) 
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.managedObjectContext];
	
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

#pragma mark - DCTLimitedFetchedResultsController

- (void)dctInternal_managedObjectContextDidChangeNotification:(NSNotification *)notification {
	
	[self.delegate controllerWillChangeContent:self];
	
	NSDictionary *userInfo = [notification userInfo];
	
	NSSet *deletedObjects = [userInfo objectForKey:NSDeletedObjectsKey];
	[self dctInternal_deletedObjects:deletedObjects];
	
	NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
	[self dctInternal_insertedObjects:insertedObjects];
	
	NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
	[self dctInternal_updatedObjects:updatedObjects];
	
	NSSet *refreshedObjects = [userInfo objectForKey:NSRefreshedObjectsKey];
	[self dctInternal_refreshedObjects:refreshedObjects];
	
	[self.delegate controllerDidChangeContent:self];
	
	/*
	NSMutableArray *objects = [fetchedObjects mutableCopy];
	
	NSMutableArray *deletedIndexes = [[NSMutableArray alloc] initWithCapacity:[updatedObjects count]];
	
	[objects addObjectsFromArray:[insertedObjects allObjects]];*/
	
	
}

- (void)dctInternal_deletedObjects:(NSSet *)deletedObjects {
	
	NSMutableArray *objects = [fetchedObjects mutableCopy];
		
	[objects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
		if ([deletedObjects containsObject:object])
			[self dctInternal_sendDeletionOfObject:object index:index];
	}];
	
	[objects removeObjectsInArray:[deletedObjects allObjects]];
	fetchedObjects = [objects copy];
	
	if ([fetchedObjects count] == self.limit) return; // Needless check?
	
	
	NSArray *originalFetchedObjects = fetchedObjects;	
	
	NSArray *newFetchedObjects = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:nil];
	[objects addObjectsFromArray:newFetchedObjects];
	[objects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
	fetchedObjects = [objects subarrayWithRange:NSMakeRange(0, self.limit)];
	
	
	[fetchedObjects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
		if (![originalFetchedObjects containsObject:object])
			[self dctInternal_sendInsertionOfObject:object index:index];
	}];
}

- (void)dctInternal_insertedObjects:(NSSet *)insertedObjects {
	
	NSArray *originalFetchedObjects = fetchedObjects;
	
	NSMutableArray *objects = [fetchedObjects mutableCopy];
	[objects addObjectsFromArray:[insertedObjects allObjects]];
	[objects sortUsingDescriptors:self.fetchRequest.sortDescriptors];
	fetchedObjects = [objects subarrayWithRange:NSMakeRange(0, self.limit)];
	
	[originalFetchedObjects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
		if (![fetchedObjects containsObject:object])
			[self dctInternal_sendDeletionOfObject:object index:index];
	}];
	
	[fetchedObjects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
		if (![originalFetchedObjects containsObject:object])
			[self dctInternal_sendInsertionOfObject:object index:index];
	}];
}

- (void)dctInternal_updatedObjects:(NSSet *)updatedObjects {}

- (void)dctInternal_refreshedObjects:(NSSet *)refreshedObjects {}

- (void)dctInternal_sendInsertionOfObject:(id)object index:(NSUInteger)index {}

- (void)dctInternal_sendDeletionOfObject:(id)object index:(NSUInteger)index {
	
	NSIndexPath *ip = [NSIndexPath indexPathForRow:index inSection:0];
	[self.delegate controller:self 
			  didChangeObject:object
				  atIndexPath:ip
				forChangeType:NSFetchedResultsChangeDelete
				 newIndexPath:nil];
}


@end
