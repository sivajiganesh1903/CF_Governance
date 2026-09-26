@isTest
public class AccountHandler153Test {
    @isTest
    static void testCreateAccount() {
        // Test setup
        String accountName = 'Test Account';
        // Call the method to be tested
        Test.startTest();
        Account result = AccountHandler153.createAccount(accountName);
        Test.stopTest();
        // Verify the results
        system.debug('Created Account Id: ' + result.Id);
        Account insertedAccount = [SELECT Id, Name FROM Account WHERE Id = :result.Id];
        System.assertNotEquals(null, insertedAccount, 'Account should have been inserted');
        System.assertEquals(accountName, insertedAccount.Name, 'Account name should match the input name');
    }
 
    @isTest
    static void testCreateAccountWithBlankName() {
        // Test setup
        String accountName = '';
        // Call the method to be tested and expect an exception
        Test.startTest();
        try {
            AccountHandler153.createAccount(accountName);
            System.assert(false, 'Exception should have been thrown for blank account name');
        } catch (Exception e) {
            System.assert(e instanceof IllegalArgumentException, 'IllegalArgumentException should be thrown');
            System.assertEquals('Account name cannot be blank', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }
}