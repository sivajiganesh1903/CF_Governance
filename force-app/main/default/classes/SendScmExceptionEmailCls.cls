public with sharing class SendScmExceptionEmailCls {
    @InvocableMethod(label='Send Exception Email')
    public static void sendExceptionEmail(List<SCMatrixExceptionRequest> requests) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        
        for (SCMatrixExceptionRequest request : requests) {
            String requestedUserStoryUrl = baseUrl + '/lightning/r/copado__User_Story__c/' + request.requestedUserStoryId + '/view';
            
            String subject = 'Exception Request for ' + escapeHtml(request.requestedUserStoryName);
            String greetingName = escapeHtml(request.reviewerLastName);

            if (String.isNotBlank(request.reviewerFirstName)) {
                greetingName += ' ' + escapeHtml(request.reviewerFirstName);
            }
            String body = '<html><body>' +
                '<p>Hi ' + greetingName + ',</p>' +                
                '<p>An Exception Request has been created for the user story <b>' + escapeHtml(request.requestedUserStoryName) + '</b> due to shared components.</p>' +
                '<br><b>Exception Request Details :</b><br> ' +
                '<p>Exception ID : ' + escapeHtml(request.exceptionRequestName) + '</p>' +
                '<p>User Story : ' +
                '<a href="' + requestedUserStoryUrl + '" target="_blank">' + requestedUserStoryUrl + '</a></p>' +
                '<p>Requested Environment : ' + escapeHtml(request.requestedEnvironmentName) + '</p>' +
                '<p>Status : ' + escapeHtml(request.exceptionStatus) + '</p><br>' +

                '<p><b>Review and Take Action : </b>' +
                '<a href="' + baseUrl + '/lightning/n/SCM_Home" target="_blank">' + baseUrl + '/lightning/n/SCM_Home</a></p>' +
                '<p>Please do validate the components carefully before approving or rejecting this request.</p>' +
                '<br><p>Thanks & Regards,<br><b>SCM Automation</b></p>' +
                '</body></html>';
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{request.reviewerEmail});
            email.setSubject(subject);
            email.setHtmlBody(body);
            
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    public static String escapeHtml(String input) {
        if (input == null) {
            return null;
        }
        return input.replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#x27;');
    }
    
    public class SCMatrixExceptionRequest {
        @InvocableVariable(required=true)
        public String reviewerEmail;
        
        @InvocableVariable(required=true)
        public String reviewerLastName;
        
        @InvocableVariable(required=false)
        public String reviewerFirstName;
        
        @InvocableVariable(required=true)
        public String requestedUserStoryName;
        
        @InvocableVariable(required=true)
        public String requestedUserStoryId;
        
        @InvocableVariable(required=true)
        public String exceptionRequestName;

        @InvocableVariable(required=true)
        public String exceptionStatus;

        @InvocableVariable(required=true)
        public String requestedEnvironmentName;
    }
}