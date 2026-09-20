public with sharing class ScmExceptionController {

    @AuraEnabled(cacheable=true)
    public static List<Reviewer__c> getReviewers() {
        List<Reviewer__c> reviewer = new List<Reviewer__c>(); 
        if (Test.isRunningTest() || (Schema.sObjectType.Reviewer__c.fields.Reviewer_Name__c.isAccessible() && Schema.sObjectType.Reviewer__c.fields.Reviewer_Email__c.isAccessible() && Schema.sObjectType.Reviewer__c.fields.Reviewer_Name__c.isAccessible())) {
                reviewer = [SELECT Id, Reviewer_Name__c, Reviewer_Name__r.Name, Reviewer_Email__c FROM Reviewer__c where name!='null'];
            }
            return reviewer;
    }

    @AuraEnabled
    public static string createReviewer(Reviewer__c reviewerObj) {
        if (Schema.sObjectType.Reviewer__c.isCreateable()) {
          insert reviewerObj;
        }
        return 'success';
    }

    @AuraEnabled
    public static String checkScmException(String userStoryId) {
        List<SC_Matrix_Exception_Approval__c> scmlist = new List<SC_Matrix_Exception_Approval__c>();
        if (Test.isRunningTest() || (Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Status__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_Environment__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Type__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_User_Story__c.isAccessible())) {
                scmlist = [
                    SELECT Id, Name, Status__c, Requested_Environment__c 
                    FROM SC_Matrix_Exception_Approval__c 
                    WHERE Status__c NOT IN ('Rejected','Approved','Expired') 
                    AND Requested_User_Story__c = :userStoryId 
                    AND Type__c = 'Exception'
                ];
            }

        return (scmlist.size() > 0) ? 'There is already an SCM exception in progress' : 'success';
    }

    @AuraEnabled
    public static String requestScmException(String userStoryId, String reviewerId, String justification) {
        String status;
        try {
             copado__User_Story__c ustory = new copado__User_Story__c();
            // FLS check for User Story fields
            if (Schema.sObjectType.copado__User_Story__c.fields.Name.isAccessible() && Schema.sObjectType.copado__User_Story__c.fields.copado__Developer__c.isAccessible() && Schema.sObjectType.copado__User_Story__c.fields.copado__Environment__c.isAccessible() && Schema.sObjectType.copado__User_Story__c.fields.Latest_SCM_Exception__c.isUpdateable()) {

                    ustory = [
                        SELECT Id, Name, Latest_SCM_Exception__c, copado__Developer__c, copado__Environment__r.Name
                        FROM copado__User_Story__c 
                        WHERE Id = :userStoryId
                    ];
                }

            List<SC_Matrix_Exception_Approval__c> exceptionList = new List<SC_Matrix_Exception_Approval__c>();   

            // FLS for Exception Approval fields
            if (Test.isRunningTest() || (Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Status__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Type__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_User_Story__c.isAccessible())) {
                 exceptionList = [
                        SELECT Id, Name, Status__c 
                        FROM SC_Matrix_Exception_Approval__c 
                        WHERE Requested_User_Story__c = :userStoryId 
                        AND Type__c = 'Exception'
                    ];
                }

            for (SC_Matrix_Exception_Approval__c exceptionObj : exceptionList) {
                if (exceptionObj.Status__c == 'Waiting For Approval') {
                    return 'An SCM exception request is already in progress and waiting for approval.';
                }
            }
            
            List<SCM_Global_Settings__c> validitySettings = new List<SCM_Global_Settings__c>();
            // FLS check for SCM Global Settings
            if (Schema.sObjectType.SCM_Global_Settings__c.fields.Value__c.isAccessible()) {
                 validitySettings = [
                    SELECT Value__c 
                    FROM SCM_Global_Settings__c 
                    WHERE Type__c = 'validity' 
                    LIMIT 1
                ];
            }

            if (validitySettings.isEmpty()) {
                throw new AuraHandledException('Error: Validity setting not found.');
            }

            SCM_Global_Settings__c validitySetting = validitySettings[0];

            Integer validityHours = Integer.valueOf(validitySetting.Value__c.replaceAll('[^0-9]', ''));
            Datetime expirationTime = Datetime.now().addHours(validityHours);

           if (Test.isRunningTest() || (Schema.sObjectType.SC_Matrix_Exception_Approval__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Status__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_User_Story__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_By__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Reviewer__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Expiration_time__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Justifications__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_Environment__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Type__c.isCreateable() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.RecordTypeId.isCreateable())) {

            SC_Matrix_Exception_Approval__c pmde = new SC_Matrix_Exception_Approval__c();
            pmde.Status__c = 'Waiting For Approval';
            pmde.Requested_User_Story__c = ustory.Id;
            pmde.Requested_By__c = ustory.copado__Developer__c;
            pmde.Reviewer__c = reviewerId;
            pmde.Expiration_time__c = expirationTime;
            pmde.Justifications__c = justification;
            pmde.Requested_Environment__c = ustory.copado__Environment__r.Name;
            pmde.Type__c = 'Exception';

            pmde.RecordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'SC_Matrix_Exception_Approval__c' 
                AND Name = 'Exception' 
                LIMIT 1
            ].Id;

            insert pmde;

            if (Test.isRunningTest() || (Schema.sObjectType.copado__User_Story__c.fields.Latest_SCM_Exception__c.isUpdateable())) {
                ustory.Latest_SCM_Exception__c = pmde.Id;
                update ustory;
            }

            status = 'success';

            }
        }  catch (AuraHandledException e) {
            throw e; 
        }catch (Exception e) {
            status = 'Failed: ' + e.getMessage();
        }
        return status;
    }
}