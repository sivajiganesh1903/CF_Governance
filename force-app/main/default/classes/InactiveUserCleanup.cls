public class InactiveUserCleanup {
    private static final Integer DAYS_THRESHOLD = 2;
    private static final String RELEASE_TEAM_EMAILS = System.Label.Copado_Release_Team_Emails;
    @InvocableMethod(label='Inactive Users')
    public static void inactiveUserData() {
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        List<copado.GlobalAPI.UserLicense> allLicenses = copadoGlobalAPI.listCopadoLicenses();
        Set<Id> userIds = new Set<Id>();
        for (copado.GlobalAPI.UserLicense license : allLicenses) {
            userIds.add(license.userId);
        }
        // Enhanced user query to include LastLoginDate
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, IsActive, LastLoginDate, Email, Profile.Name 
            FROM User 
            WHERE Id IN :userIds
        ]);
        List<Id> inactiveUserIds = new List<Id>();
        List<UserLicenseNotification> usersToNotify = new List<UserLicenseNotification>();
        Date thresholdDate = Date.today().addDays(-DAYS_THRESHOLD);
        for (copado.GlobalAPI.UserLicense license : allLicenses) {
            User user = userMap.get(license.userId);
            if (user != null) {
                if (!user.IsActive) {
                    inactiveUserIds.add(user.Id);
                } else if (user.LastLoginDate == null || user.LastLoginDate.date() <= thresholdDate) {
                    usersToNotify.add(new UserLicenseNotification(user, license));
                }
            }
        }
        // Process inactive users
        if (!inactiveUserIds.isEmpty()) {
            processInactiveUsers(inactiveUserIds, copadoGlobalAPI);
        }
        // Send notifications for inactive licenses
        if (!usersToNotify.isEmpty()) {
            sendInactivityNotifications(usersToNotify);
        }
    }
    private static void processInactiveUsers(List<Id> inactiveUserIds, copado.GlobalAPI copadoGlobalAPI) {
        List<Id> successfulDeletions = new List<Id>();
        List<Id> failedDeletions = new List<Id>();
        for (Id userId : inactiveUserIds) {
            Boolean deleteResult = copadoGlobalAPI.deleteCopadoLicense(userId);
            if (deleteResult) {
                successfulDeletions.add(userId);
            } else {
                failedDeletions.add(userId);
            }
        }
        System.debug('Successfully deleted Copado feature licenses for ' + successfulDeletions.size() + ' users.');
        System.debug('Failed to delete Copado feature licenses for ' + failedDeletions.size() + ' users.');
        deleteUserPackageLicenses(inactiveUserIds);
    }
    private static void sendInactivityNotifications(List<UserLicenseNotification> usersToNotify) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        // Split release team emails string into list
        List<String> releaseTeamEmails = RELEASE_TEAM_EMAILS.split(',');
        for (UserLicenseNotification notification : usersToNotify) {
            // Email to inactive user
            Messaging.SingleEmailMessage userMail = new Messaging.SingleEmailMessage();
            userMail.setToAddresses(new String[]{notification.userEmail});
            userMail.setCcAddresses(releaseTeamEmails); // CC the release team
            userMail.setSubject('Copado License Inactivity Notice');
            String emailBody = 'Dear ' + notification.userName + ',\n\n';
            emailBody += 'This is a notification that your Copado license has been inactive for ' + DAYS_THRESHOLD + ' days. ';
            emailBody += 'If you do not log in within the next 7 days, your license may be released for reallocation.\n\n';
            emailBody += 'License Details:\n';
            emailBody += '- License Type: ' + notification.licenseType + '\n';
            emailBody += '- Last Login: ' + (notification.lastLoginDate != null ? notification.lastLoginDate.format() : 'Never logged in') + '\n\n';
            emailBody += 'Please log in to retain your license or contact your administrator if you no longer need this license.\n\n';
            emailBody += 'Best regards,\nYour Copado Admin Team';
            userMail.setPlainTextBody(emailBody);
            emailMessages.add(userMail);
            // Separate notification to release team with additional details
            Messaging.SingleEmailMessage teamMail = new Messaging.SingleEmailMessage();
            teamMail.setToAddresses(releaseTeamEmails);
            teamMail.setSubject('Copado License Inactivity Alert - ' + notification.userName);
            String teamEmailBody = 'Release Team,\n\n';
            teamEmailBody += 'This is a notification about inactive Copado license usage:\n\n';
            teamEmailBody += 'User Details:\n';
            teamEmailBody += '- Name: ' + notification.userName + '\n';
            teamEmailBody += '- Email: ' + notification.userEmail + '\n';
            teamEmailBody += '- License Type: ' + notification.licenseType + '\n';
            teamEmailBody += '- Last Login: ' + (notification.lastLoginDate != null ? notification.lastLoginDate.format() : 'Never logged in') + '\n';
            teamEmailBody += '- Days Inactive: ' + DAYS_THRESHOLD + '\n\n';
            teamEmailBody += 'Action Required: Monitor user activity and consider license reallocation if inactivity continues.\n\n';
            teamEmailBody += 'Best regards,\nCopado License Management System';
            teamMail.setPlainTextBody(teamEmailBody);
            emailMessages.add(teamMail);
        }
        if (!emailMessages.isEmpty()) {
            try {
                Messaging.sendEmail(emailMessages);
                System.debug('Sent inactivity notifications to ' + (emailMessages.size()/2) + ' users and release team.');
            } catch (Exception e) {
                System.debug('Error sending email notifications: ' + e.getMessage());
            }
        }
    }
    @future
    public static void deleteUserPackageLicenses(List<Id> inactiveUserIds) {
        try {
            PackageLicense copadoPackage = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'copado' LIMIT 1];
            List<UserPackageLicense> userPackageLicensesToDelete = [
                SELECT Id, UserId, User.Name 
                FROM UserPackageLicense 
                WHERE PackageLicenseId = :copadoPackage.Id 
                AND UserId IN :inactiveUserIds
            ];
            if (!userPackageLicensesToDelete.isEmpty()) {
                delete userPackageLicensesToDelete;
                System.debug('Deleted ' + userPackageLicensesToDelete.size() + ' Copado Managed Package licenses.');
            } else {
                System.debug('No Copado Managed Package licenses found for the specified users.');
            }
        } catch (Exception e) {
            System.debug('Error in deleting UserPackageLicenses: ' + e.getMessage());
        }
    }
    // Helper class to store user notification information
    private class UserLicenseNotification {
        public String userName;
        public String userEmail;
        public String licenseType;
        public DateTime lastLoginDate;
        public UserLicenseNotification(User user, copado.GlobalAPI.UserLicense license) {
            this.userName = user.Name;
            this.userEmail = user.Email;
            this.licenseType = license.toString(); // Adjust based on actual license information available
            this.lastLoginDate = user.LastLoginDate;
        }
    }
}