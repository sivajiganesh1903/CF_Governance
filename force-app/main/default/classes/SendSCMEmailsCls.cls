public with sharing class SendSCMEmailsCls {
     @InvocableMethod
    public static void sendEmail(List<SCMatrixApprovalRequest> requests) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Get the base URL dynamically
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();

        for (SCMatrixApprovalRequest request : requests) {
            // Construct dynamic record URLs
            String requestedUserStoryUrl = baseUrl + '/lightning/r/copado__User_Story__c/' + request.requestedUserStoryId + '/view';
            String linkedUserStoryUrl = baseUrl + '/lightning/r/copado__User_Story__c/' + request.linkedUserStoryId + '/view';

            // Construct email subject
            String subject = 'Approval Request for ' + request.requestedUserStoryName +
                             ' related to ' + request.linkedUserStoryName;
			String fullName = '';
            if (String.isNotBlank(request.linkedUserStoryDeveloperLastName)) {
                fullName = escapeHtml(request.linkedUserStoryDeveloperLastName);
            }
            
            if (String.isNotBlank(request.linkedUserStoryDeveloperFirstName)) {
                fullName += (fullName == '' ? '' : ' ') + escapeHtml(request.linkedUserStoryDeveloperFirstName);
            }
            // Construct email body in HTML format with hyperlinks for the user stories
            String body = '<html><body>' +
                          '<p>Hi ' + fullName + ',</p>' +
                          '<p>Approval Request is created for user story <b>' + escapeHtml(request.requestedUserStoryName) + '</b> ' +
                          'to promote to <b>' + escapeHtml(request.linkedUserStoryEnvironmentName) + '</b>, as there are some shared components related to your user story ' +
                          '<b>' + escapeHtml(request.linkedUserStoryName) + '</b>.</p>' +
                        //   '<br><b>Approval Process Details:</b><br><br>' +
                        //   '<p>Approval ID: ' + escapeHtml(request.scmApprovalName) + '<br><br>' +
                        //   'Requested User Story: <a href="' + requestedUserStoryUrl + '" target="_blank">' + requestedUserStoryUrl + '</a><br><br>' +
                        //   'Related User Story: <a href="' + linkedUserStoryUrl + '" target="_blank">' + linkedUserStoryUrl + '</a><br><br>' +
                        //   'Requested Environment: ' + escapeHtml(request.requestedEnvironmentName) + '<br><br>' +
                        //   'Status: '+ escapeHtml(request.exceptionStatus) +'</p><br>' +

                          '<br><b>Approval Process Details :</b><br>' +
                          '<p>Approval ID : ' + escapeHtml(request.scmApprovalName) + '</p>' +
                          '<p>Requested User Story : ' +
                          '<a href="' + requestedUserStoryUrl + '" target="_blank">' + requestedUserStoryUrl + '</a></p>' +
                          '<p>Related User Story : ' +
                          '<a href="' + linkedUserStoryUrl + '" target="_blank">' + linkedUserStoryUrl + '</a></p>' +
                          '<p>Requested Environment : ' + escapeHtml(request.requestedEnvironmentName) + '</p>' +
                          '<p>Status : '+ escapeHtml(request.exceptionStatus) +'</p>' +
                          '<br><p><b>Review and Take Action : </b>' +
                          '<a href="' + baseUrl + '/lightning/n/SCM_Home" target="_blank">' + baseUrl + '/lightning/n/SCM_Home</a></p>' +
                          '<p>Please do validate the components carefully before approving or rejecting this request.</p>' +
                          '<br><p>Thanks & Regards,<br><b>SCM Automation</b></p>' +
                          '</body></html>';

            // Create a single email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{request.linkedUserStoryDeveloperEmail});
            email.setSubject(subject);
            email.setHtmlBody(body); // Use setHtmlBody for HTML content

            // Add the email to the list
            emails.add(email);
        }

        // Send the emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    // Utility method to escape HTML characters
    public static String escapeHtml(String input) {
        if (input == null) {
            return null; // Return null if input is null
        }
        return input.replace('&', '&amp;') // Escape ampersand
                    .replace('<', '&lt;') // Escape less than
                    .replace('>', '&gt;') // Escape greater than
                    .replace('"', '&quot;') // Escape double quotes
                    .replace('\'', '&#x27;'); // Escape single quotes
    }

    // Class to receive input variables
    public class SCMatrixApprovalRequest {
        @InvocableVariable(required=true)
        public String linkedUserStoryDeveloperEmail;

        @InvocableVariable(required=true)
        public String linkedUserStoryDeveloperLastName;

        @InvocableVariable(required=false)
        public String linkedUserStoryDeveloperFirstName;

        @InvocableVariable(required=true)
        public String requestedUserStoryName;

        @InvocableVariable(required=true)
        public String requestedUserStoryId; // Add this to pass record ID

        @InvocableVariable(required=true)
        public String linkedUserStoryName;

        @InvocableVariable(required=true)
        public String linkedUserStoryId; // Add this to pass record ID

        @InvocableVariable(required=true)
        public String linkedUserStoryEnvironmentName;

        @InvocableVariable(required=true)
        public String scmApprovalName;

        @InvocableVariable(required=true)
        public String exceptionStatus;

        @InvocableVariable(required=true)
        public String requestedEnvironmentName;
    }
}