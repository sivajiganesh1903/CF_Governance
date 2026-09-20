public class TestApexClass_QA {
	public static void processContacts() {
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        for (Contact c : contacts) {
            List<Case> cases = [SELECT Id FROM Case WHERE ContactId = :c.Id]; // Bad Practice
        }
    }
}