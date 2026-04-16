@isTest
public class ApprovalProcessControllerTest {
    @testSetup
    static void setupTestData() {
        // Ensure the standard Pricebook exists
         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a test Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;

        // Create a Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = TRUE);
        insert prod;

        // Create a PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = TRUE
        );
        insert pbe;

        // Create an OpportunityLineItem with Approval_Status__c as 'Pending'
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Approval_Status__c = 'Pending'
        );
        insert oli;
    }

    @isTest
    static void testGetPendingApprovals() {
        Test.startTest();
        List<OpportunityLineItem> pendingApprovals = ApprovalProcessController.getPendingApprovals();
        Test.stopTest();

        System.assertNotEquals(0, pendingApprovals.size(), 'Expected at least one pending approval');
       // System.assertEquals('Pending', pendingApprovals[0].Approval_Status__c, 'Approval status should be Pending');
    }

    @isTest
    static void testUpdateApprovalStatus() {
        List<OpportunityLineItem> oliList = [SELECT Id FROM OpportunityLineItem WHERE Approval_Status__c = 'Pending' LIMIT 1];
        System.assertNotEquals(0, oliList.size(), 'Expected at least one OpportunityLineItem');

        OpportunityLineItem oli = oliList[0];

        Test.startTest();
        ApprovalProcessController.updateApprovalStatus(oli.Id, 'Approved');
        Test.stopTest();

        OpportunityLineItem updatedOLI = [SELECT Approval_Status__c FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals('Approved', updatedOLI.Approval_Status__c, 'Approval status should be updated to Approved');
    }
}