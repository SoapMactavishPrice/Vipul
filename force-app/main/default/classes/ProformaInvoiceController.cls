public class ProformaInvoiceController {
    public Id quoteId { get; set; }
    
    public ProformaInvoiceController() {
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
    }
    
    public PageReference createProformaInvoice() {
        // Fetch the Quote and its Line Items
        Quote quote = [SELECT Id, Name, AccountId, ContactId, OpportunityId, ExpirationDate, Revision_Number__c, Tax, Quote_Type__c, OwnerId,
                       Description, Email, Phone, Status, ShippingHandling, GrandTotal, Contact.Email,  Consignee_Address1__c, Delivery_Address1__c,
                       Inco_Terms__c, Payment_Terms__c, Other_Payment_Terms__c, Country_of_Origin__c, CurrencyIsoCode, Transport_Value__c, Include_TCS_Value__c,
                       Consignee_Address1__r.Country__c, Consignee_Address1__r.Country__r.Country_Status__c, Consignee_Address1__r.Country__r.Country_Rating__c,
                       Delivery_Address_Same_As_Consignee__c,
                       (SELECT Id, Quantity, UnitPrice, Discount, ListPrice, Description, Product2Id,Packing_Type__c, 
                        Purchase_Price_in_INR__c, Converter__c, Margin_Type__c, Margin_Value__c, Margin_Percent__c, Commission_Type__c,
                        Commission_Value__c, Commission_Percent__c, Freight_Value__c, Product_Family__c, Rejected_Purchase_Price__c,
                        Reject_Reason__c, Purchase_Price_Status__c, Quality__c, CurrencyIsoCode, Packing__c
                        FROM QuoteLineItems) 
                       FROM Quote WHERE Id = :quoteId];
        
        // Check if a Proforma Invoice already exists for this Quote
        List<Proforma_Invoice__c> existingInvoices = [SELECT Id FROM Proforma_Invoice__c WHERE Quote__c = :quote.Id];
        Proforma_Invoice__c proformaInvoice;
        
        if (existingInvoices.isEmpty()) {
            // Create Proforma Invoice
            proformaInvoice = new Proforma_Invoice__c();
            proformaInvoice.Quote__c = quote.Id;
        } else {
            // Use the existing Proforma Invoice
            proformaInvoice = existingInvoices[0];
        }
        
        // Update Proforma Invoice fields
        proformaInvoice.Name = quote.Name;
        proformaInvoice.Account_Name__c = quote.AccountId;
        proformaInvoice.Contact_Name__c = quote.ContactId;
        proformaInvoice.Expiration_Date__c = quote.ExpirationDate;
        proformaInvoice.Status__c = quote.Status;
        proformaInvoice.Enquiry_Name__c = quote.OpportunityId;
        proformaInvoice.Revision_Number__c = quote.Revision_Number__c;
        proformaInvoice.Tax__c = quote.Tax;
        proformaInvoice.Description__c = quote.Description;
        proformaInvoice.Consignee_Address1__c = quote.Consignee_Address1__c;
        proformaInvoice.Delivery_Address1__c = quote.Delivery_Address1__c;
        proformaInvoice.Email__c = quote.Email;
        proformaInvoice.Phone__c = quote.Phone;
        proformaInvoice.Shipping_and_Handling__c = quote.ShippingHandling;
        //proformaInvoice.Grand_Total__c = quote.GrandTotal;
        proformaInvoice.Inco_Terms__c = quote.Inco_Terms__c;
        proformaInvoice.Payment_Terms__c = quote.Payment_Terms__c;
        proformaInvoice.Other_Payment_Terms__c = quote.Other_Payment_Terms__c;
        proformaInvoice.Country_of_Origin__c = quote.Country_of_Origin__c;
        proformaInvoice.CurrencyIsoCode = quote.CurrencyIsoCode;
        proformaInvoice.Transport_Value__c = quote.Transport_Value__c;
        proformaInvoice.Proforma_Invoice_Type__c = quote.Quote_Type__c;
        proformaInvoice.Detention_Free_Period_Required__c = '14 Days by Default';
        proformaInvoice.OwnerId = quote.OwnerId;
        proformaInvoice.Country_of_Final_Destination__c = quote.Consignee_Address1__r.Country__c;
        proformaInvoice.Country_Status__c = quote.Consignee_Address1__r.Country__r.Country_Status__c;
        proformaInvoice.Country_Rating__c = quote.Consignee_Address1__r.Country__r.Country_Rating__c;
        proformaInvoice.Include_TCS_Value__c = quote.Include_TCS_Value__c;
        proformaInvoice.Delivery_Address_Same_As_Consignee__c = quote.Delivery_Address_Same_As_Consignee__c;
        
        // Query the Contact records associated with the Account
        List<Contact> contacts = [SELECT Email FROM Contact WHERE AccountId = :quote.AccountId];
        
        // Concatenate the email addresses
        String contactEmails = '';
        for (Contact contact : contacts) {
            if (contact.Email != null) {
                contactEmails += contact.Email + '; ';
            }
        }
        
        // Remove the trailing semicolon and space
        if (contactEmails.endsWith('; ')) {
            contactEmails = contactEmails.substring(0, contactEmails.length() - 2);
        }
        
        // Assign the concatenated string to the Contact_Info_for_Logistic_Purpose__c field
        proformaInvoice.Contact_Info_for_Logistic_Purpose__c = contactEmails;
        
        //proformaInvoice.Contact_Info_for_Logistic_Purpose__c = quote.Contact.Email;
        proformaInvoice.Delivery_Schedule__c = '3 to 4 Weeks';
        
        // Fetch related Check_List__c record using AccountId from Quote
        List<Check_List__c> checkLists = [
            SELECT Id, Buyer__c, Notify_Information__c, Buyer_s_Ref__c, Buyer_s_Date__c, SO_Date__c, SO_No__c, Revision_Date__c, Commission_if_Any__c, Commission_Comment__c,
            PSS__c, Document_to_be_Send__c, Company_Bank__c, Shipment_Date__c, QC_sample_in_Shipment__c, Signed_Copy_of_Sales_Order__c, Pre_Carriage_by__c, Port_of_Loading__c,
            Vessel_Flight_No__c, Port_of_Discharge__c, Final_Destination__c, Shipment_Type__c, Container_Type__c, Goods_Type__c,
            BL_Instruction__c, BL_Instruction_Comments__c, PreShipment_Inspection__c, Pallet_Packing__c, Nomination_Agent__c, 
            Extended_Period__c, Type_of_Pallet__c, Vol_Logo_on_Packing__c
            FROM Check_List__c
            WHERE Account__c = :quote.AccountId
            LIMIT 1
        ];
        
        // Map Check_List__c fields if available
        if (!checkLists.isEmpty()) {
            Check_List__c checklist = checkLists[0];
            proformaInvoice.Buyer__c = checklist.Buyer__c;
            proformaInvoice.Notify_Information__c = checklist.Notify_Information__c;
            proformaInvoice.Buyer_s_Ref__c = checklist.Buyer_s_Ref__c;
            proformaInvoice.Buyer_s_Date__c = checklist.Buyer_s_Date__c;
            proformaInvoice.SO_Date__c = checklist.SO_Date__c;
            proformaInvoice.SO_No__c = checklist.SO_No__c;
            proformaInvoice.PSS__c = checklist.PSS__c;
            proformaInvoice.Document_to_be_Send__c = checklist.Document_to_be_Send__c;
            proformaInvoice.Company_Bank__c = checklist.Company_Bank__c;
            proformaInvoice.Shipment_Date__c = checklist.Shipment_Date__c;
            proformaInvoice.Revision_Date__c = checklist.Revision_Date__c;
            proformaInvoice.Commission_if_Any__c = checklist.Commission_if_Any__c;
            proformaInvoice.Commission_Comment__c = checklist.Commission_Comment__c;
            proformaInvoice.QC_sample_in_Shipment__c = checklist.QC_sample_in_Shipment__c;
            proformaInvoice.Signed_Copy_of_Sales_Order__c = checklist.Signed_Copy_of_Sales_Order__c;
            proformaInvoice.Pre_Carriage_by__c = checklist.Pre_Carriage_by__c;
            proformaInvoice.Port_of_Loading__c = checklist.Port_of_Loading__c;
            proformaInvoice.Vessel_Flight_No__c = checklist.Vessel_Flight_No__c;
            proformaInvoice.Port_of_Discharge__c = checklist.Port_of_Discharge__c;
            proformaInvoice.Final_Destination__c = checklist.Final_Destination__c;
            proformaInvoice.Shipment_Type__c = checklist.Shipment_Type__c;
            proformaInvoice.Container_Type__c = checklist.Container_Type__c;
            proformaInvoice.Goods_Type__c = checklist.Goods_Type__c;
            proformaInvoice.BL_Instruction__c = checklist.BL_Instruction__c;
            proformaInvoice.BL_Instruction_Comments__c = checklist.BL_Instruction_Comments__c;
            proformaInvoice.PreShipment_Inspection__c = checklist.PreShipment_Inspection__c;
            proformaInvoice.Pallet_Packing__c = checklist.Pallet_Packing__c;
            proformaInvoice.Nomination_Agent__c = checklist.Nomination_Agent__c;
            proformaInvoice.Extended_Period__c = checklist.Extended_Period__c;
            proformaInvoice.Type_of_Pallet__c = checklist.Type_of_Pallet__c;
            proformaInvoice.Vol_Logo_on_Packing__c = checklist.Vol_Logo_on_Packing__c;
        }


        upsert proformaInvoice;
        
        // Delete existing Proforma Invoice Line Items
        List<Proforma_Invoice_Line_Item__c> existingLineItems = [SELECT Id FROM Proforma_Invoice_Line_Item__c WHERE Proforma_Invoice_Name__c = :proformaInvoice.Id];
        delete existingLineItems;
        
        // Create new Proforma Invoice Line Items
        List<Proforma_Invoice_Line_Item__c> proformaLineItems = new List<Proforma_Invoice_Line_Item__c>();
        for (QuoteLineItem qli : quote.QuoteLineItems) {
            Proforma_Invoice_Line_Item__c pili = new Proforma_Invoice_Line_Item__c();
            pili.Proforma_Invoice_Name__c = proformaInvoice.Id;
            pili.Quantity__c = qli.Quantity;
            pili.Discount_Percentage__c = qli.Discount;
            pili.List_Price__c = qli.ListPrice;
            pili.Line_Item_Description__c = qli.Description;
            pili.Product__c = qli.Product2Id;
            pili.Sales_Price__c = qli.UnitPrice;
            pili.Packing_Type__c = qli.Packing_Type__c;
            pili.Purchase_Price_in_INR__c = qli.Purchase_Price_in_INR__c;
            pili.Converter__c = qli.Converter__c;
            pili.Margin_Type__c = qli.Margin_Type__c;
            pili.Margin_Value__c= qli.Margin_Value__c;
            pili.Margin_Percent__c = qli.Margin_Percent__c;
            pili.Commission_Type__c = qli.Commission_Type__c;
            pili.Commission_Value__c = qli.Commission_Value__c;
            pili.Commission_Percent__c = qli.Commission_Percent__c;
            pili.Freight_Value__c = qli.Freight_Value__c;
            pili.Product_Family__c = qli.Product_Family__c;
            pili.Rejected_Purchase_Price__c = qli.Rejected_Purchase_Price__c;
            pili.Reject_Reason__c = qli.Reject_Reason__c;
            pili.Purchase_Price_Status__c = qli.Purchase_Price_Status__c;
            pili.CurrencyIsoCode = qli.CurrencyIsoCode;
            pili.Quality__c = qli.Quality__c;
            pili.Packing__c = parseDecimalFromPicklist(qli.Packing__c);
            proformaLineItems.add(pili); 
        }
        insert proformaLineItems;
        
        // Redirect to the Proforma Invoice record page
        PageReference pageRef = new PageReference('/' + proformaInvoice.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public static Decimal parseDecimalFromPicklist(String s) {
        if (String.isBlank(s)) return null;
        
        // Remove everything except digits, dot, and minus (handles "5 kg", "10.5 kg", "-3 kg")
        String cleaned = s.trim().toLowerCase().replaceAll('[^0-9.-]', '');
        
        // Guard against non-numeric remnants like "-", ".", or "-."
        if (cleaned == '' || cleaned == '-' || cleaned == '.' || cleaned == '-.') return null;
        
        try {
            return Decimal.valueOf(cleaned);
        } catch (Exception e) {
            // If parsing fails for any reason, treat as no numeric value
            return null;
        }
    }

}