/**
* @description Hello World
*/
public with sharing class ContactController {   
    /**
* @description Hello World
* Retrieves contacts by last name.
* @param lastName The last name to search for.
* @return List of contacts with the provided last name.
*/
    public static List<Contact> getContactsByLastName(String lastName) {
        // Check CRUD permissions before performing SOQL query
        if (Schema.sObjectType.Contact.isAccessible()) {
            return [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE LastName = :lastName];
        }
        return new List<Contact>();
    }

    /**
* @description Hello World
* Updates the provided contact record.
* @param contactToUpdate The contact record to update.
*/
    public static void updateContact(Contact contactToUpdate) {
        try {
            // Check CRUD permissions before updating the contact
            if (contactToUpdate != null && 
                (contactToUpdate.Id == null || 
                 Schema.sObjectType.Contact.isUpdateable())) {
                     update contactToUpdate;
                 }
        } catch(Exception e) {
            // Handle exception appropriately
            if (Schema.sObjectType.Contact.isAccessible()) {
                List<Contact> contactsToInsert = new List<Contact>();

                // Create and add the first contact
                Contact con1 = new Contact();
                con1.FirstName = 'New1';
                con1.LastName = 'Contact1';
                contactsToInsert.add(con1);
            }
        }
    }
}