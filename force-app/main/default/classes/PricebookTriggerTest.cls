@isTest
public class PricebookTriggerTest {
    
    @isTest
    static void testAfterInsertTrigger() {
        // Create a test Pricebook2 record with CurrencyIsoCode = 'EUR'
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            CurrencyIsoCode = 'EUR'
        );

        Test.startTest();
        insert testPricebook;
        Test.stopTest();

        // Retrieve the inserted Pricebook2 record to validate it was created
        Pricebook2 insertedPricebook = [SELECT Id, Name, CurrencyIsoCode FROM Pricebook2 WHERE Id = :testPricebook.Id LIMIT 1];

        // Assert the record is created
        System.assertNotEquals(null, insertedPricebook, 'Pricebook should be inserted.');
        System.assertEquals('EUR', insertedPricebook.CurrencyIsoCode, 'CurrencyIsoCode should be EUR.');
    }

    @isTest
    static void testAfterInsertTriggerNonEUR() {
        // Create a test Pricebook2 record with a different currency
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook USD',
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );

        Test.startTest();
        insert testPricebook;
        Test.stopTest();

        // Retrieve the inserted Pricebook2 record to validate it was created
        Pricebook2 insertedPricebook = [SELECT Id, Name, CurrencyIsoCode FROM Pricebook2 WHERE Id = :testPricebook.Id LIMIT 1];

        // Assert the record is created
        System.assertNotEquals(null, insertedPricebook, 'Pricebook should be inserted.');
        System.assertEquals('USD', insertedPricebook.CurrencyIsoCode, 'CurrencyIsoCode should be USD.');
    }
}