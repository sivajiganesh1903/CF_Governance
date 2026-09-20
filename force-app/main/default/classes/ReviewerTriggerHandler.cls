public with sharing class ReviewerTriggerHandler {
    
    public static void handleBeforeInsertUpdate(List<Reviewer__c> newReviewers) {
        Set<Id> userIds = new Set<Id>();
        
        // Collect User IDs from the new or updated reviewers
        for (Reviewer__c rev : newReviewers) {
            if (rev.Reviewer_Name__c != null) {
                userIds.add(rev.Reviewer_Name__c);
            }
        }

        // Query existing reviewers in the system with the same User IDs
        Map<Id, Reviewer__c> existingReviewers = new Map<Id, Reviewer__c>();
        for (Reviewer__c existingRev : [
            SELECT Id, Reviewer_Name__c 
            FROM Reviewer__c 
            WHERE Reviewer_Name__c IN :userIds WITH SECURITY_ENFORCED
        ]) {
            existingReviewers.put(existingRev.Reviewer_Name__c, existingRev);
        }

        // Check for duplicates in the current transaction context and existing records
        for (Reviewer__c rev : newReviewers) {
            if (rev.Reviewer_Name__c != null) {
                Reviewer__c existingRev = existingReviewers.get(rev.Reviewer_Name__c);
                if (existingRev != null && existingRev.Id != rev.Id) {
                    rev.addError('A reviewer with this user already exists.');
                }
            }
        }
    }
}