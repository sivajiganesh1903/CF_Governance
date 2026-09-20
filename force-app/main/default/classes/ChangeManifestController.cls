public with sharing class ChangeManifestController {
    
    /**
     * Get all Main Releases ordered by name
     */
    @AuraEnabled(cacheable=true)
    public static List<Main_Release__c> getMainReleases() {
        try {
            return [
                SELECT Id, Name
                FROM Main_Release__c
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Main Releases: ' + e.getMessage());
        }
    }
    
    /**
     * Get all metadata components for user stories under a Main Release
     * Includes CreatedDate and LastModifiedDate for action calculation
     */
    @AuraEnabled(cacheable=true)
    public static List<copado__User_Story__c> getMetadataComponentsByMainRelease(Id mainReleaseId) {
        try {
            
            if (mainReleaseId == null) {
                throw new AuraHandledException('Main Release ID is required');
            }
            
            return [
                SELECT
                    Id,
                    Name,
                    copado__Release__r.Name,
                    (
                        SELECT 
                            Id, 
                            copado__Metadata_API_Name__c, 
                            copado__Type__c,
                            CreatedDate,
                            LastModifiedDate
                        FROM copado__User_Story_Metadata__r
                        ORDER BY copado__Type__c, copado__Metadata_API_Name__c
                    )
                FROM copado__User_Story__c
                WHERE copado__Release__r.Main_Release__c = :mainReleaseId
                ORDER BY copado__Release__r.Name, Name
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching metadata components: ' + e.getMessage());
        }
    }
    
    /**
     * Alternative method: Get metadata components with explicit action calculation
     * This can be used if you want server-side action calculation
     */
    @AuraEnabled(cacheable=true)
    public static List<MetadataComponentWrapper> getMetadataComponentsWithAction(Id mainReleaseId) {
        try {
            
            if (mainReleaseId == null) {
                throw new AuraHandledException('Main Release ID is required');
            }
            
            List<MetadataComponentWrapper> results = new List<MetadataComponentWrapper>();
            
            List<copado__User_Story__c> userStories = [
                SELECT
                    Id,
                    Name,
                    copado__Release__r.Name,
                    (
                        SELECT 
                            Id, 
                            copado__Metadata_API_Name__c, 
                            copado__Type__c,
                            CreatedDate,
                            LastModifiedDate
                        FROM copado__User_Story_Metadata__r
                    )
                FROM copado__User_Story__c
                WHERE copado__Release__r.Main_Release__c = :mainReleaseId
            ];
            
            for (copado__User_Story__c us : userStories) {
                if (us.copado__User_Story_Metadata__r != null) {
                    for (copado__User_Story_Metadata__c metadata : us.copado__User_Story_Metadata__r) {
                        
                        MetadataComponentWrapper wrapper = new MetadataComponentWrapper();
                        wrapper.id = metadata.Id;
                        wrapper.metadataType = metadata.copado__Type__c;
                        wrapper.component = metadata.copado__Metadata_API_Name__c;
                        wrapper.action = calculateAction(metadata.CreatedDate, metadata.LastModifiedDate);
                        wrapper.releaseName = us.copado__Release__r?.Name;
                        wrapper.userStoryName = us.Name;
                        
                        results.add(wrapper);
                    }
                }
            }
            
            return results;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching metadata components: ' + e.getMessage());
        }
    }
    
    /**
     * Calculate whether a component was Created or Modified
     */
    private static String calculateAction(DateTime createdDate, DateTime lastModifiedDate) {
        if (createdDate == null || lastModifiedDate == null) {
            return 'Unknown';
        }
        
        // If created and modified dates are the same (or within 1 second), it's Created
        Long timeDifference = Math.abs(createdDate.getTime() - lastModifiedDate.getTime());
        
        if (timeDifference < 1000) {
            return 'Created';
        } else {
            return 'Modified';
        }
    }
    
    /**
     * Wrapper class for metadata component with action
     */
    public class MetadataComponentWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String metadataType { get; set; }
        @AuraEnabled public String component { get; set; }
        @AuraEnabled public String action { get; set; }
        @AuraEnabled public String releaseName { get; set; }
        @AuraEnabled public String userStoryName { get; set; }
    }
}