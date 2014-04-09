//
//  CDEnrollmentViewController.m
//  Coursera Due
//
//  Created by Yuri Karabatov on 31.01.14.
//  Copyright (c) 2014 Yuri Karabatov. All rights reserved.
//

#import "CDEnrollmentViewController.h"
#import "AFOAuth2Client/AFOAuth2Client.h"
#import "CDNetworkDataLoader.h"
#import "Enrollment.h"
#import "Topic.h"
#import "Course.h"
#import "Event.h"
#import "CDEnrollmentCell.h"
#import "UIImageView+AFNetworking.h"
#import "NSDateFormatter+RelativeDateFormat.h"

@interface CDEnrollmentViewController ()

@end

@implementation CDEnrollmentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.

         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    CDEnrollmentCell *newCell = (CDEnrollmentCell *)cell;
    newCell.eventNameLabel.text = event.eventSummary;
    newCell.dueDateLabel.text = [self.dateFormatter relativeStringFromDateIfPossible:event.endDate];
    newCell.courseNameLabel.text = [NSString stringWithFormat:@"🎓 %@", event.courseId.topicId.name];
    NSLog(@"event.isHardDeadline = %@", event.isHardDeadline);
    if ((nil != event.isHardDeadline) && ([event.isHardDeadline isEqualToNumber:@1])) {
        newCell.deadlineTypeLabel.text = @"DEADLINE";
        newCell.deadlineTypeLabel.textColor = [UIColor whiteColor];
        newCell.deadlineTypeLabel.backgroundColor = [UIColor blackColor];
        newCell.deadlineTypeLabel.layer.borderWidth = 0.0;
    } else {
        newCell.deadlineTypeLabel.text = @"DUE";
        newCell.deadlineTypeLabel.textColor = [UIColor blackColor];
        newCell.deadlineTypeLabel.backgroundColor = [UIColor clearColor];
        newCell.deadlineTypeLabel.layer.borderColor = [UIColor blackColor].CGColor;
        newCell.deadlineTypeLabel.layer.borderWidth = 1.0;
    }
    [newCell.courseImage setImageWithURL:[NSURL URLWithString:event.courseId.topicId.largeIcon] placeholderImage:[UIImage imageNamed:@"coursera.png"]];
    NSLog(@"Cell textLabel: %@, Cell detailLabel: %@", newCell.eventNameLabel.text, newCell.dueDateLabel.text);
    NSLog(@"Session startDate: %@", event.courseId.sessionId.startDate);
    NSLog(@"Session endDate: %@", [self.dateFormatter stringFromDate:event.courseId.sessionId.endDate]);
    NSLog(@"Session startStatus: %@", event.courseId.sessionId.startStatus);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CourseCell";

    /*
     Use a default table view cell to display the event's title.
     */
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static CDEnrollmentCell *sizingCell;
    static CGFloat height;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = (CDEnrollmentCell *)[tableView dequeueReusableCellWithIdentifier:@"CourseCell"];
        // configure the cell
        sizingCell.eventNameLabel.text = @"Some very very very very very very very long name";
        sizingCell.courseNameLabel.text = @"Some very very very very very very very long name";
        sizingCell.dueDateLabel.text = @"Some very very very very very very very long name";

        // force layout
        [sizingCell setNeedsLayout];
        [sizingCell layoutIfNeeded];

        height = 0;

        height += sizingCell.eventNameLabel.bounds.size.height;
        height += sizingCell.courseNameLabel.bounds.size.height;
        height += sizingCell.dueDateLabel.bounds.size.height;
        height += 8;
    });

    //NSLog(@"Cell height = %f", height);

    return height;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)configureFetchedResultsController
{
    /*
     Set up the fetched results controller.
     */

    NSLog(@"In configureFetchedResultsController");

    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *managedObjectContext = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType tracksChanges:YES];
    self.managedObjectContext = managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];

    // Sort using the startDate property.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor ]];

    // Filter
    [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(courseId != nil) && (endDate >= %@) && (courseId.sessionId != nil) && (courseId.sessionId.startStatus == %@) && (startDate <= courseId.sessionId.endDate)", [[NSDate alloc] init], @"Present"]];

    // Do not group results into sections
    NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];

    return newController;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
