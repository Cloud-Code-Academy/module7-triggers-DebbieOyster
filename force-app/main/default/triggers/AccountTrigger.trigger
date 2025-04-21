/* Account trigger should do the following:
* 1. Set the account type to prospect.
* 2. Copy the shipping address to the billing address.
* 3. Set the account rating to hot.
* 4. Create a contact for each account inserted.
*/
trigger AccountTrigger on Account (before insert, after insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        //Set the account type to prospect only if type field is empty. Copy shipping address to billing address. Rating to hot.
        for (Account a : Trigger.new) {
            if (String.isBlank(a.Type)) {
                a.Type = 'Prospect';   
            }
            if (!String.isBlank(a.Phone) && !String.isBlank(a.Website) && !String.isBlank(a.Fax) ) {
                a.Rating = 'Hot';
            }
            
            if (!String.isBlank(a.ShippingStreet)) {
                a.BillingStreet = a.ShippingStreet;
                a.BillingCity = a.ShippingCity;
                a.BillingState = a.ShippingState;
                a.BillingPostalCode = a.ShippingPostalCode;
                a.BillingCountry = a.ShippingCountry;    
            }  
        }
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        //Create a contact for each account inserted
        List<Contact> contactsToInsert = new List<Contact>();
            for (Account a : Trigger.new) {
                Contact c = new Contact(
                    LastName = 'DefaultContact',
                    Email = 'default@email.com',
                    AccountId = a.Id
                );
                contactsToInsert.add(c);
            }
            if (!contactsToInsert.isEmpty()) {
                insert contactsToInsert;            
            }
    }
}