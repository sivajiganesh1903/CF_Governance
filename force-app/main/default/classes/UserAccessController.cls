public class UserAccessController {
    public List<UAMWrapper> uamList { get; set; }

    public UserAccessController() {
        List<User_Access_Managment__c> queriedList = [
            SELECT Id, Name, Product_Team__c, Persona_New__c, Divsion__c, Need_Admin_Access__c,
                   isApproved__c, Requested_Environment__c, Status__c, Access_Period_Start__c,
                   Access_Period_End__c,
                   (SELECT Id, Name, Email__c, Federation_Id__c, First_Name__c, Last_Name__c,
                    User_Access_Managment__c FROM User_Requests__r)
            FROM User_Access_Managment__c
            WHERE Status__c = 'Requested' AND Need_Admin_Access__c = true
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        uamList = new List<UAMWrapper>();

        for (User_Access_Managment__c uam : queriedList) {
            if (uam.User_Requests__r != null && !uam.User_Requests__r.isEmpty()) {
                String formattedStart = uam.Access_Period_Start__c != null
                    ? convertToCST(uam.Access_Period_Start__c).format('MM/dd/yyyy hh:mm a') + ' CST'
                    : '';
                String formattedEnd = uam.Access_Period_End__c != null
                    ? convertToCST(uam.Access_Period_End__c).format('MM/dd/yyyy hh:mm a') + ' CST'
                    : '';

                uamList.add(new UAMWrapper(uam, formattedStart, formattedEnd));
            }
        }
    }

    private static DateTime convertToCST(DateTime gmtDateTime) {
        return gmtDateTime.addHours(-6);
    }

    public class UAMWrapper {
        public User_Access_Managment__c uam { get; set; }
        public String formattedStart { get; set; }
        public String formattedEnd { get; set; }

        public UAMWrapper(User_Access_Managment__c uam, String startDate, String endDate) {
            this.uam = uam;
            this.formattedStart = startDate;
            this.formattedEnd = endDate;
        }
    }
}