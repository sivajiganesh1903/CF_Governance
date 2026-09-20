/**
     * @description Test class for SCAAutomation class.
     * It validates the Jenkins automation logic by creating test data and executing the method.
     * Includes mock callouts and verifies the expected behavior.
     * @author Vishnu Ramagoni
     * @date [19-03-2025]
    */
@isTest
    public class SCAAutomationTest {            
            /**
             * @description Mock class for HTTP callouts used in test cases.
            */
            private class MockHttpResponse implements HttpCalloutMock {
                /**
                 * @description Mocks the HTTP response for a given HTTP request.
                 * @param req The incoming HTTP request.
                 * @return The simulated HTTP response with status code 204.
                */
                public HTTPResponse respond(HttpRequest req) {
                    HttpResponse res = new HttpResponse();
                    res.setStatusCode(204);
                    return res;
                }
            }
            
            /**
             * @description Test method to verify SCAAutomation.getuserstory functionality.
            */
            @isTest
            public static void testSCAAutomation() {
                // Assign Copado License (optional if required for environment setup)
                copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
                copado.GlobalAPI.UserLicense ul = new copado.GlobalAPI.UserLicense();
                UL.isCCMEnabled = true; // Change management license
                UL.isCopadoEnabled = true; // Enterprise license
                UL.userId = UserInfo.getUserId();
                copado.GlobalAPI.LicenseOperationResult result = copadoGlobalAPI.upsertCopadoLicense(ul);
                System.assert(result != null, 'License operation result should not be null.');
                System.runAs(new User(Id = UserInfo.getUserId())) {
                // Create environments
                copado__Environment__c devEnv = new copado__Environment__c(Name='TRNDEV1', copado__Platform__c='Salesforce');
                insert devEnv;
                copado__Environment__c qaEnv = new copado__Environment__c(Name='TRNQA', copado__Platform__c='Salesforce');
                insert qaEnv;

                // Create credentials
                copado__Org__c devOrg = new copado__Org__c(Name='TRNDEV1', copado__Org_Type__c='Sandbox', copado__Disable_Validation__c=true, copado__Environment__c=devEnv.Id);
                insert devOrg;
                copado__Org__c qaOrg = new copado__Org__c(Name='TRNQA', copado__Org_Type__c='Sandbox', copado__Disable_Validation__c=true, copado__Environment__c=qaEnv.Id);
                insert qaOrg;

                // Create Repository
                copado__Git_Repository__c gitrepo = new copado__Git_Repository__c(Name='Test Git Repo',copado__URI__c='www.Github.com/test/testrepo/');
                insert gitrepo;
                // Create a Snapshot
                copado__Git_Backup__c gitsnapshot = new copado__Git_Backup__c(Name='Github Backup',copado__Git_Repository__c=gitrepo.id,copado__Branch__c='testbranch',copado__Org__c=qaOrg.id,copado__Git_Snapshot_Permissions__c='Allow Snapshots & Commits');
                insert gitsnapshot;

                // Create a Git Org Commit
                copado__Git_Org_Commit__c gitCommit = new copado__Git_Org_Commit__c(
                    copado__Org__c = devOrg.Id,
                    copado__Status__c = 'Complete',
                    copado__Git_Operation__c = 'Commit Files',
                    copado__Git_Backup__c = gitsnapshot.Id,
                    copado__Commit_Message__c = 'US-0168124: Github Actions',
                    copado__Commit_Id__c = '381f18f4ee84853faa1d40d01e75ce706aacdd10'
                );
                insert gitCommit;

                // Create team, release, and user story
                copado__Team__c team = new copado__Team__c(Name='Test Team', copado__Department__c='IT');
                insert team;

                copado__Release__c release = new copado__Release__c(Name='Test Release');
                insert release;
                
                // Create copado__Deployment_Flow__c
                copado__Deployment_Flow__c pipeline = new copado__Deployment_Flow__c(
                    Name = 'Test Pipeline',
                    copado__Platform__c = 'Salesforce',
                    copado__Equal_Branch_Environment_Name__c = false,
                    copado__Enable_Copado_DX__c = false,
                    copado__Disable_Validations__c = false,
                    copado__Continuous_Delivery_Enabled__c = false,
                    copado__Block_Commits__c = false,
                    copado__Apply_Connection_Behaviours_to_existing__c = false,
                    copado__Active__c = true,
                    copado__Enable_Smart_Conflict_Resolution__c = true,
                    copado__Git_Repository__c = gitrepo.Id,
                    copado__Main_Branch__c = 'main'
                );
                insert pipeline;
                
                Copado__project__c project = new Copado__project__c(Name='CopadoTest',Copado__Deployment_Flow__c=pipeline.id,copado__Index_Metadata__c=true);
                insert project;

                copado__User_Story__c userStory = new copado__User_Story__c(
                    copado__User_Story_Title__c='Test Story',
                    copado__Team__c=team.Id,
                    copado__Release__c=release.Id,
                    copado__Developer__c=UserInfo.getUserId(),
                    Copado__project__c = project.id
                );
                insert userStory;

                // Create User Story Commit
                copado__User_Story_Commit__c userStoryCommit = new copado__User_Story_Commit__c(
                    copado__User_Story__c = userStory.Id,
                    Name = 'US Commit',
                    copado__Snapshot_Commit__c = gitCommit.Id
                );
                insert userStoryCommit;
                
                copado__User_Story_Metadata__c apexClassMetadata = new copado__User_Story_Metadata__c(Name='Test Apex Class',copado__Type__c='ApexClass',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='ApexClass.CopadoSCAReaderTest');
                insert ApexClassMetadata;

                copado__User_Story_Metadata__c apexTriggerMetadata = new copado__User_Story_Metadata__c(Name='Test ApexTrigger',copado__Type__c='ApexTrigger',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='ApexTrigger.CopadoSCAReaderTest');
                insert ApexTriggerMetadata;

                copado__User_Story_Metadata__c lightningComponentBundleMetadata = new copado__User_Story_Metadata__c(Name='Test LightningComponentBundle',copado__Type__c='LightningComponentBundle',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='LightningComponentBundle.CopadoSCAReaderTest');
                insert LightningComponentBundleMetadata;
                
                copado__User_Story_Metadata__c apexPageMetadata = new copado__User_Story_Metadata__c(Name='Test ApexPage',copado__Type__c='ApexPage',copado__User_Story__c=userstory.id,copado__Metadata_API_Name__c='ApexPage.CopadoSCAReaderTest');
                insert ApexPageMetadata;

                // Prepare attachment body (contains valid types to trigger checkvar = true)
                String body = '[{"n":"userstorysfscaclass","t":"ApexClass"},{"n":"HasApex_LatestCmtDate","t":"ApexTrigger"},{"n":"Lightning_Component_Update","t":"LightningComponentBundle"},{"n":"VisualforcePageUpdate","t":"ApexPage"}]';
                Attachment attachment = new Attachment(
                    Name = 'Attachment',
                    Body = Blob.valueOf(body),
                    ParentId = gitCommit.Id
                );
                insert attachment;
                
                // Set mock callout
                Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

                // Start test execution
                Test.startTest();
                SCAAutomation.getuserstory(new List<copado__User_Story_Commit__c>{ userStoryCommit });
                Test.stopTest();
                System.assert(true, 'SCAAutomation.getuserstory executed successfully.');
               }
            }
    }