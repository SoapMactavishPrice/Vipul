@isTest
public class SendPurchasePriceEmailQuoteAsyncTest {
    
    @testSetup
    static void setupData() {
        // Create a dummy user for email sending
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert u;
    }

    @isTest
    static void testSendEmailAsync() {
        // Prepare line items
        SendPurchasePriceEmailQuoteAsync.QuoteLineItemWrapper lineItem1 = 
            new SendPurchasePriceEmailQuoteAsync.QuoteLineItemWrapper();
        lineItem1.productName = 'Product A';
        lineItem1.quantity = 5;
        lineItem1.purchasePrice = 100;

        SendPurchasePriceEmailQuoteAsync.QuoteLineItemWrapper lineItem2 = 
            new SendPurchasePriceEmailQuoteAsync.QuoteLineItemWrapper();
        lineItem2.productName = 'Product B';
        lineItem2.quantity = 10;
        lineItem2.purchasePrice = null; // testing "Not Available"

        // Prepare wrapper
        SendPurchasePriceEmailQuoteAsync.QuoteWrapper wrapper = 
            new SendPurchasePriceEmailQuoteAsync.QuoteWrapper();
        wrapper.id = 'Q-12345';
        wrapper.name = 'Test Quote';
        wrapper.ownerEmail = 'testuser@example.com';
        wrapper.ownerName = 'Test Owner';
        wrapper.link = 'https://example.com/quote/Q-12345';
        wrapper.attendeeName = 'Attendee Name';
        wrapper.lineItems = new List<SendPurchasePriceEmailQuoteAsync.QuoteLineItemWrapper>{ lineItem1, lineItem2 };

        // Serialize wrapper
        String wrapperJson = JSON.serialize(wrapper);

        Test.startTest();
        // Call future method
        SendPurchasePriceEmailQuoteAsync.sendEmailAsync(wrapperJson);
        Test.stopTest(); // ensures future executes

        // Verify email
      //  List<Messaging.SingleEmailMessage> emails = Messaging.sendEmail(
         //   new List<Messaging.SingleEmailMessage>(), false
     //   );
      
    }
}