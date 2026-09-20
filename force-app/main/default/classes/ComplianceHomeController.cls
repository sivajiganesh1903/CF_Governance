public with sharing class ComplianceHomeController {
 
    @AuraEnabled(cacheable=true)
    public static List<copado__Deployment_Flow__c> getPipelines() {
        return [
            SELECT Id, Name
            FROM copado__Deployment_Flow__c
            ORDER BY Name
        ];
    }
 
    // Main Releases
    @AuraEnabled(cacheable=true)
    public static List<Main_Release__c> getMainReleasesByPipeline(Id pipelineId) {
        return [
            SELECT Id, Name
            FROM Main_Release__c
            WHERE Pipeline__c = :pipelineId
            ORDER BY Name
        ];
    }
 
    // ✅ Updated method to include fetching metadata component and metadata type
    @AuraEnabled(cacheable=true)
    public static List<copado__User_Story__c> getUserStoriesByMainRelease(Id mainReleaseId) {
        return [
            SELECT
                Id,
                Name,
                copado__Release__r.Name,
                copado__Release__r.Main_Release__c,
                Exception_Hotfix_Requirement__c,
                Exception_Justification__c,
                Exception_Approver__c,
                copado__Org_Credential__r.Name,
                copado__Developer__r.Name,
                copado__Team__r.Name,
                copado__Metadata_Types_in_Selection__c,
                (
                    SELECT Id, copado__Metadata_API_Name__c, copado__Type__c
                    FROM copado__User_Story_Metadata__r
                )
            FROM copado__User_Story__c
            WHERE copado__Release__r.Main_Release__c = :mainReleaseId
        ];
    }
}