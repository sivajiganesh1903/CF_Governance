public class UserStoryCommitHandler {
    public static void getSnapshotFilesAndAttachments(List<copado__User_Story_Commit__c> newStoryCommits) {
        // Store User Story Commit Ids
        set<Id> storyCommitIds=new set<Id>();
        for(copado__User_Story_Commit__c storyCommitId: newStoryCommits){
            storyCommitIds.add(storyCommitId.Id);
        }
        System.debug('Story CommitIds: ' + storyCommitIds);
        
        // Query the User Story Commits
        List<copado__User_Story_Commit__c> userStoryCommits = [SELECT Id, Name, copado__User_Story__c, 
                                                               copado__User_Story__r.Name, copado__Snapshot_Commit__c, 
                                                               copado__Snapshot_Commit__r.Name, 
                                                               copado__Snapshot_Commit__r.copado__Commit_Message__c 
                                                               FROM copado__User_Story_Commit__c WHERE 
                                                               Id IN: storyCommitIds];
        System.debug('User Story Commits: ' + userStoryCommits);
        
        // Collect Snapshot Commit IDs
        Set<Id> snapshotCommitIds = new Set<Id>();
        for (copado__User_Story_Commit__c userStoryCommit : userStoryCommits) {
            if (userStoryCommit.copado__Snapshot_Commit__c != null) {
                snapshotCommitIds.add(userStoryCommit.copado__Snapshot_Commit__c);
            }
        }
        System.debug('Snapshot Commit Ids: ' + snapshotCommitIds);
        
        // Query for attachments related to the Snapshot Commits With Name as METADATA
        List<Attachment> attachments = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment 
                                        WHERE Name IN ('MetaData', 'METADATA') AND ParentId IN :snapshotCommitIds];
        
        System.debug('Attachments: +++ ' + attachments);
        
        List<Attachment> newAttachments = new List<Attachment>();
        List<Attachment> attachmentsToDelete = new List<Attachment>();
        
        // Process the attachments
        for (Attachment att : attachments) {
            System.debug('Attachment Name: ' + att.Name);
            String content = att.Body.toString();
            System.debug('Attachment Body: ' + content);
            
            // Parse the JSON content
            List<Object> jsonList = (List<Object>)JSON.deserializeUntyped(content);
            
            // Create a new list to store the filtered objects
            List<Object> filteredList = new List<Object>();
            Boolean customOrderHandlerFound = false;
            
            // Filter out the object with "t": "CustomLabels"
            for (Object obj : jsonList) {
                Map<String, Object> objMap = (Map<String, Object>)obj;
                if (objMap.get('t') == 'CustomLabels') {
                    customOrderHandlerFound = true;
                } else {
                    filteredList.add(obj);
                }
            }
            
            // Only create a new attachment and delete the old one if Custom Label was found
            if (customOrderHandlerFound) {
                // Convert the filtered list back to JSON
                String filteredContent = JSON.serialize(filteredList);
                
                // Create a new attachment with the filtered content
                Attachment newAtt = new Attachment();
                newAtt.ParentId = att.ParentId; // Attach to the same parent
                newAtt.Name = att.Name;
                newAtt.Body = Blob.valueOf(filteredContent);
                newAtt.ContentType = att.ContentType;
                
                newAttachments.add(newAtt);
                attachmentsToDelete.add(att);
                
                System.debug('New Attachment prepared for: ' + att.ParentId);
                System.debug('Filtered Content: ' + filteredContent);
            } else {
                System.debug('No Custom Label Metadata type found in attachment for: ' + att.ParentId + '. No changes made.');
            }
        }
        
        // Insert new attachments
        if (!newAttachments.isEmpty()) {
            insert newAttachments;
            System.debug('New Attachments inserted: ++++' + newAttachments.size());
        }
        
        // Delete old attachments
        if (!attachmentsToDelete.isEmpty()) {
            delete attachmentsToDelete;
            System.debug('Old Attachments deleted: ++++ ' + attachmentsToDelete.size());
        }
        
        System.debug('Total Attachments processed: ++++ ' + attachments.size());
        System.debug('Attachments modified: ++++ ' + newAttachments.size());
    }
}