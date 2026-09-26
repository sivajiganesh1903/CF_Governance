public class AccountHandler153 {
    public static Account createAccount(String accountName) {
        if(String.isBlank(accountName)) {
            throw new IllegalArgumentException('Account name cannot be blank');
        }
        Account acc = new Account(Name = accountName);
        insert acc;
        system.debug('Created Account with Id: ' + acc.Id);
        return acc;
    }
}