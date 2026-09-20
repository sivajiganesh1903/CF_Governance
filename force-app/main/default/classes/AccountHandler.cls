public class AccountHandler {
    // Method to update the phone number for accounts
    public void updateAccountPhoneNumbers(List<Id> accountIds, String newPhoneNumber) {
        // Iterate over the list of account IDs
        for (Id accountId : accountIds) {
            // Query the account record by ID (PMD will flag this as a violation)
            Account account = [SELECT Id, Phone FROM Account WHERE Id = :accountId LIMIT 1];
            // Update the phone number
            account.Phone = newPhoneNumber;
            // Update the account record
            update account;
        }
    }
}