public with sharing class ScmGlobalSettingPageController {
    @AuraEnabled(cacheable=true)
    public static List<copado__Environment__c> getEnvironments() {
        List<copado__Environment__c> copEnv = new List<copado__Environment__c>();
        if (Schema.SObjectType.copado__Environment__c.fields.copado__Type__c.isAccessible()) {
            copEnv = [SELECT Id, Name, copado__Type__c FROM copado__Environment__c WHERE copado__Type__c != 'Production/Developer' WITH SECURITY_ENFORCED];
        }
        return copEnv;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SCM_Global_Settings__c> getSettings() {
        List<SCM_Global_Settings__c> settings = new List<SCM_Global_Settings__c>();
        if (Schema.SObjectType.SCM_Global_Settings__c.fields.Type__c.isAccessible() && Schema.SObjectType.SCM_Global_Settings__c.fields.Value__c.isAccessible()) {
                try {
                    settings = [SELECT Type__c, Value__c FROM SCM_Global_Settings__c WHERE Name LIKE 'SCM_%' WITH SECURITY_ENFORCED];
                } catch (Exception e) {
                    // silently return empty
                }
            }
        return settings;
    }
    
    @AuraEnabled
    public static String saveSettings(List<String> selectedEnvironments, List<String> selectedMetadataTypes, String selectedScmStrategy, String selectedValidity) {

        Profile p = [
            SELECT Name
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        if (!p.Name.equalsIgnoreCase('System Administrator')) {
            return 'Error: You do not have permission to update global SCM settings.';
        }
      
      if (selectedScmStrategy == 'Back Promote') {
            Integer approvalCount = [SELECT COUNT() FROM SC_Matrix_Exception_Approval__c 
                                     WHERE Status__c = 'Waiting for Approval' AND Type__c = 'Approval Process' WITH SECURITY_ENFORCED];
            if (approvalCount > 0) {
                return 'Error: There is already an Approval Process in progress. You cannot change the strategy to Back Promote.';
            }
        }
        
       
        if (selectedScmStrategy == 'Approval Process') {
            Integer backPromoteCount = [SELECT COUNT() FROM Back_Promoted_Result__c 
                                        WHERE Status__c IN ('Back Promotion in Progress', 'Commit in Progress') WITH SECURITY_ENFORCED];
            if (backPromoteCount > 0) {
                return 'Error: There is already a Back Promotion in progress. You cannot change the strategy to Approval Process.';
            }
        }
       
        List<SCM_Global_Settings__c> existingSettings = [SELECT Id, Name, Type__c, Value__c FROM SCM_Global_Settings__c WITH SECURITY_ENFORCED];
        
        Set<String> existingEnvironments = new Set<String>();
        Set<String> existingMetadataTypes = new Set<String>();
        Map<String, SCM_Global_Settings__c> envMap = new Map<String, SCM_Global_Settings__c>();
        Map<String, SCM_Global_Settings__c> metaMap = new Map<String, SCM_Global_Settings__c>();
        List<SCM_Global_Settings__c> toInsert = new List<SCM_Global_Settings__c>();
        List<SCM_Global_Settings__c> toDelete = new List<SCM_Global_Settings__c>();
        
        for (SCM_Global_Settings__c setting : existingSettings) {
            if (setting.Type__c == 'environment') {
                existingEnvironments.add(setting.Value__c);
                envMap.put(setting.Value__c, setting);
            } else if (setting.Type__c == 'metadata') {
                existingMetadataTypes.add(setting.Value__c);
                metaMap.put(setting.Value__c, setting);
            } else if ((setting.Type__c == 'scmStrategy' || setting.Type__c == 'validity')) {
                if (Schema.SObjectType.SCM_Global_Settings__c.isDeletable()) {
                    try {
                        delete as user setting; 
                    } catch (DmlException ex) {
                        System.debug('Skip deleting already deleted record: ' + setting.Id);
                    }
                }
            }
        }
        
        
        for (String env : selectedEnvironments) {
            if (!existingEnvironments.contains(env)) {
                if (Schema.SObjectType.SCM_Global_Settings__c.fields.Name.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Type__c.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Value__c.isCreateable()) {
                        toInsert.add(new SCM_Global_Settings__c(
                            Name = 'SCM_env_' + env,
                            Type__c = 'environment',
                            Value__c = env
                        ));
                    }
            }
        }
        
        for (String env : existingEnvironments) {
            if (!selectedEnvironments.contains(env)) {
                toDelete.add(envMap.get(env));
            }
        }
        
        for (String meta : selectedMetadataTypes) {
            if (!existingMetadataTypes.contains(meta)) {
                if (Schema.SObjectType.SCM_Global_Settings__c.fields.Name.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Type__c.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Value__c.isCreateable()) {
                        toInsert.add(new SCM_Global_Settings__c(
                            Name = 'SCM_meta_' + meta,
                            Type__c = 'metadata',
                            Value__c = meta
                        ));
                    }
            }
        }
        
        for (String meta : existingMetadataTypes) {
            if (!selectedMetadataTypes.contains(meta)) {
                toDelete.add(metaMap.get(meta));
            }
        }
        
        if (String.isNotBlank(selectedScmStrategy)) {
            if (Schema.SObjectType.SCM_Global_Settings__c.fields.Name.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Type__c.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Value__c.isCreateable()) {
                    toInsert.add(new SCM_Global_Settings__c(
                        Name = 'SCM_strategy_' + selectedScmStrategy,
                        Type__c = 'scmStrategy',
                        Value__c = selectedScmStrategy
                    ));
                }
        }
        
        if (String.isNotBlank(selectedValidity)) {
            if (Schema.SObjectType.SCM_Global_Settings__c.fields.Name.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Type__c.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Value__c.isCreateable()) {
                    toInsert.add(new SCM_Global_Settings__c(
                        Name = 'SCM_validity_' + selectedValidity,
                        Type__c = 'validity',
                        Value__c = selectedValidity
                    ));
                }
        }
        
        
        if (!toInsert.isEmpty() && Schema.SObjectType.SCM_Global_Settings__c.fields.Name.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Type__c.isCreateable() && Schema.SObjectType.SCM_Global_Settings__c.fields.Value__c.isCreateable()) {
            insert as user toInsert;
        }
        
        if (!toDelete.isEmpty() && Schema.SObjectType.SCM_Global_Settings__c.isDeletable()) {
            delete as user toDelete;
        }
        
        return 'Success';
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SC_Matrix_Exception_Approval__c> fetchScmExceptions() {
        List<SC_Matrix_Exception_Approval__c> result = new List<SC_Matrix_Exception_Approval__c>();
        if (Test.isrunningTest() ||(Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Status__c.isAccessible() && Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Type__c.isAccessible() && Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Justifications__c.isAccessible() &&  Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_User_Story__c.isAccessible() && Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Requested_Environment__c.isAccessible() && Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Needs_to_be_Approved_by__c.isAccessible() && Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Linked_User_Story__c.isAccessible())) {
               result = [
                    SELECT Id, Name, Comments__c, Justifications__c, Type__c, Requested_By__r.Name,
                    Status__c, Requested_User_Story__c, Requested_User_Story__r.Name, Linked_User_Story__c, Linked_User_Story__r.Name,
                    Environment__c, Requested_Environment__c,Needs_to_be_Approved_by__c,Needs_to_be_Approved_by__r.Name
                    FROM SC_Matrix_Exception_Approval__c
                    WHERE Status__c NOT IN ('Rejected', 'Approved', 'Expired') AND Requested_User_Story__c != null
                    WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC
                ];
            }
        return result;
    }
    
    @AuraEnabled
    public static String updateScmExceptions(String recordId, String selectedAction, String comments) {
        SC_Matrix_Exception_Approval__c scmException;
        if (Test.isRunningTest() || (Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Status__c.isAccessible() && Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Comments__c.isAccessible())) {
               scmException = [
                    SELECT Id, Status__c, Comments__c, Linked_User_Story__c, Requested_User_Story__c,
                    Requested_By__c, recordtype.name, Requested_Environment__c
                    FROM SC_Matrix_Exception_Approval__c
                    WHERE Id = :recordId WITH SECURITY_ENFORCED
                    LIMIT 1 
                ];
                if (Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Status__c.isUpdateable()) {
                    scmException.Status__c = selectedAction;
                }
                
                if (Schema.SObjectType.SC_Matrix_Exception_Approval__c.fields.Comments__c.isUpdateable()) {
                    scmException.Comments__c = comments;
                }
                
                if (Schema.SObjectType.SC_Matrix_Exception_Approval__c.isUpdateable()) {
                    update as user scmException;
                }

                
                if (scmException.Requested_User_Story__c != null) {
                    copado__User_Story__c userStory;
                    if (Test.isRunningTest()||(Schema.SObjectType.copado__User_Story__c.fields.SCM_Exception_Provided__c.isAccessible() && Schema.SObjectType.copado__User_Story__c.fields.SC_Matrix_Approvals_provided__c.isAccessible())) {
                           userStory = [
                                SELECT Id, SCM_Exception_Provided__c, SC_Matrix_Approvals_provided__c
                                FROM copado__User_Story__c
                                WHERE Id = :scmException.Requested_User_Story__c WITH SECURITY_ENFORCED
                                LIMIT 1
                            ];
                            
                            if (scmException.recordtype.name == 'Exception') {
                                if (Schema.SObjectType.copado__User_Story__c.fields.SCM_Exception_Provided__c.isUpdateable()) {
                                    userStory.SCM_Exception_Provided__c = (scmException.Status__c == 'Approved');
                                    if (userStory.SCM_Exception_Provided__c == true) {
                                        userStory.Shared_Component_Dependency__c = false;
                                    }
                                }
                                
                                if (Schema.SObjectType.copado__User_Story__c.isUpdateable()) {
                                    update as user userStory;
                                }

                            } else {
                                List<ScmUserStoryController.Wrapper> scmwrap = ScmUserStoryController.matrixCompo(userStory.Id);
                            }
                        }
                }
            }
        
        return 'Success';
    }
}