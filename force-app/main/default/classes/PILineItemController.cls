public class PILineItemController {
    
    public String currentRecID { get; set; }
    public List<Proforma_Invoice_Line_Item__c> piList { get; set; }
    public Proforma_Invoice__c pi { get; set; }
    
    public PILineItemController() {
        currentRecID = ApexPages.currentPage().getParameters().get('id');
        
        if (currentRecID != null) {
            fetchPI();
            fetchPIItems();
        }
    }
    
    private void fetchPI() {
        pi = [SELECT Id, OwnerId, Name FROM Proforma_Invoice__c WHERE Id = :currentRecID LIMIT 1];
    }
    
    public void fetchPIItems() {
        piList = [SELECT Id, Name, CurrencyIsoCode, Product__c, Proforma_Invoice_Name__c, Quantity__c, Discount_Percentage__c, 
                  Line_Item_Description__c, List_Price__c, Sales_Price__c, Subtotal__c, Total_Price__c, Product__r.Name,
                  Product__r.ProductCode, Product__r.Description, Product__r.Packing_Type__c, Product__r.Unit__c, Packing_Type__c,
                  Product__r.Packing__c, Quality__c, Packing__c, Box_Drum__c, Pallet_Quantity__c, Pallet_No__c, Others_Packing_Type__c
                  FROM Proforma_Invoice_Line_Item__c WHERE Proforma_Invoice_Name__c = :currentRecID];
    }
    
    // Save Method
    public PageReference Save() {
        // Perform necessary actions before redirecting
        // Example: Update records if needed
        update piList;
        
        PageReference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;
    }
    
    public PageReference Cancel() {
        PageReference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;        
    }  
}