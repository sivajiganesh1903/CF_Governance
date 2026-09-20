public class UserStatus {
    
    public static void getActiveUsers() {
        Date todayDate = System.today();
        System.debug('Today\'s Date: ' + todayDate);
        
        List<User> activeUsers = [SELECT Id, Name, Email, Username, LastLoginDate FROM User 
                                  WHERE IsActive = true AND LastLoginDate != NULL];
        System.debug('Total active users with LastLoginDate: ' + activeUsers.size());
        
        for (User user : activeUsers) {
            Integer daysSinceLogin = user.LastLoginDate.date().daysBetween(todayDate);
            System.debug('User: ' + user.Name + ', Email: ' + user.Email + ', Days since login: ' + daysSinceLogin);
            
            if (daysSinceLogin == 0) {
                sendLoginReminderEmail(user, 0);
            } else if (daysSinceLogin == 49) {
                sendLoginReminderEmail(user, 49);
            } else if (daysSinceLogin == 1) {
                sendLoginReminderEmail(user, 1);
            }
        }
    }
    
    private static void sendLoginReminderEmail(User user, Integer days) {
        List<String> address = new List<String>{ user.Email,'sivajiganesh97@gmail.com' };
            String htmlBody = '';
        String subject = '';
        
        if (days == 0) {
            subject = 'Your Salesforce Access Is at Risk - Your Salesforce Account will be Inactivated in Next 30 Days';
            htmlBody = 'Hello ' + user.Name + ',<br><br>' +
                'We noticed that you haven\'t logged into Salesforce in the last' + days + 'days.<br>' +
                'Your login user details are:<br>' +
                'Username: ' + user.Username + '<br>' +
                'Email: ' + user.Email + '<br><br>' + 
                'If you’re facing any issues accessing your Salesforce account, feel free to reach out to the support team.<br>' +
                'If you don\'t login in the next 30 days, your account will be inactivated.<br><br>' +
                'Thank you.<br>' +
                'Salesforce Admin Team';
        } 
        else if (days == 10) {
            subject = 'Your Salesforce Access Is Inactivated';
            htmlBody = 'Hello ' + user.Name + ',<br><br>' +
                'We noticed that you haven\'t logged into Salesforce in the last' + days + 'days.<br>' +
                'Your login user details are:<br>' +
                'Username: ' + user.Username + '<br>' +
                'Email: ' + user.Email + '<br><br>' + 
                'We have deactivated your Salesforce account. If you wish to reactivate it, please contact the support team.<br><br>' +
                'Thank you.<br>' +
                'Salesforce Admin Team';
        } 
        else if (days == 20){
            subject = 'Your Salesforce Access Is at Risk - Inactive Salesforce Account for ' + days + ' Days';
            htmlBody = 'Hello ' + user.Name + ',<br><br>' +
                'We noticed that you haven\'t logged into Salesforce in the last ' + days + ' days.<br>' +
                'Your login user details are:<br>' +
                'Username: ' + user.Username + '<br>' +
                'Email: ' + user.Email + '<br><br>' + 
                'If you’re facing any issues accessing your Salesforce account, feel free to reach out to the support team.<br><br>' +
                'Thank you.<br>' +
                'Salesforce Admin Team';
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(subject);
        mail.setHtmlBody(htmlBody);
        mail.setToAddresses(address);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        System.debug('Email sent to: ' + user.Email + ' for ' + days + ' days inactivity.');
    }
}