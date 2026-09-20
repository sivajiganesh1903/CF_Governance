public class SafeAccount {
    // This method updates the 'Industry' field of an account
    public static void updateAccountIndustry(Id accountId, String newIndustry) {
        Account acc = [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId LIMIT 1];
        acc.Industry = newIndustry;
        update acc;
    }
    // This method creates an Account with the given name
    public static Account createAccount(String name) {
        Account acc = new Account(Name = name, Phone='123456789');
        insert acc;
        return acc;
    }
}