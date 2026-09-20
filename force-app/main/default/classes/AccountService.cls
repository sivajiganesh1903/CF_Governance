public with sharing class AccountService {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String searchKey) {
        String key = '%' + searchKey + '%';
        return [
            SELECT Id, Name, Phone, Industry 
            FROM Account
            WHERE Name LIKE :key
            ORDER BY Name
            LIMIT 10
        ];
    }
}