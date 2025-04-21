/* Opportunity trigger should do the following:
* 1. Validate that the amount is greater than 5000.
* 2. Prevent the deletion of a closed won opportunity for a banking account.
* 3. Set the primary contact on the opportunity to the contact with the title of CEO.
*/

trigger OpportunityTrigger on Opportunity (
    before insert, before update, 
    after insert, after update, 
    before delete, after delete
) {
    switch on Trigger.operationType {

        // BEFORE INSERT 
        when BEFORE_INSERT {
            
        }

        // BEFORE UPDATE - Validate that the amount is greater than 5000.
        when BEFORE_UPDATE {
            for (Opportunity opp : Trigger.new) {
                if (opp.Amount < 5000) {
                    opp.addError('Opportunity amount must be greater than 5000');
                }
            }
        }

        // AFTER INSERT and AFTER UPDATE — same logic for Primary Contact
        when AFTER_INSERT, AFTER_UPDATE {
            // Get all AccountIds from the Opportunities being processed
            Set<Id> accountIds = new Set<Id>();
            for (Opportunity opp : Trigger.new) {
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
        
            // Query CEO contacts for those Accounts
            Map<Id, Id> accountToCeoContactMap = new Map<Id, Id>();
            for (Contact con : [
                SELECT Id, AccountId 
                FROM Contact 
                WHERE Title = 'CEO' AND AccountId IN :accountIds
            ]) {
                accountToCeoContactMap.put(con.AccountId, con.Id);
            }
        
            // Only update opportunities that do NOT already have the CEO contact set
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Opportunity opp : Trigger.new) {
                Id ceoContactId = accountToCeoContactMap.get(opp.AccountId);
        
                // Update only if CEO contact exists AND is different than the current value
                if (ceoContactId != null && opp.Primary_Contact__c != ceoContactId) {
                    oppsToUpdate.add(new Opportunity(
                        Id = opp.Id,
                        Primary_Contact__c = ceoContactId
                    ));
                }
            }
        
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
        } 

        // BEFORE DELETE
        when BEFORE_DELETE {
            // Collect AccountIds from Opportunities being deleted
            Set<Id> accountIdsToCheck = new Set<Id>();
            for (Opportunity opp : Trigger.old) {
                if (opp.AccountId != null) {
                    accountIdsToCheck.add(opp.AccountId);
                }
            }

            // Query only Banking accounts
            Set<Id> bankingAccountIds = new Set<Id>();
            for (Account acct : [
                SELECT Id 
                FROM Account 
                WHERE Industry = 'Banking' AND Id IN :accountIdsToCheck
            ]) {
                bankingAccountIds.add(acct.Id);
            }

            for (Opportunity opp : Trigger.old) {
                if (opp.StageName == 'Closed Won' &&
                    bankingAccountIds.contains(opp.AccountId)) {
                    opp.addError('Cannot delete closed opportunity for a banking account that is won');
                }
            }
        }
    }
}
