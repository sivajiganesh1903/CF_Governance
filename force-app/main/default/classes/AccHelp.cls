public class AccHelp {
    // Level: 1 To update the industry of a list of Account Records
    public static void updateAccountIndustry(List<Id> accountIds, String newIndustry) {
        if(accountIds == null || accountIds.isEmpty()) {
            System.debug('Account Id list is empty or null');
            throw new IllegalArgumentException('Account Id list cannot be empty');
        }        
        // Query the Accounts to be updated XXXXXXXX
        List<Account> accountsToUpdate = [SELECT Id, Name, Industry FROM Account WHERE Id IN :accountIds];
        
        // Update the industry for each account
        for(Account acc : accountsToUpdate) {
            System.debug('Updating industry for account: ' + acc.Name + ' to ' + newIndustry);
            acc.Industry = newIndustry;
        }
        System.debug(accountsToUpdate);
        if(!accountsToUpdate.isEmpty()) {
            System.debug('Updating industry for accounts: ' + accountsToUpdate);
            update accountsToUpdate;
        }
    }    
}