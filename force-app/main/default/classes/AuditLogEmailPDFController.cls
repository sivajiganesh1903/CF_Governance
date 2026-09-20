public class AuditLogEmailPDFController {
	public void sendEmailWithPDF(Id recordId) {
        // Generate the PDF content
        PageReference pageRef = Page.AuditLogReport;
        pageRef.getParameters().put('id', recordId);
        Blob pdfBlob;
        
        try {
            pdfBlob = pageRef.getContentAsPDF();
        } catch (VisualforceException e) {
            // Handle any exceptions here
            pdfBlob = Blob.valueOf('Error generating PDF: ' + e.getMessage());
        }

        // Create an EmailMessage with the PDF as an attachment
        Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
        pdfAttachment.setFileName('Audit_Log_Report.pdf');
        pdfAttachment.setBody(pdfBlob);

        // Create an Email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Audit Log Report');
        email.setToAddresses(new String[]{'dipali.m@cloudfulcrum.com'}); // Replace with the recipient's email
        email.setPlainTextBody('Please find the attached Audit Log Report PDF.');

        // Attach the PDF to the email
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{pdfAttachment});

        // Send the email
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
		system.debug('Email Sent/NotSent');
        // Check for email send results and handle any errors
        if (results[0].isSuccess()) {
            System.debug('Email sent successfully');
        } else {
            System.debug('Email send failed: ' + results[0].getErrors()[0].getMessage());
        }
    }
}