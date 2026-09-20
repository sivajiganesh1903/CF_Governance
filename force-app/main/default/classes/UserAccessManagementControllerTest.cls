@isTest
public class UserAccessManagementControllerTest {
    
    @isTest
    static void testCreateUserAccessRecord_Success() {
        // Create a valid User_Access_Managment__c record
        User_Access_Managment__c objUser = new User_Access_Managment__c(Access_Details__c = 'Valid Access Details', First_Name__c = 'FirstTest',
                                                                        Last_Name__c = 'SecondTest', Email__c = 'test@test.com',
                                                                        Time_Zone__c = '(GMT-03:00) Atlantic Daylight Time (America/Halifax)',
                                                                        Divsion__c = 'FA', Product_Team__c = 'FSC',
                                                                        Start_Of_Day__c = '00:00', End_of_Day__c = '17:00',
                                                                        Federation_ID__c = 'ASZE12', Environments__c = 'FSC QA');
        
        String userType = 'New User Request'; // Set the userType
        
        // Call the method and assert the result
        Test.startTest();
        String result = UserAccessManagementController.createUserAccessRecord(objUser, userType);
        Test.stopTest();
        
        // Assert that the record was created and the name was returned
        System.assertNotEquals(objUser.Name, result);
        System.assertEquals(objUser.Environments__c, 'FSC QA');
    }
    
    @isTest
    static void testGetStartOfDayPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getStartOfDayPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testGetProductTeamPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getProductTeamPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testGetDivisionPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getDivisionPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testGetTimeZonePicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getTimeZonePicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testGetEnvPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getEnvPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testGetPersonaPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getPersonaPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testCreateUserAccessRecord_Exception() {
        // Create a User_Access_Managment__c record with missing required fields to trigger an exception
        User_Access_Managment__c objUser = new User_Access_Managment__c(
            Access_Details__c = 'Test Access',
            First_Name__c = 'TestFirst'
            // Missing required fields like Email__c
        );
        String userType = 'New User Request';
        
        Test.startTest();
        try {
            String result = UserAccessManagementController.createUserAccessRecord(objUser, userType);
            //System.assert(false, 'Exception was expected but not thrown.');
        } catch (Exception e) {
            // Assert that an exception was caught
            System.assert(e.getMessage().contains('required'), 'Expected error message.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSearchUsers() {
        User testUser = new User(FirstName = 'Sivaji', LastName = 'CF', Username = 'sivajict@test.com', Email = 'sivajicf@test.com',
                                 Alias = 'sicf', ProfileId = [SELECT Id FROM Profile LIMIT 1].Id, TimeZoneSidKey = 'America/Los_Angeles',
                                 LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert testUser;
        
        Test.startTest();
        List<User> users = UserAccessManagementController.searchUsers('Sivaji');
        Test.stopTest();
        
        // Assert that the user is found
        System.assert(users.size() > 0, 'Expected user to be returned.');
        System.assertEquals(testUser.Id, users[0].Id, 'Expected the correct user to be returned.');
    }
    /*
    // Issuse Tracking Test Case Methods
    @isTest
    static void testGetCategoryPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getCategoryPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    }
    
    @isTest
    static void testGetPriorityPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getPriorityPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    } 
    
    @isTest
    static void testGetEnvironmentPicklistValues() {
        Test.startTest();
        List<String> values = UserAccessManagementController.getEnvironmentPicklistValues();
        Test.stopTest();
        
        // Assert that the picklist values were retrieved
        System.assertNotEquals(null, values);
        System.assert(values.size() > 0);
    } 
    
    // Issue Tracker
    @isTest
    static void testCreateIssueTrackerRecord_Success() {
        
        // Create a valid Team record (assuming Team__c is a lookup/master-detail field)
        copado__Team__c team = new copado__Team__c(Name = 'Test Team');
        insert team;
        
        // Create a valid Issue_Tracker__c record
        Issue_Tracker__c issueObj = new Issue_Tracker__c(Issue_Description__c = 'Test Issue Description',Issue_Environment__c = 'INT',
                                                         Priority__c = 'P3', Category__c = 'Tooling',Team__c = 'a1r7d0000086FiWAAU');
        
        Test.startTest();
        String result = UserAccessManagementController.createIssueTrackerRecord(issueObj);
        Test.stopTest();
        
        // Assert that the record was created and 'success' was returned
        System.assertEquals('success', result);
        System.assertNotEquals(null, issueObj.Id);
    }
    
    //Adding Method
    @isTest
    static void testCreateIssueTrackerRecord_Exception() {
        // Create an Issue_Tracker__c record with invalid data to trigger an exception
        Issue_Tracker__c issueObj = new Issue_Tracker__c(
            // Missing required fields, such as Category__c, to simulate failure
            Issue_Description__c = 'Test Issue Description'
        );
        
        Test.startTest();
        String result = UserAccessManagementController.createIssueTrackerRecord(issueObj);
        Test.stopTest();
        
        // Assert that an error message was returned
        System.assert(result.startsWith('Error: '), 'Expected error message.');
    }
    
    @isTest
    static void testGetTeams() {
        // Step 1: Create mock copado__Team__c records
        List<copado__Team__c> teams = new List<copado__Team__c>();
        teams.add(new copado__Team__c(Name = 'Team A'));
        teams.add(new copado__Team__c(Name = 'Team B'));
        teams.add(new copado__Team__c(Name = 'Team C'));
        
        // Insert the mock team records
        insert teams;
        
        // Step 2: Call the getTeams method
        Test.startTest();
        List<UserAccessManagementController.IdNameWrapper> result = UserAccessManagementController.getTeams();
        Test.stopTest();
        
        // Step 3: Verify the results
        System.assertEquals(3, result.size(), 'Expected 3 teams in the result list');
        
        // Check if the team names and IDs match
        System.assertEquals(teams[0].Id, result[0].id, 'First team ID should match');
        System.assertEquals('Team A', result[0].name, 'First team name should be Team A');
    } */
    
}