// Apex code - AccountManager.cls
public class AccountManager {
    
    public static void updateAccountName(Account acc, String newName) {
        if(acc != null && newName != null) {
            acc.Name = newName;
            update acc;
        }
    }
}