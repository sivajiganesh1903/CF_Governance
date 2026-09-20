public with sharing class SCMTestingClass {

    // Method 1: Create an Account record
    public static String createAccount(String name, String industry) {
        try {
            if (String.isBlank(name)) {
                throw new IllegalArgumentException('Account Name is required');
            }
            Account acc = new Account(Name = name, Industry = industry);
            insert acc;
            return acc.Id;
        } catch (Exception e) {
            System.debug('Error creating account: ' + e.getMessage());
            return null;
        }
    }

    // Method 2: Get Account by Id
    public static Account getAccountById(String accountId) {
        try {
            if (String.isBlank(accountId)) {
                throw new IllegalArgumentException('Account ID is required');
            }
            return [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId LIMIT 1];
        } catch (Exception e) {
            System.debug('Error fetching account: ' + e.getMessage());
            return null;
        }
    }
}