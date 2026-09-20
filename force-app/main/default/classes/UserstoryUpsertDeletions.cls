/**
 * @description Handler class to validate User Story metadata files before promotion.
 * Prevents User Stories from being promoted when both Git upsert metadata (Git MetaData) and deletion metadata (Delete MetaData) 
 * files are present, as these operations are mutually exclusive in a single deployment.
 */
public with sharing class UserstoryUpsertDeletions {    
    // Constants for file names to avoid magic strings
    private static final String DELETE_METADATA_FILE = 'Delete MetaData';
    private static final String GIT_METADATA_FILE = 'Git MetaData';
    private static final String VALIDATION_ERROR_MESSAGE = '"Git Upserts" and "Git Deletion" cannot be selected together in the same User Story';
    private static final Integer MIN_FILE_CONTENT_LENGTH = 3;   
    /**
     * @description Recursion prevention flag to avoid infinite trigger loops
     */
    private static Boolean isExecuting = false;   
    /**
     * @description Validates User Stories before promotion to ensure Git MetaData and Delete MetaData files are not both present. 
     * This method should be called from a User Story trigger on before update.
     * @param newUserStories List of User Story records with new values from trigger context
     * @param oldUserStoriesMap Map of User Story records with old values (Id => User_Story__c)
     * @throws DmlException Adds field-level error to User Story record if validation fails
     */
    public static void beforePromoteChange(List<copado__User_Story__c> newUserStories, 
                                          Map<Id, copado__User_Story__c> oldUserStoriesMap) {      
        // Prevent recursion
        if (isExecuting) {
            return;
        }        
        try {
            isExecuting = true;         
            // Identify User Stories where Promote Change or Promote and Deploy was just checked
            Set<Id> userStoryIdsToProcess = new Set<Id>();           
            for (copado__User_Story__c newUS : newUserStories) {
                copado__User_Story__c oldUS = oldUserStoriesMap.get(newUS.Id);               
                // Check if promotion checkbox was just enabled
                Boolean promoteChangeChecked = newUS.copado__Promote_Change__c && !oldUS.copado__Promote_Change__c;
                Boolean promoteDeployChecked = newUS.copado__Promote_and_Deploy__c && !oldUS.copado__Promote_and_Deploy__c;               
                if (promoteChangeChecked || promoteDeployChecked) {
                    userStoryIdsToProcess.add(newUS.Id);
                }
            }           
            // Exit early if no User Stories need validation
            if (userStoryIdsToProcess.isEmpty()) {
                return;
            }          
            // Query classic Attachments (legacy file storage)
            List<Attachment> attachments = [SELECT Id, Name, Body, ParentId, ContentType FROM Attachment WHERE ParentId IN :userStoryIdsToProcess 
                                            AND (Name = :DELETE_METADATA_FILE OR Name = :GIT_METADATA_FILE) ORDER BY ParentId, Name];         
            System.debug('Total classic attachments found: ' + attachments.size());        
            // Query Salesforce Files (ContentDocumentLink - modern file storage)
            List<ContentDocumentLink> contentLinks = [SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId 
                                                      FROM ContentDocumentLink WHERE LinkedEntityId IN :userStoryIdsToProcess 
                                                      AND (ContentDocument.Title = :DELETE_METADATA_FILE 
                                                           OR ContentDocument.Title = :GIT_METADATA_FILE)];           
            System.debug('Total content links found: ' + contentLinks.size());          
            // Exit if no files found
            if (attachments.isEmpty() && contentLinks.isEmpty()) {
                System.debug('No files or attachments found for any User Story');
                return;
            }        
            // Build map of User Story Id => (File Name => File Content)
            Map<Id, Map<String, String>> userStoryAttachmentData = new Map<Id, Map<String, String>>();            
            // Process classic Attachments
            for (Attachment att : attachments) {
                if (!userStoryAttachmentData.containsKey(att.ParentId)) {
                    userStoryAttachmentData.put(att.ParentId, new Map<String, String>());
                }
                String attachmentContent = att.Body.toString();
                userStoryAttachmentData.get(att.ParentId).put(att.Name, attachmentContent);
            }           
            // Process Salesforce Files (ContentVersion)
            if (!contentLinks.isEmpty()) {
                Set<Id> versionIds = new Set<Id>();
                Map<Id, Id> versionToStory = new Map<Id, Id>();                
                for (ContentDocumentLink link : contentLinks) {
                    System.debug('CDL: ' + link);
                    versionIds.add(link.ContentDocument.LatestPublishedVersionId);
                    versionToStory.put(link.ContentDocument.LatestPublishedVersionId, link.LinkedEntityId);
                }
                List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion 
                                                        WHERE Id IN :versionIds];              
                System.debug('Total ContentVersions found: ' + contentVersions.size());              
                for (ContentVersion cv : contentVersions) {
                    Id storyId = versionToStory.get(cv.Id);                  
                    if (!userStoryAttachmentData.containsKey(storyId)) {
                        userStoryAttachmentData.put(storyId, new Map<String, String>());
                    }
                    String fileContent = cv.VersionData.toString();
                    System.debug('File Content Length for ' + cv.Title + ' = ' + fileContent.length());
                    userStoryAttachmentData.get(storyId).put(cv.Title, fileContent);
                }
            }           
            // Validate: ensure Git MetaData and Delete MetaData don't coexist
            for (Id usId : userStoryAttachmentData.keySet()) {
                Map<String, String> fileMap = userStoryAttachmentData.get(usId);              
                Boolean hasGit = fileMap.containsKey(GIT_METADATA_FILE) && fileMap.get(GIT_METADATA_FILE) != null && 
                                fileMap.get(GIT_METADATA_FILE).length() > MIN_FILE_CONTENT_LENGTH;
                
                Boolean hasDelete = fileMap.containsKey(DELETE_METADATA_FILE) && fileMap.get(DELETE_METADATA_FILE) != null && 
                                   fileMap.get(DELETE_METADATA_FILE).length() > MIN_FILE_CONTENT_LENGTH;               
                if (hasGit && hasDelete) {
                    // Add error to the User Story record to prevent save
                    if (Trigger.newMap.containsKey(usId)) {
                        Trigger.newMap.get(usId).addError(VALIDATION_ERROR_MESSAGE);
                    }
                } else {
                    System.debug('✔ VALIDATION PASSED for User Story: ' + usId);
                }
            }  
        } finally {
            // Always reset recursion flag
            isExecuting = false;
        }
    }
}