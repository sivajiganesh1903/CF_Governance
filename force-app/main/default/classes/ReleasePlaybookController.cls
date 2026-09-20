public with sharing class ReleasePlaybookController {
    
    public class ReleasePlaybookWrapper {
        @AuraEnabled
        public Release_Playbook__c playbook { get; set; }
        @AuraEnabled
        public String pipelineName { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled 
        public Id Id { get; set; }
        @AuraEnabled 
        public String name { get; set; }
        @AuraEnabled 
        public String playbookName { get; set; }
        
        public ReleasePlaybookWrapper(Release_Playbook__c playbook) {
            this.playbook = playbook;
            this.pipelineName = playbook.Pipeline__r != null ? playbook.Pipeline__r.Name : null;
            this.status = playbook.Status__c;
            this.id = playbook.Id;
            this.name = playbook.Name;
            this.playbookName = playbook.Release_Playbook_Name__c;
        }
    }
    
    @AuraEnabled
    public static List<ReleasePlaybookWrapper> getTemplateRecs() {
        List<Release_Playbook__c> playbooks = [SELECT Id, Name, Pipeline__r.Name,Release_Template__c,Status__c FROM Release_Playbook__c 
                                               WHERE RecordType.Name = 'Release Playbook Template'];
        System.debug('Release Play Book Items are: ++++++ : ' + playbooks);
        
        List<ReleasePlaybookWrapper> wrappers = new List<ReleasePlaybookWrapper>();
        for (Release_Playbook__c playbook : playbooks) {
            wrappers.add(new ReleasePlaybookWrapper(playbook));
        }
        System.debug('Returning PlayBook are: ++++++ : ' + wrappers);
        return wrappers;
    }
    
    @AuraEnabled
    public static void createReleasePlaybookItems(Id releasePlaybookId, Id selectedTemplateId) {
        System.debug('Release Playbook ID: ' + releasePlaybookId);
        System.debug('Selected Template IDs: ' + selectedTemplateId);
        if (selectedTemplateId == null) {
            throw new AuraHandledException('No template IDs provided.');
        }
        try {
            // Check if items already exist for the given releasePlaybookId
            Integer existingItemCount = [SELECT COUNT() FROM Release_Playbook_Item__c WHERE Release_Playbook__c = :releasePlaybookId];
            if (existingItemCount > 0) {
                throw new AuraHandledException('Items already exist for the selected release playbook.');
            }
            
            Release_Playbook__c selectedTemplates = [SELECT Id, Name, Pipeline__c, Release_Template__c, Status__c
                                                     FROM Release_Playbook__c WHERE Id = :selectedTemplateId LIMIT 1];
            System.debug('Selected Templates: +++++ :' + selectedTemplates);
            if (selectedTemplates == null) {
                throw new AuraHandledException('Selected template items not found.');
            }
            
            // Query the child templates related to the selected templates
            List<Release_Playbook_Item__c> childTemplates = [SELECT Id, Name, Area__c, Execution_Sequence__c,  Environment__c,
                                                             End_Date_Time__c, Issues_Comments__c, Order__c, Pipeline__r.Name, SCA__c, 
                                                             Release_Playbook__c, Stage__c, Start_Date_Time__c, Status__c, Required_Sub_Item_s__c,
                                                             Task_Description__c, Release_Playbook_Template_Item__c FROM 
                                                             Release_Playbook_Item__c WHERE RecordType.Name = 'Release Item Templates' 
                                                             AND Release_Playbook__c = :selectedTemplates.Id];
            System.debug('Child Templates: ' + childTemplates);
            List<Release_Playbook_Item__c> newItems = new List<Release_Playbook_Item__c>();
            for (Release_Playbook_Item__c template : childTemplates) {
                Release_Playbook_Item__c newItem = new Release_Playbook_Item__c();
                newItem.Release_Playbook__c = releasePlaybookId;
                newItem.Area__c = template.Area__c;
                newItem.Required_Sub_Item_s__c = template.Required_Sub_Item_s__c;
                newItem.SCA__c = template.SCA__c;
                newItem.Environment__c = template.Environment__c;
                newItem.Execution_Sequence__c = template.Execution_Sequence__c;
                newItem.Issues_Comments__c = template.Issues_Comments__c;
                newItem.Order__c = template.Order__c;
                newItem.Stage__c = template.Stage__c;
                newItem.Status__c = template.Status__c;
                newItem.Task_Description__c = template.Task_Description__c;
                // Setting the self-lookup field to reference the template record
                newItem.Release_Playbook_Template_Item__c = template.Id;  // Replace 'Template_Lookup__c' with your actual field name
                newItem.RecordTypeId = Release_Playbook_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Release Activity').getRecordTypeId();
                newItems.add(newItem);
                System.debug('List of new Items : ++++ ' + newItems);
            }
            
            List<Release_Assignment__c> templateReleaseAssignees = [SELECT Id, Name__c, Company__c, Contact__c, Email__c, RecordType.Name, 
                                                                    Release_Playbook__c, Role__c FROM Release_Assignment__c 
                                                                    WHERE RecordType.Name = 'Template Release Assignments' 
                                                                    AND Release_Playbook__c = :selectedTemplates.Id];
            System.debug('templateReleaseAssignees are: +++++ ' + templateReleaseAssignees);
            
            List<Release_Assignment__c> newReleaseAssign = new List<Release_Assignment__c>();
            for (Release_Assignment__c templateReleaseAssign : templateReleaseAssignees) {
                Release_Assignment__c newAssign = new Release_Assignment__c();
                newAssign.Name__c = templateReleaseAssign.Name__c;
                newAssign.Company__c = templateReleaseAssign.Company__c;
                newAssign.Contact__c = templateReleaseAssign.Contact__c;
                newAssign.Email__c = templateReleaseAssign.Email__c;
                newAssign.Release_Playbook__c = releasePlaybookId;
                // Fetching the RecordTypeId
                Id recordTypeId = Release_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Assignment Users').getRecordTypeId();
                System.debug('Record Type ID for Assignment Users: ' + recordTypeId);
                newAssign.RecordTypeId = recordTypeId;
                newAssign.Role__c = templateReleaseAssign.Role__c;
                newReleaseAssign.add(newAssign);
                System.debug('List of new TemplateItems : ++++ ' + newReleaseAssign);
            }
            
            insert newReleaseAssign;
            System.debug('List of new TemplateItems : ++++ ' + newReleaseAssign);
            
            if (!newItems.isEmpty()) {
                System.debug('List of new Items in If Condition : ++++ ' + newItems);
                insert newItems;
            } else {
                throw new AuraHandledException('No new Release Playbook Template records to process.');
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Release Playbook Items: ' + e.getMessage());
        }
    }
    
}