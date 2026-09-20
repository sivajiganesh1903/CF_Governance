@isTest
public class UserAccessRecordRetrieverTest {
    
    @isTest
    static void testGetUserAccessManagementRecords() {
        // Create a user reference
        User referenceUser = new User(LastName = 'ReferenceUser', Alias = 'refuser', Email = 'refusr@example.com',
                                      Username = 'refusr@example.com',
                                      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                                      LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US',
                                      TimeZoneSidKey = 'Asia/Kolkata'
                                     );
        insert referenceUser;
        
        // Create a test User_Access_Managment__c record
        User_Access_Managment__c testUserAccess = new 
            User_Access_Managment__c(Status__c = 'Requested', Product_Team__c = 'FSC', 
                                     First_Name__c = 'Test', Last_Name__c = 'User1',
                                     Environments__c = 'FSC Dev1', Federation_ID__c = 'P456721', 
                                     Email__c = 'testuser1@example.com', Access_Details__c = 'Test', 
                                     Divsion__c = 'DevOps', Access_Period_Start__c = Date.today(),
                                     Access_Period_End__c = Date.today().addDays(30), Addition_of_Permission__c = 'Permission A',
                                     Removal_of_Permissions__c = 'Permission B', End_of_Day__c = '17:00', 
                                     Start_Of_Day__c = '09:00', Persona__c = 'Branch Office Administrator (BOA)',
                                     Time_Zone__c = '(GMT-03:00) Atlantic Daylight Time (America/Halifax)',
                                     Reference_User__c = referenceUser.Id,        // Use the dynamically created user
                                     Request_Type__c = 'New User Request'
                                    );
        insert testUserAccess;
        
        // Create mock OrgWideEmailAddress
        OrgWideEmailAddress orgEmail = new OrgWideEmailAddress();
        orgEmail.Address = 'test@example.com';
        orgEmail.DisplayName = 'CF-EJ-FSCDEVOPS';
        
        // Create mock PMD_Report__mdt records
        PMD_Report__mdt mockReport = new PMD_Report__mdt();
        mockReport.Org_Address__c = orgEmail.Address; // Set the Org Address
        mockReport.Email_Address__c = 'test@example.com'; // Use the same address
        // Note: Do not insert OrgWideEmailAddress and PMD_Report__mdt in test, it should exist in org
        // Start test for getUserAccessManagementRecords
        Test.startTest();
        List<UserAccessRecordRetriever.devopsWrapper> results = UserAccessRecordRetriever.getUserAccessManagementRecords();
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals(0, results.size(), 'Expected results to be returned.');
    }
    
    @isTest
    static void testSendWeeklyUserAccessReport() {
        
        // Create mock OrgWideEmailAddress
        OrgWideEmailAddress orgEmail = new OrgWideEmailAddress();
        orgEmail.Address = 'test@example.com';
        orgEmail.DisplayName = 'CF-EJ-FSCDEVOPS';
        
        // Create mock PMD_Report__mdt records
        PMD_Report__mdt mockReport = new PMD_Report__mdt();
        mockReport.Org_Address__c = orgEmail.Address; // Set the Org Address
        mockReport.Email_Address__c = 'test@example.com'; // Use the same address
        
        // Insert User_Access_Managment__c record for testing
        User_Access_Managment__c testUserAccess = new 
            User_Access_Managment__c(Status__c = 'Requested', Product_Team__c = 'FSC', First_Name__c = 'Test', 
                                     Last_Name__c = 'User1',Environments__c = 'FSC Dev1', Federation_ID__c = 'P456721', 
                                     Email__c = 'testuser1@example.com', Access_Details__c = 'Test', Divsion__c = 'DevOps', 
                                     Access_Period_Start__c = Date.today(), Access_Period_End__c = Date.today().addDays(30));
        insert testUserAccess;
        
        // Start test for sendWeeklyUserAccessReport
        Test.startTest();
        UserAccessRecordRetriever.sendWeeklyUserAccessReport();
        Test.stopTest();
    }
}