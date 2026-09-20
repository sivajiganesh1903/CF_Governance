public with sharing class ResultFileController {
    public String htmlContent { get; set; }

    public ResultFileController() {
        //String recordId = ApexPages.currentPage().getParameters().get('recordId');
        string recordId ='a167e000002QpqyAAC';
        if (recordId == null) {
            htmlContent = 'Error: No record ID provided.';
            return;
        }

        // Find latest ContentDocument linked to the record
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId ORDER BY SystemModstamp DESC LIMIT 1];
        if (links.isEmpty()) {
            htmlContent = 'Error: No file found.';
            return;
        }

        // Get latest version of the file
        ContentDocument doc = [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :links[0].ContentDocumentId LIMIT 1];
        ContentVersion version = [SELECT VersionData FROM ContentVersion WHERE Id = :doc.LatestPublishedVersionId LIMIT 1];

        // Read the file content (binary)
        Blob fileBlob = version.VersionData;
        htmlContent = fileBlob.toString(); // assumes file is HTML-safe UTF-8
    }
}