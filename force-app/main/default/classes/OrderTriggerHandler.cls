public class OrderTriggerHandler {
    public static void mapChecklistFields(List<Order> newOrders) {
        Set<Id> checklistIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Order ord : newOrders) {
            if (ord.Check_List__c != null) {
                checklistIds.add(ord.Check_List__c);
            }
            if (ord.AccountId != null) {
                accountIds.add(ord.AccountId);
            }
        }

        // Query Check_List__c records
        Map<Id, Check_List__c> checklistMap = new Map<Id, Check_List__c>(
            [SELECT Id, Commission_if_Any__c, ECGC_Status__c, Container_Type__c,
                    Type_of_Pallet__c, VOL_Logo_on_Packing__c, SIGNED_COPY_OF_SALES_Order__c
             FROM Check_List__c
             WHERE Id IN :checklistIds]
        );

        // Query Account records
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, GSTIN_No__c, PAN_No__c, Payment_Method__c
             FROM Account
             WHERE Id IN :accountIds]
        );

        // Query Address_Information__c records for 'Bill To' and 'Ship To'
        Map<Id, Address_Information__c> billToMap = new Map<Id, Address_Information__c>();
        Map<Id, Address_Information__c> shipToMap = new Map<Id, Address_Information__c>();

        List<Address_Information__c> addressList = [
            SELECT Id, Account__c, RecordType.Name
            FROM Address_Information__c
            WHERE Account__c IN :accountIds
        ];

        for (Address_Information__c addr : addressList) {
            if (addr.RecordType.Name == 'Bill To' && !billToMap.containsKey(addr.Account__c)) {
                billToMap.put(addr.Account__c, addr);
            } else if (addr.RecordType.Name == 'Ship To' && !shipToMap.containsKey(addr.Account__c)) {
                shipToMap.put(addr.Account__c, addr);
            }
        }

        // Map fields to Order
        for (Order ord : newOrders) {
            if (ord.Check_List__c != null && checklistMap.containsKey(ord.Check_List__c)) {
                Check_List__c checklist = checklistMap.get(ord.Check_List__c);
                ord.Commission_if_Any__c = checklist.Commission_if_Any__c;
                ord.ECGC_Status__c = checklist.ECGC_Status__c;
                ord.Container_size__c = checklist.Container_Type__c;
                ord.Type_of_Pallet__c = checklist.Type_of_Pallet__c;
                ord.Vol_Logo_on_Packing__c = checklist.VOL_Logo_on_Packing__c;
                ord.Signed_Copy_of_Sales_Order__c = checklist.SIGNED_COPY_OF_SALES_Order__c;
            }

            if (ord.AccountId != null) {
                if (accountMap.containsKey(ord.AccountId)) {
                    Account acc = accountMap.get(ord.AccountId);
                    ord.GST_No__c = acc.GSTIN_No__c;
                    ord.PAN_No__c = acc.PAN_No__c;
                    ord.Payment_Method__c = acc.Payment_Method__c;
                }

                if (billToMap.containsKey(ord.AccountId)) {
                    ord.Consignee_Address1__c = billToMap.get(ord.AccountId).Id;
                }

                if (shipToMap.containsKey(ord.AccountId)) {
                    ord.Delivery_Address1__c = shipToMap.get(ord.AccountId).Id;
                }
            }
        }
    }
}