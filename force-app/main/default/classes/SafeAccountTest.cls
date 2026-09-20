@isTest
public class SafeAccountTest {
    @testSetup
    static void setupTestData() {
        // Create an Account to use in tests
        Account acc = new Account(Name = 'Test Account', Phone='123456789');
        insert acc;
    }
    @isTest
    static void testUpdateAccountIndustry() {
        // Get the created Account from the setup method
        Account acc = [SELECT Id, Name, Description FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Call the method to update the Industry
        SafeAccount.updateAccountIndustry(acc.Id, 'Technology');
        
        // Query the account again to check the updated field
        Account updatedAcc = [SELECT Id, Name, Industry FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Technology', updatedAcc.Industry, 'Industry should be updated to Technology');
    }
    
    @isTest
    static void testCreateAccount() {
        // Call the createAccount method
        Account newAcc = SafeAccount.createAccount('New Account');
        
        // Check if the account was created
        System.assertNotEquals(null, newAcc.Id, 'The new account should have an Id');
        
        // Query and check if the account name is correct
        Account queriedAcc = [SELECT Id, Name FROM Account WHERE Id = :newAcc.Id];
        System.assertEquals('New Account', queriedAcc.Name, 'The new account should have the correct name');
    }
}