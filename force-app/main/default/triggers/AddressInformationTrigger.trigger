trigger AddressInformationTrigger on Address_Information__c (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        AddressInformationTriggerHandler.updateAddressInformation(Trigger.new);
    }
    
    /*if (Trigger.isAfter) {
        AddressInformationTriggerHandler.handleCopyBillToShipTo(Trigger.new);
    }*/

}