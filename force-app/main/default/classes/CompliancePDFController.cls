public with sharing class CompliancePDFController {

    public String pipelineName { get; set; }
    public String mainReleaseName { get; set; }
    public List<RowWrapper> tableRows { get; set; }
    public List<copado__User_Story__c> userStories { get; set; }

    public class RowWrapper {
        public String releaseName { get; set; }
        public String userStoryName { get; set; }
        public String exceptionHotfix { get; set; }
        public String exceptionJustification { get; set; }
        public String exceptionApprover { get; set; }
        public String metadataComponent { get; set; } 
        public String metadataType { get; set; }
        public String credential { get; set; }
        public String developer { get; set; }
        public String team { get; set; }
    }

    public CompliancePDFController() {
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
     
            List<copado__User_Story__c> userStories = [
                SELECT
                    Id,
                    Name,
                    copado__Release__r.Name,
                    Exception_Hotfix_Requirement__c,
                    Exception_Justification__c,
                    Exception_Approver__c,
                    copado__Org_Credential__r.Name,
                    copado__Developer__r.Name,
                    copado__Team__r.Name,
                    (
                        SELECT Id, copado__Metadata_API_Name__c, copado__Type__c 
                        FROM copado__User_Story_Metadata__r
                    )
                FROM copado__User_Story__c
                WHERE copado__Release__r.Main_Release__c = :mainReleaseId
            ];
            

            tableRows = new List<RowWrapper>();

            for (copado__User_Story__c us : userStories) {

                // ✅ Loop over committed components directly
                if (us.copado__User_Story_Metadata__r != null && !us.copado__User_Story_Metadata__r.isEmpty()) {

                    for (copado__User_Story_Metadata__c m : us.copado__User_Story_Metadata__r) {
                        RowWrapper row = new RowWrapper();
                        row.releaseName            = us.copado__Release__r != null ? us.copado__Release__r.Name : '';
                        row.userStoryName          = us.Name;
                        row.exceptionHotfix        = us.Exception_Hotfix_Requirement__c;
                        row.exceptionJustification = us.Exception_Justification__c;
                        row.exceptionApprover      = us.Exception_Approver__c;
                        row.metadataComponent      = m.copado__Metadata_API_Name__c; // ✅ component name
                        row.metadataType           = m.copado__Type__c;              // ✅ its type
                        row.credential             = us.copado__Org_Credential__r != null ? us.copado__Org_Credential__r.Name : '';
                        row.developer              = us.copado__Developer__r != null ? us.copado__Developer__r.Name : '';
                        row.team                   = us.copado__Team__r != null ? us.copado__Team__r.Name : '';
                        tableRows.add(row);
                    }

                } else {
                    // ✅ No components — still show user story with blank component/type
                    RowWrapper row = new RowWrapper();
                    row.releaseName            = us.copado__Release__r != null ? us.copado__Release__r.Name : '';
                    row.userStoryName          = us.Name;
                    row.exceptionHotfix        = us.Exception_Hotfix_Requirement__c;
                    row.exceptionJustification = us.Exception_Justification__c;
                    row.exceptionApprover      = us.Exception_Approver__c;
                    row.metadataComponent      = '';
                    row.metadataType           = '';
                    row.credential             = us.copado__Org_Credential__r != null ? us.copado__Org_Credential__r.Name : '';
                    row.developer              = us.copado__Developer__r != null ? us.copado__Developer__r.Name : '';
                    row.team                   = us.copado__Team__r != null ? us.copado__Team__r.Name : '';
                    tableRows.add(row);
                }
            }
        }
    }
}