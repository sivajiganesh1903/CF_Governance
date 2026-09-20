public class ActiveUserCleanup {
    @InvocableMethod(label='Active User')
    public static void deleteUserLicenses(List<Id> userIds) {
        // Using Copado Global API
        copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
        System.debug(userIds);

        // Get user information
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, username, Name, IsActive FROM User WHERE Id IN :userIds]);
        System.Debug('Users Information +++++' + userMap);

        // Delete Copado feature licenses
        List<Id> successfulDeletions = new List<Id>();
        List<Id> failedDeletions = new List<Id>();
        for (Id userId : userIds) {
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
        deleteUserPackageLicensesAsync(userIds);

        // Get updated license information
        copado.GlobalAPI.CopadoLicenses licenseInfo = copadoGlobalAPI.getLicenseInformation();
        System.debug('Updated license information:');
        System.debug('Available Copado Branch Management licenses: ' + licenseInfo.availableCBMLicenses);
        System.debug('Available Copado Admin licenses: ' + licenseInfo.availableCopadoLicenses);
        System.debug('Available Copado User licenses: ' + licenseInfo.availableCCMLicenses);
        System.debug('Available Copado Plan licenses: ' + licenseInfo.availableCADLicenses);
        System.debug('Available Copado Compliance licenses: ' + licenseInfo.availableCCHLicenses);

        // Log details of processed users
        for (Id userId : userIds) {
            User user = userMap.get(userId);
            System.debug('Processed user: ' + user.Name + ' (Id: ' + user.Id + ', IsActive: ' + user.IsActive + ')');
        }
    }

    // Helper method to handle single-user case
    public static void deleteSingleUser(Id userId) {
        List<Id> userIdList = new List<Id>{userId};
        deleteUserLicenses(userIdList);
    }

    // Future method to delete UserPackageLicenses in a separate transaction
    @future
    public static void deleteUserPackageLicensesAsync(List<Id> userIds) {
        PackageLicense copadoPackage = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'copado' LIMIT 1];
        List<UserPackageLicense> userPackageLicensesToDelete = [SELECT Id, UserId, User.Name, PackageLicenseId, 
                                                                PackageLicense.NamespacePrefix FROM UserPackageLicense 
                                                                WHERE PackageLicenseId = :copadoPackage.Id AND 
                                                                UserId IN :userIds];
        System.debug('Copado Deployer Package: +++ ' + copadoPackage);
		System.debug('User Package Licenses +++ ' + userPackageLicensesToDelete);

        if (!userPackageLicensesToDelete.isEmpty()) {
            delete userPackageLicensesToDelete;
            System.debug('Deleted ' + userPackageLicensesToDelete.size() + ' Copado Managed Package licenses.');
        } else {
            System.debug('No Copado Managed Package licenses found for the specified users.');
        }
    }
}