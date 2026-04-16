@isTest
public class PILineItemControllerTest {
    
    @testSetup
    static void setup() {
        // Create test data
        Proforma_Invoice__c pi = new Proforma_Invoice__c(Name = 'Test PI');
        insert pi;
        
        List<Proforma_Invoice_Line_Item__c> piItems = new List<Proforma_Invoice_Line_Item__c>();
        for (Integer i = 0; i < 5; i++) {
            piItems.add(new Proforma_Invoice_Line_Item__c(
                Proforma_Invoice_Name__c = pi.Id,
                //Name = 'Test Item ' + i,
                Quantity__c = 10,
                Sales_Price__c = 100
            ));
        }
        insert piItems;
    }
    
    @isTest
    static void testPILineItemController() {
        // Fetch the test Proforma Invoice record
        Proforma_Invoice__c pi = [SELECT Id FROM Proforma_Invoice__c LIMIT 1];
        
        // Set the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/PILineItemVFPage'));
        ApexPages.currentPage().getParameters().put('id', pi.Id);
        
        // Instantiate the controller
        PILineItemController controller = new PILineItemController();
                
        // Test the Save method
        Test.startTest();
        controller.piList[0].Quantity__c = 20;
        controller.Save();
        Test.stopTest();
        
        // Verify the update
        Proforma_Invoice_Line_Item__c updatedItem = [SELECT Quantity__c FROM Proforma_Invoice_Line_Item__c WHERE Id = :controller.piList[0].Id];
        
        // Test the Cancel method
        PageReference cancelPage = controller.Cancel();
    }
}