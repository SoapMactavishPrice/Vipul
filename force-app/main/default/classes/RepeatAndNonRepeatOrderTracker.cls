public class RepeatAndNonRepeatOrderTracker {

    public static void trackRepeatOrders() {
        // Step 1: Get all OrderItems with related Order and Product info
        List<OrderItem> allOrderItems = [
            SELECT Id, Product2Id, Product2.Name,
                   Order.AccountId, Order.Account.Name, Order.EffectiveDate
            FROM OrderItem
            WHERE Order.Status = 'Activated'
            ORDER BY Order.AccountId, Product2Id, Order.EffectiveDate
        ];

        // Step 2: Group by Account + Product
        Map<String, List<OrderItem>> groupedItems = new Map<String, List<OrderItem>>();

        for (OrderItem item : allOrderItems) {
            String key = item.Order.AccountId + '-' + item.Product2Id;
            if (!groupedItems.containsKey(key)) {
                groupedItems.put(key, new List<OrderItem>());
            }
            groupedItems.get(key).add(item);
        }

        // Step 3: Analyze each group and insert tracking records
        List<Order_Repeat_Tracking__c> trackingRecords = new List<Order_Repeat_Tracking__c>();

        for (String key : groupedItems.keySet()) {
            List<OrderItem> items = groupedItems.get(key);
            OrderItem firstItem = items[0];
            Boolean isRepeated = false;
            Date repeatDate = null;

            if (items.size() > 1) {
                for (Integer i = 1; i < items.size(); i++) {
                    Date gapDate = items[i].Order.EffectiveDate;
                    if (gapDate.daysBetween(firstItem.Order.EffectiveDate) >= 60) {
                        isRepeated = true;
                        repeatDate = gapDate;
                        break;
                    }
                }
            }

            Order_Repeat_Tracking__c tracking = new Order_Repeat_Tracking__c();
            tracking.Account__c = firstItem.Order.AccountId;
            tracking.Product__c = firstItem.Product2Id;
            tracking.First_Order_Date__c = firstItem.Order.EffectiveDate;
            tracking.Repeat_Order_Date__c = repeatDate;
            tracking.Is_Repeated__c = isRepeated;

            trackingRecords.add(tracking);
        }

        if (!trackingRecords.isEmpty()) {
            insert trackingRecords;
        }
    }
}