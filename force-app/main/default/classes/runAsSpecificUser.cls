public class runAsSpecificUser {
    public static void executeAsSpecificUser(String username) {
        // Query user by username
        User specificUser = [SELECT Id, Name, Profile.Name FROM User WHERE Username = :username LIMIT 1];
        // Example: Tailor logic based on the user's profile
        if (specificUser.Profile.Name == 'System Administrator') {
            System.debug('Performing admin-specific actions.');
            Account acc = new Account();
            acc.Name = 'test 10/01';
            
            insert acc;
        } else {
            System.debug('Performing actions for non-admin users.');
            // Non-admin logic here
        }
        // You can also use specificUser.Id for data queries
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE OwnerId = :specificUser.Id];
        System.debug('Accounts owned by specific user: ' + accounts);
    }
}