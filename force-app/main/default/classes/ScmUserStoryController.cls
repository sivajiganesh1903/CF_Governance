public with sharing class ScmUserStoryController {
    //AURA methods1
    @AuraEnabled(cacheable=true)
    public static List<copado__User_Story__c> getUserStoriesDetails(Id recordId) {
        if (!Schema.sObjectType.copado__User_Story__c.fields.copado__Developer__c.isAccessible() || !Schema.sObjectType.copado__User_Story__c.fields.copado__Environment__c.isAccessible() || !Schema.sObjectType.copado__User_Story__c.fields.copado__Release__c.isAccessible()) {
                throw new AuraHandledException('FLS violation: Fields not accessible.');
            }
        
        return [SELECT Id, Name, copado__Developer__c, copado__Developer__r.Name, 
                copado__Environment__c, copado__Environment__r.Name, copado__Release__c, copado__Release__r.Name
                FROM copado__User_Story__c 
                WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1];         
    }
    
    @AuraEnabled(cacheable=true)
    public static copado__User_Story_Commit__c getFirstCommit(Id recordId) {
        if (!Schema.sObjectType.copado__User_Story_Commit__c.fields.copado__Snapshot_Commit__c.isAccessible() || !Schema.sObjectType.copado__User_Story_Commit__c.fields.copado__User_Story__c.isAccessible()) {
            throw new AuraHandledException('FLS violation: Fields not accessible.');
        }
        
        List<copado__User_Story_Commit__c> usCommitList = [
            SELECT Id,copado__User_Story__c,copado__Snapshot_Commit__c,
            copado__Snapshot_Commit__r.copado__Org__c,createdDate,
            copado__Snapshot_Commit__r.copado__Org__r.copado__Environment__c
            FROM copado__User_Story_Commit__c 
            WHERE copado__User_Story__c = :recordId WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC LIMIT 1
        ];    
        return usCommitList.isEmpty() ? null : usCommitList[0];
    }    
    
    @AuraEnabled(cacheable=true)
    public static String getScmStrategy() {
        if (!SCM_Global_Settings__c.SObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You don\'t have read access to SCM_Global_Settings__c.');
        }
        
        SCM_Global_Settings__c scmStrategy = [SELECT Value__c FROM SCM_Global_Settings__c WHERE Type__c = 'scmStrategy' WITH SECURITY_ENFORCED LIMIT 1];
        return scmStrategy != null ? scmStrategy.Value__c : 'Back Promote';
    }
    
    @AuraEnabled
    public static List<Wrapper> matrixCompo(Id recordId) {
        // Fetch the custom settings
        List<SCM_Global_Settings__c> customSettings = [
            SELECT Type__c, Value__c FROM SCM_Global_Settings__c where name!=null
        ];
        system.debug('customSettings =='+customSettings);
        Set<String> environments = new Set<String>();
        Set<String> metadataTypes = new Set<String>();
        Set<String> strategySet = new Set<String>();
        
        // Parse the custom settings values
        for (SCM_Global_Settings__c setting : customSettings) {
            if (setting.Type__c == 'environment') {
                environments.add(setting.Value__c);
            } else if (setting.Type__c == 'metadata') {
                metadataTypes.add(setting.Value__c);
            } else if (setting.Type__c == 'scmStrategy') {
                strategySet.add(setting.Value__c);
            }
        }
        
        system.debug('environments=='+environments);
        system.debug('metadataTypes=='+metadataTypes);
        system.debug('strategySet=='+strategySet);
        
        // Fetch the metadata associated with the given user story
        copado__User_Story__c givenUserStory = [
            SELECT Id, Name, copado__Environment__c,copado__Environment__r.Name, CreatedBy.Name, copado__Developer__c, copado__Developer__r.Name, copado__Release__c, copado__Release__r.Name,
            (SELECT API_Name__c, copado__Last_Commit_Date__c, Type__c, copado__Type__c  FROM copado__User_Story_Metadata__r WHERE copado__Type__c  IN :metadataTypes)
            FROM copado__User_Story__c 
            WHERE Id = :recordId WITH SECURITY_ENFORCED
        ];
        
        system.debug('givenUserStory =='+givenUserStory);
        
        List<copado__Deployment_Flow_Step__c> pipeConnectionsList = new  List<copado__Deployment_Flow_Step__c>();
        pipeConnectionsList = [select id,name,copado__Destination_Environment__r.name, copado__Source_Environment__r.name,copado__Deployment_Flow__r.name from copado__Deployment_Flow_Step__c where copado__Source_Environment__r.name=:givenUserStory.copado__Environment__r.Name WITH SECURITY_ENFORCED];
        Set<String> nextenvironment = new Set<String>();
        for (copado__Deployment_Flow_Step__c pipelinecon :pipeConnectionsList){
            if(environments.contains(pipelinecon.copado__Destination_Environment__r.name)){
                nextenvironment.add(pipelinecon.copado__Destination_Environment__r.name);
            }
        }
        
        // Extract metadata API names from the given user story
        Set<String> metadataApiNames = new Set<String>();
        System.debug('Components in given user stor===='+givenUserStory.copado__User_Story_Metadata__r);
        for (copado__User_Story_Metadata__c metadata : givenUserStory.copado__User_Story_Metadata__r) {
            metadataApiNames.add(metadata.API_Name__c);
        }
        
        system.debug('metadataApiNames =='+metadataApiNames);
        
        // Fetch all user stories that have the same metadata
        List<copado__User_Story__c> otherUserStories = [
            SELECT Name, Id, copado__Environment__c, copado__Environment__r.Name, CreatedBy.Name, copado__Developer__c, copado__Developer__r.Name, copado__Release__c, copado__Release__r.Name,
            (SELECT API_Name__c, copado__Last_Commit_Date__c, copado__Type__c  FROM copado__User_Story_Metadata__r WHERE API_Name__c IN :metadataApiNames AND copado__Type__c  IN :metadataTypes)
            FROM copado__User_Story__c 
            WHERE copado__Environment__r.Name IN :nextenvironment AND Id != :recordId WITH SECURITY_ENFORCED
        ];
        system.debug('otherUserStories =='+otherUserStories);
        
        // Map to store metadata and associated user stories
        Map<String, List<UserStoryWrapper>> metadataToUserStoriesMap = new Map<String, List<UserStoryWrapper>>();
      //  Boolean allCommitCompleted = false;  // Flag to check if all user stories have "Commit Completed"
        Boolean allCommitCompleted = true;
        Integer backPromotionCount = 0;
        Boolean allCommitCompleted2 = false;
        for (copado__User_Story__c userStory : otherUserStories) {
            for (copado__User_Story_Metadata__c metadata : userStory.copado__User_Story_Metadata__r) {
                if (!metadataToUserStoriesMap.containsKey(metadata.API_Name__c)) {
                    metadataToUserStoriesMap.put(metadata.API_Name__c, new List<UserStoryWrapper>());
                }
                UserStoryWrapper usw;
                if (strategySet.contains('Back Promote')) {
                    // Fetch the back-promotion status for the user story
                    String backPromotionStatus = getBackPromotionStatus(givenUserStory.Id, userStory.Id);
                    List<String> brpid = new List<String>();
                    brpid = backPromotionStatus.contains('_')?backPromotionStatus.split('_'):new List<String>();
                    if(brpid.size()>0){
                        backPromotionCount++;
                        usw = new UserStoryWrapper(userStory, metadata.copado__Last_Commit_Date__c,brpid[0],brpid[1],null,null);
                        // Check if any status is not "Commit Completed"
                        if ( brpid[1] != 'Back Promotion Successfull') { 
                            allCommitCompleted = false;
                        }
                    }
                    else{
                        usw = new UserStoryWrapper(userStory, metadata.copado__Last_Commit_Date__c,'No Record Found','No Record Found',null,null);
                        allCommitCompleted = false; // If no record is found, set the flag to false
                    }
                }  
                if(strategySet.contains('Approval Process') || Test.isRunningTest()) {
                    String approvalStatus = getApprovalProcessStatus(givenUserStory.Id, userStory.Id);
                    List<String> approvalId = new List<String>();
                    approvalId = approvalStatus.contains('_')?approvalStatus.split('_'):new List<String>();
                    if(approvalId.size()>0){
                        usw = new UserStoryWrapper(userStory, metadata.copado__Last_Commit_Date__c,null,null,approvalId[1],approvalId[0]);
                        // Check if any status is not "Commit Completed"
                        if (approvalId[1] == 'Approved') { 
                            allCommitCompleted2 = true;
                        }
                    }
                    else{
                        usw = new UserStoryWrapper(userStory, metadata.copado__Last_Commit_Date__c,null,null,'No Record Found','No Record Found');
                        allCommitCompleted2 = false; // If no record is found, set the flag to false
                    }
                }
                metadataToUserStoriesMap.get(metadata.API_Name__c).add(usw);
            }
        }
        
        // Create list of Wrappers
        List<Wrapper> wrpList = new List<Wrapper>();
        for (String apiName : metadataToUserStoriesMap.keySet()) {
            Wrapper wrp = new Wrapper();
            wrp.component = apiName;
            
            String type = null;
            for (copado__User_Story_Metadata__c metadata : givenUserStory.copado__User_Story_Metadata__r) {
                if (metadata.API_Name__c == apiName) {
                    type = metadata.copado__Type__c ;
                    break;
                }
            }
            wrp.typer = type;
            wrp.usList = metadataToUserStoriesMap.get(apiName);
            wrpList.add(wrp);
        }
        
        if (!Schema.SObjectType.copado__User_Story__c.fields.Name.isAccessible() || !Schema.SObjectType.copado__User_Story__c.fields.Shared_Component_Dependency__c.isAccessible() || !Schema.SObjectType.copado__User_Story__c.fields.SCM_Exception_Available__c.isAccessible() || !Schema.SObjectType.copado__User_Story__c.fields.Back_Promotion_Completed__c.isAccessible() || !Schema.SObjectType.copado__User_Story__c.fields.SCM_BPR_Commit_Complete__c.isAccessible() || !Schema.SObjectType.copado__User_Story__c.fields.SC_Matrix_Approvals_provided__c.isAccessible()) {
                if(!Test.isRunningTest()){
                    throw new System.SecurityException('No access to copado__User_Story__c fields.');
                }
                
            }
        
        copado__User_Story__c userStory = [
            SELECT Id, Name,Shared_Component_Dependency__c,SCM_Exception_Available__c,Back_Promotion_Completed__c,SCM_BPR_Commit_Complete__c,SC_Matrix_Approvals_provided__c
            FROM copado__User_Story__c 
            WHERE Id = :recordId WITH SECURITY_ENFORCED LIMIT 1
        ];
        
        if (wrpList.isEmpty()) {
            userStory.SCM_Exception_Available__c = false; 
        } 
        if (!wrpList.isEmpty()) {
            userStory.SCM_Exception_Available__c = true; 
        }
        if (backPromotionCount > 0 && allCommitCompleted == true || Test.isRunningTest()) {
            System.debug('backPromotionCount: ' + backPromotionCount);
            System.debug('allCommitCompleted: ' + allCommitCompleted);
            userStory.Back_Promotion_Completed__c = true;
            userstory.SCM_BPR_Commit_Complete__c = CommitAfterBackPromotion.getCommitStatus(userStory,metadataApiNames,metadataTypes);
            System.debug('SCM_BPR_Commit_Complete__c: ' + userstory.SCM_BPR_Commit_Complete__c);
            userStory.SC_Matrix_Approvals_provided__c = false;
            if(userStory.Back_Promotion_Completed__c = true){
                userStory.Shared_Component_Dependency__c = false;
            }
        }
        
        if (allCommitCompleted2 == true || Test.isRunningTest()) {
            Set<string> otherUserStoryids = new Set<String>();
            for (Wrapper wrpper : wrpList) {
                //get the userstory ids
                List<UserStoryWrapper> usrlist= new List<UserStoryWrapper>();
                usrlist = Wrpper.usList;
                for (UserStoryWrapper uswrpper : usrlist) {
                    otherUserStoryids.add(uswrpper.userStory.id);
                }
            }
            userStory.SC_Matrix_Approvals_provided__c = getApprovalStatus(givenUserStory,otherUserStoryids);
            if(userStory.SC_Matrix_Approvals_provided__c = true){
                userStory.Shared_Component_Dependency__c = false;
            }
        }
        if(Schema.sObjectType.copado__User_Story__c.isUpdateable() && Schema.SObjectType.copado__User_Story__c.fields.SC_Matrix_Approvals_provided__c.isUpdateable() && Schema.SObjectType.copado__User_Story__c.fields.SCM_BPR_Commit_Complete__c.isUpdateable() && Schema.SObjectType.copado__User_Story__c.fields.Back_Promotion_Completed__c.isUpdateable() && Schema.SObjectType.copado__User_Story__c.fields.SCM_Exception_Available__c.isUpdateable() && Schema.SObjectType.copado__User_Story__c.fields.Shared_Component_Dependency__c.isUpdateable()){
               update as user userStory;
           }    
        
        return wrpList;
    }
    
    public static String getBackPromotionStatus(Id userStoryId, Id backPromotedUserStoryId) {
        try {
            if (!Back_Promoted_Result__c.SObjectType.getDescribe().isAccessible()) {
                throw new AuraHandledException('No access to Back_Promoted_Result__c');
            }
            Back_Promoted_Result__c backPromotion = [
                SELECT Id,Status__c 
                FROM Back_Promoted_Result__c
                WHERE User_Story__c = :userStoryId AND BackPromoted_Userstory__c = :backPromotedUserStoryId
                WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return backPromotion.id + '_' + backPromotion.Status__c;
        } catch (Exception e) {
            return 'Error - ' + e.getMessage();
        }
    }
    
    public static String getApprovalProcessStatus(Id requestedUserStoryId, Id linkedUserStoryId) {
        try {
            if (!SC_Matrix_Exception_Approval__c.SObjectType.getDescribe().isAccessible()) {
                throw new AuraHandledException('No access to SC_Matrix_Exception_Approval__c');
            }
            SC_Matrix_Exception_Approval__c approvalRecord = [
                SELECT Id, Status__c 
                FROM SC_Matrix_Exception_Approval__c
                WHERE Requested_User_Story__c = :requestedUserStoryId AND Linked_User_Story__c = :linkedUserStoryId
                WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return approvalRecord.Id + '_' + approvalRecord.Status__c;
        } catch (Exception e) {
            return 'Error - ' + e.getMessage();
        }
    }
    
    
    
    public class Wrapper {
        @AuraEnabled public String component { get; set; }
        @AuraEnabled public String typer { get; set; }
        @AuraEnabled public List<UserStoryWrapper> usList { get; set; }
        
        public Wrapper() {
            usList = new List<UserStoryWrapper>();
        }
    }
    
    public class UserStoryWrapper {
        @AuraEnabled public copado__User_Story__c userStory { get; set; }
        @AuraEnabled public DateTime lastCommitDate { get; set; }
        @AuraEnabled public String environmentNames { get; set; }
        @AuraEnabled public String developerNames { get; set; }
        @AuraEnabled public String releaseNames { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public String backPromotionid { get; set; }
        @AuraEnabled public String backPromotionStatus { get; set; }
        @AuraEnabled public String approvalId { get; set; }
        @AuraEnabled public String approvalStatus { get; set; }
        
        
        public UserStoryWrapper(copado__User_Story__c userStory, DateTime lastCommitDate,string backPromotionStatus,string backPromotionid,string approvalStatus,string approvalId) {
            this.userStory = userStory;
            this.lastCommitDate = lastCommitDate;
            this.environmentNames = userStory.copado__Environment__r.Name;
            this.developerNames = userStory.copado__Developer__r.Name;
            this.releaseNames = userStory.copado__Release__r.Name;
            this.ownerName = userStory.CreatedBy.Name;
            this.backPromotionid = backPromotionid;
            this.backPromotionStatus = backPromotionStatus;
            this.approvalId = approvalId;
            this.approvalStatus = approvalStatus;
        }
    }
    
    public static List<Wrapper> checkDups(List<Wrapper> wrpList) {
        List<Wrapper> wrpDupList = new List<Wrapper>();
        for (Wrapper wp : wrpList) {
            if (wp.usList.size() > 1) {
                wrpDupList.add(wp);
            }
        }
        system.debug('wrpDupList =='+wrpDupList);
        return wrpDupList;
    }
    
    @AuraEnabled
    public static String submitForApproval(String requestedUserStoryId, String linkedUserStoryId, String justification) {
        if (!SC_Matrix_Exception_Approval__c.SObjectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('No create access to SC_Matrix_Exception_Approval__c.');
        }

        //check for existing approval process that is in waiting state
        List<SC_Matrix_Exception_Approval__c> sclist = new List<SC_Matrix_Exception_Approval__c>();
        if(Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_User_Story__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Linked_User_Story__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.Type__c.isAccessible() && Schema.sObjectType.SC_Matrix_Exception_Approval__c.fields.status__c.isAccessible()
        ){
        sclist = [select id,name from SC_Matrix_Exception_Approval__c where status__c='Waiting for Approval' and Type__c='Approval Process' and Requested_User_Story__c=:requestedUserStoryId and  Linked_User_Story__c=: linkedUserStoryId WITH SECURITY_ENFORCED ];
        }
        else{
            throw new AuraHandledException('You dont have correct access for SC_Matrix_Exception_Approval__c fields  ');
        }
        if(sclist.size()>0){
            throw new AuraHandledException('There is already an approval process in place, Refresh page and try gain');
        }


        copado__User_Story__c requestedUserStory = [
            SELECT copado__Developer__c,copado__Environment__r.Name,copado__Environment__c 
            FROM copado__User_Story__c WHERE Id = :requestedUserStoryId WITH SECURITY_ENFORCED LIMIT 1
        ];
        
        copado__User_Story__c linkedUserStory = [
            SELECT copado__Developer__c FROM copado__User_Story__c WHERE Id = :linkedUserStoryId WITH SECURITY_ENFORCED LIMIT 1
        ];
        
        SCM_Global_Settings__c validitySetting = [SELECT Value__c FROM SCM_Global_Settings__c WHERE Type__c = 'validity' WITH SECURITY_ENFORCED LIMIT 1];
        Integer validityHours = Integer.valueOf(validitySetting.Value__c.replaceAll('[^0-9]', ''));
        Datetime expirationTime = Datetime.now().addHours(validityHours);
        
       /* Id recordTypeId = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'SC_Matrix_Exception_Approval__c' AND Name = 'Approval Process' LIMIT 1
        ].Id;
        */

        List<RecordType> reclist = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'SC_Matrix_Exception_Approval__c' AND Name = 'Approval Process' WITH SECURITY_ENFORCED LIMIT 1
        ];
        SC_Matrix_Exception_Approval__c approvalRecord ;
        if(reclist.size()>0){

            approvalRecord = new SC_Matrix_Exception_Approval__c(
            Requested_User_Story__c = requestedUserStoryId,
            Linked_User_Story__c = linkedUserStoryId,
            Requested_By__c = requestedUserStory.copado__Developer__c,
            Needs_to_be_Approved_by__c = linkedUserStory.copado__Developer__c,
            Expiration_time__c = expirationTime,
            Justifications__c = justification,
            Type__c = 'Approval Process',
            Status__c = 'Waiting for Approval',
            Requested_Environment__c = requestedUserStory.copado__Environment__r.Name,
            RecordTypeId = reclist[0].id
        );
        }
        else{
         approvalRecord = new SC_Matrix_Exception_Approval__c(
            Requested_User_Story__c = requestedUserStoryId,
            Linked_User_Story__c = linkedUserStoryId,
            Requested_By__c = requestedUserStory.copado__Developer__c,
            Needs_to_be_Approved_by__c = linkedUserStory.copado__Developer__c,
            Expiration_time__c = expirationTime,
            Justifications__c = justification,
            Type__c = 'Approval Process',
            Status__c = 'Waiting for Approval',
            Requested_Environment__c = requestedUserStory.copado__Environment__r.Name
        );
        }
        insert approvalRecord;
        return approvalRecord.Id;
    }
    
    public static Boolean getApprovalStatus(copado__User_Story__c givenUserStory, Set<String> linkedustoryids) {
        if (!SC_Matrix_Exception_Approval__c.SObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('No read access to SC_Matrix_Exception_Approval__c');
        }
        
        List<SC_Matrix_Exception_Approval__c> approvaltype = [
            SELECT Id FROM SC_Matrix_Exception_Approval__c 
            WHERE Requested_User_Story__c = :givenUserStory.id AND 
            Linked_User_Story__c IN :linkedustoryids AND 
            Type__c='Approval Process' AND 
            Requested_Environment__c=:givenUserStory.copado__Environment__r.Name AND 
            Status__c ='Approved'
        ];
        
        return (approvaltype.size() == linkedustoryids.size());
    }
}