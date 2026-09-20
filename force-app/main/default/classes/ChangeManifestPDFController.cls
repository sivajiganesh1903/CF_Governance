public with sharing class ChangeManifestPDFController {

    public String pipelineName { get; set; }
    public String mainReleaseName { get; set; }
    public List<ManifestRow> manifestRows { get; set; }

    public class ManifestRow {
        public String metadataType { get; set; }
        public String component { get; set; }
        public String action { get; set; }
    }

    public ChangeManifestPDFController() {
        Id mainReleaseId = ApexPages.currentPage().getParameters().get('mainReleaseId');

        if (mainReleaseId != null) {

            Main_Release__c mr = [
                SELECT Id, Name, Pipeline__r.Name
                FROM Main_Release__c
                WHERE Id = :mainReleaseId
                LIMIT 1
            ];

            pipelineName = mr.Pipeline__r.Name;
            mainReleaseName = mr.Name;

            // Get Releases
            Set<Id> releaseIds = new Set<Id>();
            for (copado__Release__c rel : [
                SELECT Id FROM copado__Release__c WHERE Main_Release__c = :mainReleaseId
            ]) {
                releaseIds.add(rel.Id);
            }

            // Get Promotions
            Set<Id> promotionIds = new Set<Id>();
            for (copado__Promotion__c promo : [
                SELECT Id FROM copado__Promotion__c WHERE copado__Release__c IN :releaseIds
            ]) {
                promotionIds.add(promo.Id);
            }

            // Get User Story IDs via Junction
            Set<Id> userStoryIds = new Set<Id>();
            for (copado__Promoted_User_Story__c pus : [
                SELECT copado__User_Story__c
                FROM copado__Promoted_User_Story__c
                WHERE copado__Promotion__c IN :promotionIds
            ]) {
                userStoryIds.add(pus.copado__User_Story__c);
            }

            // Get User Stories with Metadata
            List<copado__User_Story__c> userStories = [
                SELECT
                    Id,
                    Name,
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
                WHERE Id IN :userStoryIds
            ];

            manifestRows = new List<ManifestRow>();

            for (copado__User_Story__c us : userStories) {
                if (us.copado__User_Story_Metadata__r != null) {
                    for (copado__User_Story_Metadata__c metadata : us.copado__User_Story_Metadata__r) {
                        ManifestRow row = new ManifestRow();
                        row.metadataType = metadata.copado__Type__c;
                        row.component = metadata.copado__Metadata_API_Name__c;
                        row.action = (metadata.CreatedDate == metadata.LastModifiedDate) 
                            ? 'Created' 
                            : 'Modified';
                        manifestRows.add(row);
                    }
                }
            }
        }
    }
}