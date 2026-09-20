public with sharing class CopadoReleaseController {
    // Wrapper for User Story Data
    public class UserStoryWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String jiraKey { get; set; }
        @AuraEnabled public String prioritySeverity { get; set; }
        @AuraEnabled public String recordTypeId { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public String userStoryTitle { get; set; }
        @AuraEnabled public String teamId { get; set; }
        @AuraEnabled public String teamName { get; set; }
        @AuraEnabled public String developerId { get; set; }
        @AuraEnabled public String releaseId { get; set; }
        @AuraEnabled public String releaseName { get; set; }
        @AuraEnabled public String status { get; set; }
    }
    
    // Wrapper for Release data
    public class ReleaseWrapper {
        @AuraEnabled public Id releaseId { get; set; }
        @AuraEnabled public String releaseName { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String projectName { get; set; }
        @AuraEnabled public String deploymentFlowName { get; set; }
    }
    
    // Fetch the User stories associated with the Release records
    @AuraEnabled(cacheable=true)
    public static List<UserStoryWrapper> getUserStories(Id releasePlaybookId) {
        system.debug('Release Playbook Id: ' + releasePlaybookId);
        // Querying Releases associated with Release Playbook   
        List<copado__Release__c> releases = [SELECT Id, Release_Playbook__c FROM copado__Release__c 
                                             WHERE Release_Playbook__c = :releasePlaybookId];
        Set<Id> releaseIds = new Set<Id>();        
        for (copado__Release__c release : releases) {
            releaseIds.add(release.Id);
        }
        List<UserStoryWrapper> userStoriesWrapper = new List<UserStoryWrapper>();
        if (!releaseIds.isEmpty()) {
            List<copado__User_Story__c> userStories = [SELECT Id, Name, Jira_Key__c, Priority_Severity__c,
                                                       RecordTypeId, RecordType.Name, copado__User_Story_Title__c, 
                                                       copado__Team__c, copado__Team__r.Name, copado__Developer__r.Name,
                                                       copado__Release__c, copado__Release__r.Name, copado__Status__c 
                                                       FROM copado__User_Story__c 
                                                       WHERE copado__Release__c IN :releaseIds AND copado__Status__c != 'Cancelled'];
            for (copado__User_Story__c story : userStories) {
                UserStoryWrapper wrapper = new UserStoryWrapper();
                wrapper.Id = story.Id;
                wrapper.name = story.Name;
                wrapper.jiraKey = story.Jira_Key__c;
                wrapper.prioritySeverity = story.Priority_Severity__c;
                wrapper.recordTypeId = story.RecordTypeId;
                wrapper.recordTypeName = story.RecordType.Name;
                wrapper.userStoryTitle = story.copado__User_Story_Title__c;
                wrapper.teamId = story.copado__Team__c;
                wrapper.teamName = story.copado__Team__r.Name;
                wrapper.developerId = story.copado__Developer__r.Name;
                wrapper.releaseId = story.copado__Release__c;
                wrapper.releaseName = story.copado__Release__r.Name;
                wrapper.status = story.copado__Status__c;
                userStoriesWrapper.add(wrapper);
            }
        }
        return userStoriesWrapper;
    }
    
    // Fetch the Release associated with the Project records
    @AuraEnabled(cacheable=true)
    public static List<ReleaseWrapper> getCopadoReleases() {
        try {
            List<ReleaseWrapper> results = new List<ReleaseWrapper>();
            List<copado__Release__c> releases = [SELECT Id, Name, copado__Status__c, Release_Playbook__c,
                                                 copado__Project__r.Name, 
                                                 copado__Project__r.copado__Deployment_Flow__r.Name 
                                                 FROM copado__Release__c 
                                                 WHERE copado__Project__r.copado__Deployment_Flow__r.Name = 'FSC Salesforce' 
                                                 AND Release_Playbook__c = NULL];
            for (copado__Release__c release : releases) {
                ReleaseWrapper wrapper = new ReleaseWrapper();
                wrapper.releaseId = release.Id;
                wrapper.releaseName = release.Name;
                wrapper.status = release.copado__Status__c;
                wrapper.projectName = release.copado__Project__r.Name;
                wrapper.deploymentFlowName = release.copado__Project__r.copado__Deployment_Flow__r.Name;
                results.add(wrapper);
            }
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Fetch Keyword based releases
    @AuraEnabled(cacheable=true)
    public static List<ReleaseWrapper> fetchReleases(String searchKeyR) {
        if (String.isNotBlank(searchKeyR)) {
            String key = '%' + searchKeyR + '%';
            List<ReleaseWrapper> results = new List<ReleaseWrapper>();
            List<copado__Release__c> releases = [SELECT Id, Name, copado__Status__c, Release_Playbook__c, 
                                                 copado__Project__r.Name,
                                                 copado__Project__r.copado__Deployment_Flow__r.Name 
                                                 FROM copado__Release__c 
                                                 WHERE copado__Project__r.copado__Deployment_Flow__r.Name = 'FSC Salesforce' 
                                                 AND Release_Playbook__c = NULL AND Name LIKE :key ORDER BY Name ASC];
            for (copado__Release__c release : releases) {
                ReleaseWrapper wrapper = new ReleaseWrapper();
                wrapper.releaseId = release.Id;
                wrapper.releaseName = release.Name;
                wrapper.status = release.copado__Status__c;
                wrapper.projectName = release.copado__Project__r.Name;
                wrapper.deploymentFlowName = release.copado__Project__r.copado__Deployment_Flow__r.Name;
                results.add(wrapper);
            }
            return results;
        } else {
            return getCopadoReleases(); // Call the method to get all releases if no search key is provided
        }
    }
    
    @AuraEnabled
    public static void saveRelease(Id playbookId, List<Id> releaseIds) {
        system.debug('PlaybookId==> ' + playbookId);
        List<copado__Release__c> releasesToUpdate = [SELECT Id FROM copado__Release__c WHERE Id IN :releaseIds];
        for (copado__Release__c rel : releasesToUpdate) {
            rel.Release_Playbook__c = playbookId;
        }
        update releasesToUpdate;
    }
    // Retreive All Users 
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers() {
        try{
            return [SELECT Id, Name, MobilePhone, Email, CompanyName, SenderEmail, Profile.Name FROM User 
                    ORDER BY Name ASC];
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }        
    }
    
    @AuraEnabled
    public static void saveReleaseAssignments(Id playbookId, List<Id> userIds) {
        try {
            List<User> users = [SELECT Id, MobilePhone, CompanyName, Email, Designation__c FROM User WHERE Id IN :userIds];
            List<Release_Assignment__c> assignments = new List<Release_Assignment__c>();
            for (User user : users) {
                Release_Assignment__c assignment = new Release_Assignment__c();
                assignment.Name__c = user.Id;
                assignment.Release_Playbook__c = playbookId;
                assignment.Contact__c = user.MobilePhone;
                assignment.Company__c = user.CompanyName;
                assignment.Email__c = user.Email;  
                assignment.Role__c = user.Designation__c;
                Id recordTypeId = Release_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Assignment Users').getRecordTypeId();
                System.debug('Record Type ID for Assignment Users: ' + recordTypeId);
                assignment.RecordTypeId = recordTypeId;
                assignments.add(assignment);
            }
            insert assignments;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    // Fetch Keyword based Users
    @AuraEnabled(cacheable=true)
    public static List<User> fetchUsers(String searchKey) {
        if (String.isNotBlank(searchKey)) {
            String key = '%' + searchKey + '%';
            return [SELECT Id, Name, Email FROM User WHERE Name LIKE :key OR Email LIKE :key ORDER BY Name ASC];
        } else {
            return [SELECT Id, Name, Email FROM User];
        }
    }
}