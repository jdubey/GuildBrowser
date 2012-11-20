//
//  GuildTests.m
//  GuildBrowser
//
//  Created by Joshua Dubey on 11/19/12.
//  Copyright (c) 2012 Charlie Fulton. All rights reserved.
//

#import "GuildTests.h" 
#import "WoWApiClient.h" 
#import <OCMock/OCMock.h> 
#import "Guild.h"
#import "TestSemaphor.h" 
#import "Character.h"

@implementation GuildTests
{
    // 1
    Guild *_guild;
    NSDictionary *_testGuildData;
}

- (void)setUp
{
    // Read from file
    NSURL *dataServiceURL = [[NSBundle bundleForClass:self.class] URLForResource:@"guild" withExtension:@"json"];
    NSData *sampleData = [NSData dataWithContentsOfURL:dataServiceURL];
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:sampleData options:kNilOptions error:&error];
    _testGuildData = json;
}

- (void)tearDown
{
    // Tear-down code here.
    _guild = nil;
    _testGuildData = nil;
}

- (void)testCreatingGuildDataFromWowApiClient
{
    // Create a mock object that will be used just like a real instance of WowApiClient. Any method that you call on this instance needs to be defined – you do this in step 2.
    id mockWowApiClient = [OCMockObject mockForClass:[WoWApiClient class]];
    //
    // using OCMock to mock our WowApiClient object
    //
    // Define what you want to happen when you call the guildWithName:onRealm:success:error method on your mock instance of WowApiClient. If you call methods on the mock object that you hadn’t previously defined, you will get exceptions. If you don’t want that to happen, you can create a “nice” instance of your class by calling niceMockForClass instead of mockForClass. So when you call the guildWithName:onRealm:success:error method, you define what you want to happen in the OCMock stub’s andDo: invocation block.
    [[[mockWowApiClient stub] andDo:^(NSInvocation *invocation) {
        
        // how the success block is defined from our client
        // this is how we return data to caller from stubbed method
        // 3
        void (^successBlock)(Guild *guild);
        
        //
        // gets the success block from the call to our stub method
        // The hidden arguments self (of type id) and _cmd (of type SEL) are at indices 0 and 1;
        // method-specific arguments begin at index 2.
        // Note that the successBlock is the fourth argument when starting at index 2 (guildWithName = 2, onRealm = 3, success = 4).
        // store this reference into the block type defined in step 3.
        [invocation getArgument:&successBlock atIndex:4];
        
        // first create sample guild from file vs network call
        // 5
        Guild *testData = [[Guild alloc] initWithGuildData:_testGuildData];
        
        // Guild instance is now passed to the successBlock you previously got a reference to in step 4.
        successBlock(testData); }]
     
     
     // 7
     // the actual method we are stubb'ing, accepting any args.  Note that this is continuing the method call that begins in step 2 – it’s just that one of the arguments contained a block of code, which made it span so many lines. All the [OCMArg any] parameters indicate that you will allow any type of argument to be passed into your mock and that there are no constraints.
     guildWithName:[OCMArg any]
     onRealm:[OCMArg any]
     success:[OCMArg any]
     error:[OCMArg any]];
    
    // String used to wait for block to complete
    
    // The execution of the success block once the test completes will be asynchronous. Without adding some sort of “wait” or timeout, the test will not wait for the block to come back.
    // That’s where the TestSemaphor object, mentioned previously, comes in. It’s really simple to use. You create a string value to wait for, and when your call is done – in this case, when you get returned to your success block – you “lift” this string.
    // The semaphoreKey as the key to a gate blocking you, or rather, blocking the test. The test waits until it receives the key to proceed further, and you send the key to the test in step 11.
    NSString *semaphoreKey = @"membersLoaded";
    
    //
    // now call the stubbed out client, by calling the real method //
    // 9
    [mockWowApiClient guildWithName:@"Dream Catchers"
                            onRealm:@"Borean Tundra"
                            success:^(Guild *guild)
    {
        // When the method returns via the success block, you will have the Guild object all set up and ready to use. Now you can test it to make sure that the returned data is correct.
        _guild = guild;
        
        // Now that the data we are waiting for is here, this will allow the test to continue by lifting the semaphore key
        // and satisfying the running loop that is waiting on it to lift
        [[TestSemaphor sharedInstance] lift:semaphoreKey];
    } error:^(NSError *error) {
        // also lift the semaphore if the error block returned instead.
        [[TestSemaphor sharedInstance] lift:semaphoreKey];
    }];
    
    // You saw in steps 11 and 12 that you lift the semaphoreKey when the block is done. In order to make the test wait for this to happen, you have to first set the semaphore to wait. You do this by calling waitForKey and passing in the string value that will lift the key. The test will wait at this step until the semaphoreKey is lifted.
    [[TestSemaphor sharedInstance] waitForKey:semaphoreKey];
    
    // Done waiting for semaphore, start testing.
    STAssertNotNil(_guild, @"");
    STAssertEqualObjects(_guild.name, @"Dream Catchers", nil);
    STAssertTrue([_guild.members count] == [[_testGuildData valueForKey:@"members"] count], nil);
    
    // Now validate that each type of class was loaded in the correct order
    // this tests the calls that our CharacterViewController will be making
    // for the UICollectionViewDataSource methods //
    // 15
    //
    // Validate 1 Death Knight ordered by level, acheivement points
    //
    NSArray *characters = [_guild membersByWowClassTypeName:WowClassTypeDeathKnight];
    STAssertEqualObjects(((Character *)characters[0]).name,@"Lixiu",nil);
    
    //
    // Validate 3 Druids ordered by level, acheivement points
    //
    characters = [_guild membersByWowClassTypeName:WowClassTypeDruid];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Elassa", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Ivymoon", nil);
    STAssertEqualObjects(((Character*)characters[2]).name, @"Everybody", nil);
    
    //
    // Validate 2 Hunter ordered by level, acheivement points
    //
    characters = [_guild membersByWowClassTypeName:WowClassTypeHunter];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Bulldogg", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Bluekat", nil);
    
    //
    // Validate 2 Mage ordered by level, acheivement points
    //
    characters = [_guild membersByWowClassTypeName:WowClassTypeMage];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Mirai", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Greatdane", nil);
    
    //
    // Validate 3 Paladin ordered by level, acheivement points
    //
    characters = [_guild membersByWowClassTypeName:WowClassTypePaladin];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Verikus", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Jonan", nil);
    STAssertEqualObjects(((Character*)characters[2]).name, @"Desplaines", nil);
    
    //
    // Validate 3 Priest ordered by level, acheivement points
    //
    characters = [_guild membersByWowClassTypeName:WowClassTypePriest];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Mercpriest", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Monk", nil);
    STAssertEqualObjects(((Character*)characters[2]).name, @"Bliant", nil);
    
    //
    // Validate 3 Rogue ordered by level, acheivement points
    //
    characters = [_guild membersByWowClassTypeName:WowClassTypeRogue];
    STAssertEqualObjects(((Character*)characters[0]).name, @"Lailet", nil);
    STAssertEqualObjects(((Character*)characters[1]).name, @"Britaxis", nil);
    STAssertEqualObjects(((Character*)characters[2]).name, @"Josephus", nil);
}
@end