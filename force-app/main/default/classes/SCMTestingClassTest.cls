@isTest
public class SCMTestingClassTest {

    // Test method for successful account creation
    @isTest
    static void testCreateAccountSuccess() {
        String accountId = SCMTestingClass.createAccount('Test Account', 'Technology');
        System.assertNotEquals(null, accountId, 'Account ID should not be null');
        
        Account acc = [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId];
        System.assertEquals('Test Account', acc.Name);
        System.assertEquals('Technology', acc.Industry);
    }

    // Test method to cover the catch block in createAccount()
    @isTest
    static void testCreateAccountFailure() {
        // Pass a blank name to trigger the exception
        String accountId = SCMTestingClass.createAccount('', 'Technology');
        System.assertEquals(null, accountId, 'Account creation should return null on failure');
    }

    // Test method for successful account retrieval
    @isTest
    static void testGetAccountByIdSuccess() {
        Account testAccount = new Account(Name = 'Sample Account', Industry = 'Finance');
        insert testAccount;

        Account fetchedAccount = SCMTestingClass.getAccountById(testAccount.Id);
        System.assertNotEquals(null, fetchedAccount, 'Fetched Account should not be null');
        System.assertEquals('Sample Account', fetchedAccount.Name);
        System.assertEquals('Finance', fetchedAccount.Industry);
    }

    // Test method to cover the catch block in getAccountById()
    @isTest
    static void testGetAccountByIdFailure() {
        // Pass a blank ID to trigger the exception
        Account fetchedAccount = SCMTestingClass.getAccountById('');
        System.assertEquals(null, fetchedAccount, 'Fetching account should return null on failure');
    }
}