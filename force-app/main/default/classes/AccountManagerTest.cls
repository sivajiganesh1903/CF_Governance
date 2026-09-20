// Test class - AccountManagerTest.cls
@isTest
public class AccountManagerTest {
    
    @isTest
    static void testUpdateAccountName() {
        // Create a test account
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        // Call the method to update account name
        AccountManager.updateAccountName(testAccount, 'New Test Account Name');
        
        // Retrieve the updated account from the database
        Account updatedAccount = [SELECT Name FROM Account WHERE Id = :testAccount.Id];
        
        // Verify that the name has been updated correctly
        System.assertEquals('New Test Account Name', updatedAccount.Name);
    }
}