public class CustomLabelsAutomation {
	/**
     * Main method to process the snapshot commits and update attachments.
     */
    public static void processSnapshotCommits() {
        try {
            // Query attachments related to the copado__Snapshot__Commit__c records with name "METADATA"
            List<Attachment> attachments = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE Name = 'METADATA' 
                                            AND Parent.Type = 'copado__Snapshot__Commit__c'];

            if (attachments.isEmpty()) {
                System.debug('No METADATA attachments found.');
                return;
            }

            List<Attachment> attachmentsToUpdate = new List<Attachment>();

            // Iterate over attachments and process the content
            for (Attachment attachment : attachments) {
                // Read the content of the attachment
                String content = blobToString(attachment.Body);

                // Identify and remove CustomLabels snippet
                String updatedContent = removeCustomLabelsSnippet(content);

                // If content was modified, prepare the updated attachment
                if (content != updatedContent) {
                    Attachment updatedAttachment = new Attachment(
                        Id = attachment.Id,
                        Body = Blob.valueOf(updatedContent)
                    );
                    attachmentsToUpdate.add(updatedAttachment);
                }
            }

            // Update the attachments if any were modified
            if (!attachmentsToUpdate.isEmpty()) {
                update attachmentsToUpdate;
                System.debug('Attachments updated successfully.');
            } else {
                System.debug('No changes detected in attachments.');
            }
        } catch (Exception e) {
            System.debug('Error processing snapshot commits: ' + e.getMessage());
        }
    }

    /**
     * Helper method to remove the CustomLabels snippet from the content.
     * @param content The original attachment content.
     * @return The content with the CustomLabels snippet removed.
     */
    private static String removeCustomLabelsSnippet(String content) {
        // Define the pattern to match the CustomLabels snippet
        String startPattern = '<CustomLabels>';
        String endPattern = '</CustomLabels>';

        Integer startIndex = content.indexOf(startPattern);
        Integer endIndex = content.indexOf(endPattern) + endPattern.length();

        // If the snippet is found, remove it
        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
            String beforeSnippet = content.substring(0, startIndex);
            String afterSnippet = content.substring(endIndex);
            return beforeSnippet + afterSnippet;
        }
        return content;  // Return original content if no snippet found
    }

    /**
     * Helper method to convert Blob data to String.
     * @param blobData The Blob content from the attachment.
     * @return String representation of the Blob data.
     */
    private static String blobToString(Blob blobData) {
        if (blobData == null) {
            return '';
        }
        return blobData.toString();  // Convert Blob to String
    }
}