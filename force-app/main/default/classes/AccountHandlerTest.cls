@isTest
public class AccountHandlerTest {
    @isTest
    public static void testUpdateAccountPhoneNumbers() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Retrieve the ID of the test account
        Id accountId = testAccount.Id;
        
        // Instantiate the AccountHandler class
        AccountHandler accountHandler = new AccountHandler();
        
        // Call the method to update the phone number
        accountHandler.updateAccountPhoneNumbers(new List<Id>{accountId}, '123-456-7890');
        
        // Verify the phone number was updated
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :accountId];
        System.assertEquals('123-456-7890', updatedAccount.Phone);
    }
}