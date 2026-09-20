public class InactiveUserCleanups {
    
    @InvocableMethod(label='Inactive Users')
    public static void inAcitveUserData() {
        // Using Copado Global API to fetch Copado license information:
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        List<copado.GlobalAPI.UserLicense> allLicenses = copadoGlobalAPI.listCopadoLicenses();
        
        // Collect all User IDs
        Set<Id> userIds = new Set<Id>();
        for (copado.GlobalAPI.UserLicense license : allLicenses) {
            userIds.add(license.userId);
        }
        
        // Query User information related to Copado license UserIds
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, IsActive FROM User WHERE Id IN :userIds]);
        
        // Filter for inactive users
        List<Id> inactiveUserIds = new List<Id>();
        for (copado.GlobalAPI.UserLicense license : allLicenses) {
            if (userMap.containsKey(license.userId) && !userMap.get(license.userId).IsActive) {
                inactiveUserIds.add(license.userId);
            }
        }
        
        // Delete Copado feature licenses for inactive users
        if (!inactiveUserIds.isEmpty()) {
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
            
            // Call the future method to delete Copado Managed Package licenses
            deleteUserPackageLicenses(inactiveUserIds);
        }
    }
    
    @future
    public static void deleteUserPackageLicenses(List<Id> inactiveUserIds) {
        try {
            PackageLicense copadoPackage = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'copado' LIMIT 1];
            List<UserPackageLicense> userPackageLicensesToDelete = [SELECT Id, UserId, User.Name 
                                                                    FROM UserPackageLicense 
                                                                    WHERE PackageLicenseId = :copadoPackage.Id 
                                                                    AND UserId IN :inactiveUserIds];
            
            System.debug('User Package Licenses to be deleted: ' + userPackageLicensesToDelete);
            
            // Delete the UserPackageLicense records
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
}