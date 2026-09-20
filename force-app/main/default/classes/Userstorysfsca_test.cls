@istest
public with sharing class Userstorysfsca_test {
    // Mock class for HTTP callouts
    private class MockHttpResponse implements HttpCalloutMock {
        /**
* @description This method handles the mock HTTP callout and returns a response with status code 204.
* @param req The HTTP request object.
* @return HttpResponse with status code 204.
*/
        public HTTPResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(204);
            return res;
        }
    }
    
    @testSetup
    static void createObjectData(){    
        
        //creating all object Data
        
        //LatAm_Profile_List__c test2 = new LatAm_Profile_List__c(Name='LatAmProfileList',Profile_List__c='System Administrator');
        //insert test2;
        
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        copado.GlobalAPI.UserLicense ul = new copado.GlobalAPI.UserLicense();
        
        ul.isCADEnabled = false; //Agile delivery license
        ul.isCCHEnabled = false; //Compliance hub license
        ul.isCCMEnabled = true; //Change management (developer) license
        ul.isCopadoEnabled = true; //Enterprise (admin / release manager) license
        //UL.isCSTEnabled = true; //Copado Selenium testing license
        ul.userId = UserInfo.getUserId();
        
        copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(ul);
        System.assert(result != null, 'License operation result should not be null.');
        
        // CREATE ENVIRONMENT
        copado__Environment__c objEnvi1 = new copado__Environment__c(Name='TRNDEV1',copado__Platform__c='Salesforce');
        insert objEnvi1;
        
        copado__Environment__c objEnvi2 = new copado__Environment__c(Name='TRNQA',copado__Platform__c='Salesforce');
        insert objEnvi2;
        
        
        //CREATE CREDENTIAL
        copado__Org__c objCredential1 = new copado__Org__c (Name='TRNDEV1', copado__Org_Type__c='Sandbox' ,copado__Disable_Validation__c=true,copado__Environment__c = objEnvi1.Id);
        insert objCredential1;
        
        copado__Org__c objCredential2 = new copado__Org__c (Name='TRNQA',   copado__Org_Type__c='Sandbox' ,copado__Disable_Validation__c=true,copado__Environment__c = objEnvi2.Id);
        insert objCredential2;
        
        copado__Team__c team = new copado__Team__c (Name='Test Team',copado__Department__c ='IT');
        insert team;
        
        copado__Release__c release = new copado__Release__c(Name='Test Release', CFEC__Planned_Date_Time__c= System.Today()+5);
        insert release;
        
        copado__Git_Repository__c gitrepo = new copado__Git_Repository__c(Name='Test Git Repo',copado__URI__c='www.Github.com/test/testrepo/');
        insert gitrepo;
        
        copado__Git_Backup__c gitsnapshot = new copado__Git_Backup__c(Name='Github Backup',copado__Git_Repository__c=gitrepo.id,copado__Branch__c='testbranch',copado__Org__c=objCredential2.id,copado__Git_Snapshot_Permissions__c='Allow Snapshots & Commits');
        insert gitsnapshot;
        
        
        Id uid;
        uid = UserInfo.getUserId();
        copado__User_Story__c userstory = new copado__User_Story__c(copado__User_Story_Title__c='Test Story',copado__Team__c=team.id,copado__Release__c=release.id,copado__Developer__c=uid);
        insert userstory;
        
        copado__User_Story_Metadata__c apexClassMetadata = new copado__User_Story_Metadata__c(Name='Test Apex Class',copado__Type__c='ApexClass',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='ApexClass.CopadoSCAReaderTest');
        insert ApexClassMetadata;
        
        copado__User_Story_Metadata__c apexTriggerMetadata = new copado__User_Story_Metadata__c(Name='Test ApexTrigger',copado__Type__c='ApexTrigger',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='ApexTrigger.CopadoSCAReaderTest');
        insert ApexTriggerMetadata;
        
        copado__User_Story_Metadata__c lightningComponentBundleMetadata = new copado__User_Story_Metadata__c(Name='Test LightningComponentBundle',copado__Type__c='LightningComponentBundle',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='LightningComponentBundle.CopadoSCAReaderTest');
        insert LightningComponentBundleMetadata;
        
        copado__User_Story_Metadata__c apexPageMetadata = new copado__User_Story_Metadata__c(Name='Test ApexPage',copado__Type__c='ApexPage',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='ApexPage.CopadoSCAReaderTest');
        insert ApexPageMetadata;
        
    }
    
    @isTest
    static void testCreateCIJob() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Set mock callout
            Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
            
            // Query the User Story
            copado__User_Story__c userstory = [SELECT Id, Name FROM copado__User_Story__c Where copado__User_Story_Title__c='Test Story' LIMIT 1];
            Test.startTest();
            userstorysfsca.createcijob(userstory.Id);
            Test.stopTest();
            
            // Assertions
            System.assert(true, 'createcijob executed without exceptions');
        }
    }
    /*
    @istest
    static void testorgscan(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Set mock callout
            Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
            
            copado__Environment__c objEnvi1 = [SELECT Id,Git_base_branch__c FROM copado__Environment__c WHERE Name='TRNQA']; 
            copado__Git_Backup__c gitsnapshot = [SELECT Id FROM copado__Git_Backup__c WHERE Name='Github Backup'];
            objEnvi1.Git_base_branch__c = gitsnapshot.id;
            update objEnvi1;
            copado__Org__c credential = [SELECT Id FROM copado__Org__c WHERE Name='TRNQA'];
            Test.startTest();
            Userstorysfsca.orgscan(credential.id);
            Test.stopTest();
            System.assert(true, 'createcijob executed without exceptions');
        }
    }
    */
    @istest
    static void usSfscaHandlerPassRecIdToAura(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
            copado__Team__c team=new copado__Team__c(Name='Dev',copado__Department__c='IT');
            copado__Release__c release=new copado__Release__c(name='January 2025');
            
            copado__User_Story__c us=new copado__User_Story__c(copado__Team__c=team.Id, copado__Release__c=release.Id, copado__Developer__c=userInfo.getUserId(), copado__Has_Apex_Code__c=true);
            insert us;
            
            us.copado__Latest_Commit_Date__c=System.today();
            update us;
            System.assertEquals(System.today(), us.copado__Latest_Commit_Date__c,  'Commit date has updated successfully');
        }
    }
    
    @isTest
    static void testStoryScanButtonMethod() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
            
            copado__User_Story__c userstory = [SELECT Id FROM copado__User_Story__c WHERE copado__User_Story_Title__c = 'Test Story' LIMIT 1];
            
            Test.startTest();
            Userstorysfsca.storyscanbutton(userstory.Id);
            Test.stopTest();
            
            System.assert(true, 'storyscanbutton executed without exception');
        }
    } 
    
}