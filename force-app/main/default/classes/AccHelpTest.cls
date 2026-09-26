@IsTest
public class AccHelpTest {
    // Gate: 1
    @IsTest
    static void testUpdateAccountIndustry() {
        // testing user story Method
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, Industry = 'Technology'));
        }
        insert testAccounts;        
        // Retrieve the test account IDs List<Id> accountIds = new List<Id>();
        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        System.debug(testAccounts);
        System.debug(' accountIds: ' + accountIds);
        //Test the method: 2
        Test.startTest();
        AccHelp.updateAccountIndustry(accountIds, 'Finance');
        Test.stopTest();
        
        // Query the accounts and verify to updates
        List<Account> updatedAccounts = [SELECT Industry FROM Account WHERE Id IN :accountIds];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Finance', acc.Industry, 'The account industry was not updated correctly.');
        }
    }
    
    // Gate: 2
    @IsTest
    static void testEmptyAccountList() {
        try {
            Test.startTest();
            AccHelp.updateAccountIndustry(new List<Id>(), 'Finance');
            Test.stopTest();
            System.assert(false, 'Expected an exception for empty account list, but none was thrown.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Account Id list cannot be empty', e.getMessage());
        }
    }   
}