/**
 * @description Invocable class to trigger Jenkins Actions for User Story commits.
 * It queries attachment records, decodes the content, and triggers CI jobs if specific metadata types are found.
 * @author Vishnu Ramagoni
 * @date 26-03-2025
 */
public with sharing class SCAAutomation {
        /**
         * @description Invocable method to process Jenkins actions for User Stories.
         * @param ids List of copado__User_Story_Commit__c records.
         */
        @InvocableMethod(label='Jenkins Actions')
        public static void getuserstory(List<copado__User_Story_Commit__c> ids) {
    
            // Query the attachment
            Attachment attachmentRecord = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :ids[0].copado__Snapshot_Commit__c WITH SECURITY_ENFORCED LIMIT 1];
            
            // Decode the attachment content
            Blob attachmentBlob = attachmentRecord.Body;
            String jsonString = attachmentBlob.toString();
            
            Boolean checkvar = false;
            checkvar= jsonString.contains('ApexClass')?true:(jsonString.contains('ApexTrigger')?true:(jsonString.contains('LightningComponentBundle')?true:(jsonString.contains('ApexPage')?true:false)));
    
            if(checkvar){
                userstorysfsca.createcijob(ids[0].copado__User_Story__c);
            }
            
        }
    }