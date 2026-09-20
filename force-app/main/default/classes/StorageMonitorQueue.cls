public class StorageMonitorQueue implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();

            String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v59.0/limits';
            System.debug('Endpoint URL: ' + endpoint);

            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            HttpResponse res = http.send(req);
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> dataStorage = (Map<String, Object>) result.get('DataStorageMB');

                Integer maxMB = (Integer) dataStorage.get('Max');
                Integer remainingMB = (Integer) dataStorage.get('Remaining');

                Integer usedMB = maxMB - remainingMB;
                Decimal percentUsed = (usedMB * 100.0) / maxMB;
                System.debug('Storage Used %: ' + percentUsed);

                if (percentUsed >= 40) {
                    sendEmailAlert(percentUsed, usedMB, maxMB);
                }

            } else {
                System.debug('Failed to fetch limits: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }

        System.debug('=== Queueable Job Finished ===');
    }

    private static void sendEmailAlert(Decimal percent, Integer used, Integer max) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'sivajiganeshgurram@gmail.com'});
        mail.setSubject('Salesforce Data Storage Alert');
        mail.setPlainTextBody(
            'Warning!\n\n' +
            'Used: ' + used + ' MB\n' +
            'Total: ' + max + ' MB\n' +
            'Usage: ' + percent.setScale(2) + '%'
        );
        System.debug('Emails: ' + mail);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        System.debug('Email sent.');
    }
}