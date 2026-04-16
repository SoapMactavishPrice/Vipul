trigger PricebookTrigger on Pricebook2 (after insert) {
    for (Pricebook2 pb : Trigger.new) {
        if (pb.CurrencyIsoCode == 'EUR') {  
            // Call a future method to handle PricebookEntry updates
         //   PricebookEntryUpdater.updatePriceEntries(pb.Id);
        }
    }
}