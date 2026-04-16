@isTest
private class OrderTriggerHandlerTest {

    @isTest
    static void testMapChecklistFields() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            GSTIN_No__c = '29ABCDE1234F2Z5',
            PAN_No__c = 'ABCDE1234F',
            Payment_Method__c = 'PDC after dispatch'
        );
        insert acc;

        // Create Check_List__c
        Check_List__c checklist = new Check_List__c(
            Name = 'Test Checklist',
            Commission_if_Any__c = 'Yes',
            ECGC_Status__c = 'Defaulter',
           // Container_Type__c = '40'',
            Type_of_Pallet__c = 'Plastic',
          //  VOL_Logo_on_Packing__c = true,
          //  SIGNED_COPY_OF_SALES_Order__c = true,
            Account__c = acc.Id
        );
        insert checklist;

        // Create Order with reference to Account and Checklist
        Order ord = new Order(
            AccountId = acc.Id,
            Check_List__c = checklist.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );

        // Add order to list and call handler
        List<Order> newOrders = new List<Order>{ ord };

        Test.startTest();
        OrderTriggerHandler.mapChecklistFields(newOrders);
        Test.stopTest();

       
    }

    @isTest
    static void testMapChecklistFields_NoChecklistOrAccount() {
        // Create an Order without AccountId and Check_List__c
        Order ord = new Order(
            Status = 'Draft',
            EffectiveDate = Date.today()
        );

        List<Order> newOrders = new List<Order>{ ord };

        Test.startTest();
        OrderTriggerHandler.mapChecklistFields(newOrders);
        Test.stopTest();

       
    }
}