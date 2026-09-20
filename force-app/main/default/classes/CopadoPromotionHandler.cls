public class CopadoPromotionHandler {
    public static void deleteGitReleatedAttachements(List<copado__Promotion__c> newPromotions, Map<Id, copado__Promotion__c> oldPromotions){
         /*copado__Git_Repository__c repository = [SELECT Id FROM copado__Git_Repository__c WHERE 
												   Name LIKE 'Trial - Salesforce Metadata Format Copado-sivaji08' LIMIT 1];*/
        for (copado__Promotion__c promotion : newPromotions) {
            copado__Promotion__c promotionGitId = [SELECT Id, Name, copado__Source_Environment__c, copado__Source_Environment__r.Name, 
                                                   copado__Destination_Environment__c, copado__Destination_Environment__r.Store_Conflict_Files__c,
                                                   copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.Id, 
                                                   copado__Destination_Environment__r.Name, copado__Destination_Environment__r.copado__Type__c, 
                                                   copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.Name 
                                                   FROM copado__Promotion__c WHERE Id = :promotion.Id];
            Id gitRepoId = promotionGitId.copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.Id;
            System.debug('Git Repository Id: +++' + promotionGitId);
            copado__Promotion__c oldPromotion = oldPromotions.get(promotion.Id);
            
            if ((promotion.copado__Status__c == 'Completed' && oldPromotion.copado__Status__c != 'Completed') 
                && promotionGitId.copado__Destination_Environment__r.Store_Conflict_Files__c == false) {                                            
                    // Query to fetch attachments related to the promotion with names ending in .json
                    List<Attachment> conflictAttachments = [SELECT Id, Name, ContentType, Body, ParentId FROM Attachment
                                                            WHERE ParentId = :promotion.Id AND Name LIKE '%.json'];                
                    // List to store "smartOnlineResolutionKey" values
                    List<String> resolutionKeys = new List<String>();                
                    // Iterate through the attachments to extract the "smartOnlineResolutionKey"
                    for (Attachment attachment : conflictAttachments) {
                        try {
                            // Convert the body content from Blob to String
                            String jsonString = attachment.Body.toString();                        
                            // Deserialize the JSON string
                            Object deserializedJson = JSON.deserializeUntyped(jsonString);                        
                            
                            if (deserializedJson instanceof Map<String, Object>) {
                                // JSON is an object, so we cast to a Map
                                Map<String, Object> jsonMap = (Map<String, Object>) deserializedJson;
                                if (jsonMap.containsKey('smartOnlineResolutionKey')) {
                                    resolutionKeys.add((String) jsonMap.get('smartOnlineResolutionKey'));
                                }
                            } else if (deserializedJson instanceof List<Object>) {
                                // JSON is an array, so we iterate over the List
                                List<Object> jsonList = (List<Object>) deserializedJson;
                                for (Object jsonElement : jsonList) {
                                    if (jsonElement instanceof Map<String, Object>) {
                                        Map<String, Object> jsonMap = (Map<String, Object>) jsonElement;
                                        if (jsonMap.containsKey('smartOnlineResolutionKey')) {
                                            resolutionKeys.add((String) jsonMap.get('smartOnlineResolutionKey'));
                                            // Removed the break to ensure all occurrences are added
                                            // If you only need the first occurrence, break after finding it  break;
                                        }
                                    }
                                }
                            } else {
                                System.debug('Unexpected JSON format in attachment: ' + attachment.Name);
                            }
                        } catch (Exception e) {
                            System.debug('Failed to parse JSON content from attachment: ' + attachment.Name + ' Error: ' + e.getMessage());
                        }
                    }                
                    System.debug('Resolution Keys==> ' + resolutionKeys);
                    
                    if (promotionGitId != null) {
                        System.debug('Repository Id: ++++++' + gitRepoId);
                        List<Attachment> conflictAttachments1 = [SELECT Id, Name FROM Attachment WHERE ParentId = :gitRepoId
                                                                 AND Name IN :resolutionKeys];
                        System.debug('.conflict files==> ' + conflictAttachments1);                    
                        
                        // Check if there are any attachments to delete
                        if (!conflictAttachments1.isEmpty()) {
                            try {
                                // Perform the delete operation
                                delete conflictAttachments1;
                                System.debug('Deleted ' + conflictAttachments1.size() + ' .conflict files successfully.');
                            } catch (DmlException e) {
                                System.debug('Error deleting .conflict files: ' + e.getMessage());
                                // Handle the exception as needed
                            }
                        } else {
                            System.debug('No .conflict files found to delete.');
                        }
                    }
                } else {
                    System.debug('Git repository not found.');
                }
        }
    }
}