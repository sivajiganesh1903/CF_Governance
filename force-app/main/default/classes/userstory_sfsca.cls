public with sharing class userstory_sfsca {
    public Id userStoryId;
    
    // Constructor that accepts the User Story ID as a parameter
    public userstory_sfsca(Id userStoryId) {
        this.userStoryId = userStoryId;
    }

    // Method to query copado__User_Story_Metadata__c based on the User Story ID
    public List<copado__User_Story_Metadata__c> getUserStoryMetadata() {
        if (userStoryId == null) {
            throw new IllegalArgumentException('User Story ID cannot be null.');
        }

        // Query copado__User_Story_Metadata__c where it references the provided User Story ID
        List<copado__User_Story_Metadata__c> userStoryMetadataRecords = [
            SELECT Id, Name /* Add any other relevant fields here */
            FROM copado__User_Story_Metadata__c
            WHERE copado__User_Story__c = :userStoryId
        ];
        
        return userStoryMetadataRecords;
    }
}