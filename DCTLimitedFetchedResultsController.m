/*
 DCTLimitedFetchedResultsController.m
 DCTLimitedFetchedResultsController
 
 Created by Daniel Tull on 13.07.2011.
 
 
 
 Copyright (c) 2011 Daniel Tull. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DCTLimitedFetchedResultsController.h"


@interface DCTLimitedFetchedResultsControllerSectionInfo : NSObject
@property (nonatomic, strong, readwrite) NSString *indexTitle;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) NSUInteger numberOfObjects;
@property (nonatomic, strong, readwrite) NSArray *objects;	
@end

@implementation DCTLimitedFetchedResultsControllerSectionInfo
@synthesize indexTitle;
@synthesize name;
@synthesize numberOfObjects;
@synthesize objects;
@end

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
    
	if (!(self = [super init])) return nil;
	
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																   managedObjectContext:context
																	 sectionNameKeyPath:nil
																			  cacheName:name];
	fetchedResultsController.delegate = self;
	
	return self;
}

- (BOOL)performFetch:(NSError **)error {
	
	if (![fetchedResultsController performFetch:error]) return NO;
	
	fetchedObjects = fetchedResultsController.fetchedObjects;
	
	if ([fetchedObjects count] >= self.limit)
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

- (NSManagedObjectContext *)managedObjectContext {
	return fetchedResultsController.managedObjectContext;
}

- (NSFetchRequest *)fetchRequest {
	return fetchedResultsController.fetchRequest;
}

- (NSString *)cacheName {
	return fetchedResultsController.cacheName;
}

- (NSString *)sectionNameKeyPath {
	return fetchedResultsController.sectionNameKeyPath;
}

- (NSArray *)sectionIndexTitles {
	return fetchedResultsController.sectionIndexTitles;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex {
	return 0;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName {
	return nil;
}

- (NSArray *)sections {
	DCTLimitedFetchedResultsControllerSectionInfo *info = [[DCTLimitedFetchedResultsControllerSectionInfo alloc] init];
	info.numberOfObjects = [fetchedObjects count];
	info.objects = fetchedObjects;
	return [NSArray arrayWithObject:info];
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
		
		//NSLog(@"%@:%@ INSERT: %@", self, NSStringFromSelector(_cmd), newIndexPath);
		
		NSMutableArray *array = [self.fetchedObjects mutableCopy];
		[array insertObject:object atIndex:newIndexPath.row];
		fetchedObjects = [array copy];
		
		//NSLog(@"%@:%@ %@", self, NSStringFromSelector(_cmd), fetchedObjects);
		
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
		
		//NSLog(@"%@:%@ DELETE: %@", self, NSStringFromSelector(_cmd), indexPath);
		
		if (indexPath.row >= self.limit) return;
		
		NSMutableArray *array = [self.fetchedObjects mutableCopy];
		[array removeObject:object];
		fetchedObjects = [array copy];
		
		[self.delegate controller:self
				  didChangeObject:object
					  atIndexPath:indexPath
					forChangeType:NSFetchedResultsChangeDelete
					 newIndexPath:newIndexPath];
		
		if ([self.fetchedObjects count] < self.limit-1) return;
		
		if ([self.fetchedObjects count] == [[[fetchedResultsController sections] objectAtIndex:0] numberOfObjects]) return;
				
		NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.limit-1 inSection:0];
		id newObject = [fetchedResultsController objectAtIndexPath:lastIndexPath];
		
		//NSLog(@"%@:%@ REFILL: %@", self, NSStringFromSelector(_cmd), lastIndexPath);
		
		lastIndexPath = [NSIndexPath indexPathForRow:self.limit-1 inSection:0];
		
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
