//
//  CDNetworkDataLoader.m
//  Coursera Due
//
//  Created by Yuri Karabatov on 23.01.14.
//  Copyright (c) 2014 Yuri Karabatov. All rights reserved.
//

#import "CDNetworkDataLoader.h"
#import "CDOAuthConstants.h"
#import "AFOAuth2Client/AFOAuth2Client.h"

static CDNetworkDataLoader *sharedLoader = nil;

@interface CDNetworkDataLoader ()

@property (nonatomic, strong, readwrite) RKObjectManager *maestroManager;
@property (nonatomic, strong, readwrite) RKObjectManager *enrollmentManager;

@end

@implementation CDNetworkDataLoader

+ (instancetype)sharedLoader
{
    return sharedLoader;
}

+ (void)setSharedLoader:(CDNetworkDataLoader *)loader
{
    sharedLoader = loader;
}

- (id)initWithCoursera
{
    self = [super init];
    if (self) {

        // Setup new RKObjectManager for Courses and Topics

        NSURL *maestroBaseURL = [NSURL URLWithString:@"https://www.coursera.org"];
        RKObjectManager *maestroNewManager = [RKObjectManager managerWithBaseURL:maestroBaseURL];
        maestroNewManager.managedObjectStore = [RKManagedObjectStore defaultStore];

        // Entity mapping: Topic

        RKEntityMapping *topicMapping = [RKEntityMapping mappingForEntityForName:@"Topic"
                                                            inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        topicMapping.forceCollectionMapping = YES;
        [topicMapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"id"];
        [topicMapping addAttributeMappingsFromDictionary:@{
                                                           @"(id).name": @"name",
                                                           @"(id).photo": @"photo",
                                                           @"(id).large_icon": @"largeIcon"
                                                           }];
        topicMapping.identificationAttributes = @[ @"id" ];

        RKResponseDescriptor *topicDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:topicMapping method:RKRequestMethodAny pathPattern:@"/maestro/api/topic/list2" keyPath:@"topics" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [maestroNewManager addResponseDescriptor:topicDescriptor];

        // Entity mapping: simple Topic

        RKEntityMapping *simpleTopicMapping = [RKEntityMapping mappingForEntityForName:@"Topic"
                                                                  inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [simpleTopicMapping addAttributeMappingsFromDictionary:@{
                                                                 @"topic_id": @"id",
                                                                 }];
        simpleTopicMapping.identificationAttributes = @[ @"id" ];

        // Entity mapping: Course

        RKEntityMapping *courseMapping = [RKEntityMapping mappingForEntityForName:@"Course"
                                                             inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [courseMapping addAttributeMappingsFromDictionary:@{
                                                            @"id": @"id",
                                                            @"home_link": @"homeLink",
                                                            }];
        courseMapping.identificationAttributes = @[ @"id" ];
        [courseMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil
                                                                                      toKeyPath:@"topicId"
                                                                                    withMapping:simpleTopicMapping]];

        RKResponseDescriptor *courseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:courseMapping method:RKRequestMethodAny pathPattern:@"/maestro/api/topic/list2" keyPath:@"courses" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [maestroNewManager addResponseDescriptor:courseDescriptor];

        self.maestroManager = maestroNewManager;

        // Setup new RKObjectManager for Enrollments

        NSURL *enrollmentBaseURL = [NSURL URLWithString:@"https://api.coursera.org"];
        RKObjectManager *enrollmentNewManager = [RKObjectManager managerWithBaseURL:enrollmentBaseURL];
        enrollmentNewManager.managedObjectStore = [RKManagedObjectStore defaultStore];

        // Entity mapping: simple Topic 2

        RKEntityMapping *simpleTopicMapping2 = [RKEntityMapping mappingForEntityForName:@"Topic"
                                                                   inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [simpleTopicMapping2 addAttributeMappingsFromDictionary:@{
                                                                  @"courseId": @"id",
                                                                  }];
        simpleTopicMapping2.identificationAttributes = @[ @"id" ];


        // Entity mapping: simple Course

        RKEntityMapping *simpleCourseMapping = [RKEntityMapping mappingForEntityForName:@"Course"
                                                                   inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [simpleCourseMapping addAttributeMappingsFromDictionary:@{
                                                                  @"sessionId": @"id",
                                                                  }];
        simpleCourseMapping.identificationAttributes = @[ @"id" ];

        // Entity mapping: Enrollment

        RKEntityMapping *enrollmentMapping = [RKEntityMapping mappingForEntityForName:@"Enrollment"
                                                                 inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [enrollmentMapping addAttributeMappingsFromDictionary:@{
                                                                @"id": @"id",
                                                                @"isSigTrack": @"isSignatureTrack",
                                                                @"startDate": @"startDate",
                                                                @"endDate": @"endDate",
                                                                @"startStatus": @"startStatus"
                                                                }];
        enrollmentMapping.identificationAttributes = @[ @"id" ];
        [enrollmentMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil
                                                                                          toKeyPath:@"sessionId"
                                                                                        withMapping:simpleCourseMapping]];
        [enrollmentMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil
                                                                                          toKeyPath:@"courseId"
                                                                                        withMapping:simpleTopicMapping2]];

        RKResponseDescriptor *enrollmentDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:enrollmentMapping method:RKRequestMethodAny pathPattern:@"/api/users/v1/me/enrollments" keyPath:@"enrollments" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [enrollmentNewManager addResponseDescriptor:enrollmentDescriptor];

        self.enrollmentManager = enrollmentNewManager;

        // Hydrate the Shared Loader

        if (nil == sharedLoader) {
            [CDNetworkDataLoader setSharedLoader:self];
        }
    }

    return self;
}

- (void)getPublicCourses
{
    [self.maestroManager getObjectsAtPath:@"/maestro/api/topic/list2" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"Mapping Result: %@", mappingResult.array);
    } failure:nil];

}

- (void)getMyEnrollments
{
    // Initialize OAuth2 client for testing purposes

    NSURL *url = [NSURL URLWithString:@"https://accounts.coursera.org"];
    AFOAuth2Client *oauthClient = [AFOAuth2Client clientWithBaseURL:url clientID:kClientId secret:kClientSecret];

    [oauthClient authenticateUsingOAuthWithPath:@"/oauth2/v1/token"
                                       username:kClientEmail
                                       password:kClientPassword
                                          scope:@"password"
                                        success:^(AFOAuthCredential *credential) {
                                            NSLog(@"I have a token! %@", credential.accessToken);
                                            [AFOAuthCredential storeCredential:credential withIdentifier:oauthClient.serviceProviderIdentifier];

                                            // Setup authorization for Enrollments

                                            [self.enrollmentManager.HTTPClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", credential.accessToken]];

                                            // Execute operation

                                            RKObjectRequestOperation *operation = [self.enrollmentManager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/api/users/v1/me/enrollments" parameters:nil];
                                            [self.enrollmentManager enqueueObjectRequestOperation:operation];

                                        }
                                        failure:^(NSError *error) {
                                            NSLog(@"Error: %@", error);
                                        }];
}

@end