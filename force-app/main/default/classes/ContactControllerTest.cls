@isTest
public class ContactControllerTest {

    // Test method to verify retrieval of contacts by last name
    @isTest
    static void testGetContactsByLastName() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Insert test data
            Contact testContact = new Contact(LastName = 'Doe', FirstName = 'John', Email = 'john.doe@test.com', Phone = '1234567890');
            insert testContact;

            // Call the method to retrieve contacts by last name
            List<Contact> contacts = ContactController.getContactsByLastName('Doe');

            // Verify that the contact is retrieved
            System.assertEquals(1, contacts.size(), 'Expected one contact to be retrieved');
            System.assertEquals('Doe', contacts[0].LastName, 'Unexpected last name');
        }
    }

    // Test method to verify updating contact information
    @isTest
    static void testUpdateContact() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create test data
            Contact testContact = new Contact(LastName = 'Smith', FirstName = 'Jane', Email = 'jane.smith@test.com', Phone = '9876543210');
            insert testContact;

            // Modify the contact information
            testContact.Email = 'updated.email@test.com';
            testContact.Phone = '5555555555';

            // Call the method to update contact information
            ContactController.updateContact(testContact);

            // Retrieve the updated contact
            Contact updatedContact = [SELECT Id, Email, Phone FROM Contact WHERE Id = :testContact.Id];

            // Verify that the contact information is updated
            System.assertEquals('updated.email@test.com', updatedContact.Email, 'Unexpected email');
            System.assertEquals('5555555555', updatedContact.Phone, 'Unexpected phone number');
        }
    }
    // Test method to verify exception handling in updateContact method
    @isTest
    static void testUpdateContactException() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create a contact without an ID to simulate an exception
            Contact testContact = new Contact(LastName = 'Exception', FirstName = 'Test', Email = 'exception@test.com', Phone = '1234567890');

            Test.startTest();
            // Call the method to update contact information, which should trigger an exception
            ContactController.updateContact(testContact);
            Test.stopTest();

            // Verify that a new contact is created due to the exception
            Contact[] newContacts = [SELECT Id, FirstName, LastName FROM Contact WHERE LastName = 'Contact1'];
            System.assertEquals(1, newContacts.size(), 'Expected one contact to be created due to exception');
        }
    }
}