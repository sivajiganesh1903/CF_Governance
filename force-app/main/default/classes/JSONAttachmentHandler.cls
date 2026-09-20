public with sharing class JSONAttachmentHandler {
    @InvocableMethod(label='Attach JSON to Record' description='Attach a JSON string as a file to a record.')
    public static void attachJsonToRecords(List<Request> requestList) {
        List<Attachment> attachments = new List<Attachment>();

        for (Request req : requestList) {
            // Convert JSON string to Blob
            Blob jsonBlob = Blob.valueOf(req.jsonString);
            
            // Create Attachment object
            Attachment attachment = new Attachment();
            attachment.ParentId = req.recordId; // ID of the record to which the attachment is linked
            attachment.Name = req.fileName; // Name of the attachment file
            attachment.Body = jsonBlob; // The JSON content
            attachment.ContentType = 'application/json'; // Set the content type to JSON
            
            attachments.add(attachment);
        }
        
        // Insert all attachments
        if (!attachments.isEmpty()) {
            insert attachments;
        }
    }

    // Wrapper class to handle inputs from Flow
    public class Request {
        @InvocableVariable(required=true)
        public String jsonString;
        
        @InvocableVariable(required=true)
        public Id recordId;
        
        @InvocableVariable(required=true)
        public String fileName;
    }
}