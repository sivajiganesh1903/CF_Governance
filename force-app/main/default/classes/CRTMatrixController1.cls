public with sharing class CRTMatrixController1 {
    //wrapper class for multiple objects field values
  /*  public class CRTMatrixWrapper {
        @AuraEnabled public ID US_ID;
        @AuraEnabled public ID US_prID;
        @AuraEnabled public ID CM_ID;   
        @AuraEnabled public String US_release;
        @AuraEnabled public String US_Name;
        @AuraEnabled public String US_testLookup;
        @AuraEnabled public String US_title;
        @AuraEnabled public String US_recordType;
        @AuraEnabled public String US_critical;
        @AuraEnabled public String PR_project;
        @AuraEnabled public String test_Name;
        @AuraEnabled public String test_result;
        @AuraEnabled public string CM_Name;   
        @AuraEnabled public string US_Owner;   
        @AuraEnabled public String Rsl_testStatus;
        @AuraEnabled public String Rsl_deployment;
        @AuraEnabled public String Rsl_Environment;
        @AuraEnabled public string MD_Name;   
        
    }
    
    @AuraEnabled(cacheable = true)
    public static List<CRTMatrixWrapper> getMatrixData() {
        //query user story records which are related with Copado test and copado user story commit
        List<copado__User_Story__c> USData = [SELECT Id, copado__Release__r.Name, Name, copado__User_Story_Title__c, 
                                              RecordType.Name, Criticality__c , copado__Project__r.Name, 
                                              copado__Project__c,Owner.Name FROM copado__User_Story__c 
                                              WHERE copado__User_Story_Title__c != '' 
                                              AND Id IN (SELECT copado__User_Story__c FROM copado__Test__c) 
                                              AND Id IN (SELECT copado__User_Story__c FROM copado__User_Story_Commit__c)];
        system.debug(USData.size());
        List<CRTMatrixWrapper> MatrixDatalist = new List<CRTMatrixWrapper>();
        
        for (copado__User_Story__c us : USData) {
            CRTMatrixWrapper wrapper = new CRTMatrixWrapper();
            wrapper.US_release = us.copado__Release__r.Name;
            wrapper.US_title = us.copado__User_Story_Title__c;
            wrapper.US_recordType = us.RecordType.Name;
            wrapper.US_Name = us.Name;
            wrapper.US_Owner = us.Owner.Name;
            wrapper.US_prID = us.copado__Project__c;
            wrapper.US_ID = us.Id;
            //wrapper.US_critical = us.Criticality__c   ;
            wrapper.PR_project = us.copado__Project__r.Name;
            // List of all user story commits which are related to User story
            List<copado__User_Story_Commit__c> CMData = [SELECT Id, Name,copado__Snapshot_Commit__r.Name,
                                                         copado__Snapshot_Commit__r.ID,LastModifiedBy.Name 
                                                         FROM copado__User_Story_Commit__c 
                                                         WHERE copado__User_Story__c = :us.Id];
            wrapper.CM_ID = CMData[0].copado__Snapshot_Commit__r.ID;
            wrapper.CM_Name = CMData[0].copado__Snapshot_Commit__r.Name;
            
            //List of Selected metadata which are related to User story data
            List<copado__User_Story_Metadata__c> metaData = [SELECT Id, copado__Metadata_API_Name__c FROM 
                                                             copado__User_Story_Metadata__c 
                                                             WHERE copado__User_Story__c = :us.Id];
            if (!metaData.isEmpty()) {
                wrapper.MD_Name = metaData[0].copado__Metadata_API_Name__c;
            } else {
                wrapper.MD_Name = '--None--';
            }
            system.debug('selected Metadata'+''+metaData);
            
            //List of test data which are related to User story data
            List<copado__Test__c> testData = [SELECT Id, Name FROM copado__Test__c WHERE copado__User_Story__c = :us.Id];
            
            if (!testData.isEmpty()) {
                wrapper.test_Name = testData[0].Name;
                
                //List of Result data  which are related to Test data
                List<copado__Result__c> resultData = [SELECT Id, copado__Status__c, copado__Deployment__c, Test_Environment__c,
                                                      copado__Test__c, copado__User_Story__c FROM copado__Result__c 
                                                      WHERE (copado__Status__c ='Success' OR copado__Status__c='Failed' 
                                                             OR copado__Status__c!='') AND copado__Test__c = :testData[0].Id];
                system.debug('Result dat is'+''+resultData);
                if (!resultData.isEmpty()) {
                    wrapper.Rsl_testStatus = resultData[0].copado__Status__c;
                    wrapper.Rsl_Environment = resultData[0].Test_Environment__c;
                }
                
            }
            
            MatrixDatalist.add(wrapper);
        }
        
        System.debug(MatrixDatalist);
        return MatrixDatalist;
    } */
}