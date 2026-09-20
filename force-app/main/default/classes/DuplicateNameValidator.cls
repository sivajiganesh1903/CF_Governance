public with sharing class DuplicateNameValidator {
    public static void validateDuplicateName(copado__Deployment_Task__c record) {
        //getting the name of record being created
        String recordName = record.Name;
        System.debug('current created record name +++++'+recordName);


        // Query existing records with the same name
        List<copado__Deployment_Task__c> existingRecords = [SELECT Id, Name FROM copado__Deployment_Task__c WHERE Name = :recordName LIMIT 1];
        System.debug('Exisiting Records found ++++++'+existingRecords);
        
        // If duplicates are found (excluding the current record for update), add an error to the record
        if (!existingRecords.isEmpty() && (record.Id == null || existingRecords[0].Id != record.Id)) {
            record.addError('A record with this name already exists. Please choose a different name.');
        }
    }
}