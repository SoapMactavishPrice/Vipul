@RestResource(urlMapping = '/CreateSalesOrder')
global class CreateSalesOrderAPI {
    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');

        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'CreateSalesOrder_API';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Created_Time__c = Datetime.now();

        List < JSON2ApexSaveWebToLead > jsonDataAccountList = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonDataAccountList' + jsonDataAccountList);

        try {

            Map < String, Object > responseMap = new Map < String, Object > ();
            Set<String> customerCodeSet = new Set<String>();
            Set<String> salesOrderNoSet = new Set<String>();
            Set<String> itemNumberSet = new Set<String>();
            Set<String> productIdSet = new Set<String>();
            List < Account > existingAccount = new List < Account > ();
            Map < String, String > existingAccountMap = new Map < String, String > ();
            Map < String, String > salesOrderNoMap = new Map < String, String > ();
            Map < String, String > quoteNoMap = new Map < String, String > ();
            Map<String, Object> prodCodeProdIdMap = new Map<String, Object>();
            List <Order> insertSalesOrderList = new List < Order > ();
            List <OrderItem> insertSalesOrderLineList = new List < OrderItem > ();

            for (JSON2ApexSaveWebToLead jsonObj: jsonDataAccountList) {
                if (String.isBlank(jsonObj.customerCode) || String.isBlank(jsonObj.salesOrderNumber)) {
                    throw new IllegalArgumentException('customerCode & salesOrderNumber cannot be blank');
                } else {
                    customerCodeSet.add(jsonObj.customerCode);
                    salesOrderNoSet.add(jsonObj.salesOrderNumber);
                    for (OrderLineItemWrapper z : jsonObj.OrderLineItems) {
                        itemNumberSet.add(z.productCode);
                    }
                }
            }

            // Get Existing Accounts list
            List < Account > existingAccountList = [
                SELECT Id, Name, Customer_Code__c
                FROM Account
                WHERE Customer_Code__c IN :customerCodeSet
            ];

            // Create key value pair of existing Accounts and get their ID
            for (Account Account: existingAccountList) {
                existingAccountMap.put(Account.Customer_Code__c, Account.Id);
            }

            // Get Existing Order List
            List <Order> existingOrderList = [
                SELECT Id, Name, Oracle_Sales_Order_No__c
                FROM Order
                WHERE Oracle_Sales_Order_No__c IN :salesOrderNoSet
            ];

            for (Order ord : existingOrderList) {
                salesOrderNoMap.put(ord.Oracle_Sales_Order_No__c, ord.Id);
            }

            // Get Existing Item List
            List<Product2> productList = [
                SELECT Id, Name, Item_No__c
                FROM Product2
                WHERE Item_No__c != null
                AND Item_No__c IN :itemNumberSet
            ];

            for (Product2 p : productList) {
                prodCodeProdIdMap.put(p.Item_No__c, p.Id);
                productIdSet.add(p.Id);
            }

            // Get Quote Id by SOnumber
            List <Quote> existingQuoteList = [
                SELECT Id, Name, SAP_SO_Number__c
                FROM Quote
                WHERE SAP_SO_Number__c IN :salesOrderNoSet
            ];

            for (Quote q : existingQuoteList) {
                quoteNoMap.put(q.SAP_SO_Number__c, q.Id);
            }

            
            Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            System.debug(productIdSet);
            System.debug(standardPB.Id);
            List<PricebookEntry> pbeList = [
                SELECT Id, Product2Id, Product2.Item_No__c, CurrencyIsoCode 
                FROM PricebookEntry
                WHERE Product2Id != null
                AND Product2.Item_No__c != null
                AND Product2Id IN :productIdSet
                AND Pricebook2Id = :standardPB.Id
                AND IsActive = true
            ];

            System.debug(pbeList);

            Map<String, Object> pbentryMap = new Map<String, Object>();
            for (PricebookEntry p : pbeList) {
                pbentryMap.put(p.Product2.Item_No__c+p.CurrencyIsoCode, p.Id);
            }

            for (JSON2ApexSaveWebToLead jsonObj: jsonDataAccountList) {
                if (salesOrderNoMap.containsKey(jsonObj.salesOrderNumber)) {
                    throw new IllegalArgumentException('Duplicate salesOrderNumber found');
                } else if (!existingAccountMap.containsKey(jsonObj.customerCode)) {
                    throw new IllegalArgumentException('customerCode not found');
                } else {
                    Order ord = new Order();
                    if (quoteNoMap.containsKey(jsonObj.salesOrderNumber)) {
                        ord.QuoteId = quoteNoMap.get(jsonObj.salesOrderNumber);
                    } else {
                        throw new IllegalArgumentException('Quote not found for salesOrderNumber: ' + jsonObj.salesOrderNumber + '');
                    }
                    ord.Oracle_Sales_Order_No__c = jsonObj.salesOrderNumber;
                    ord.Pricebook2Id = standardPB.Id;
                    ord.AccountId = existingAccountMap.get(jsonObj.customerCode);
                    ord.EffectiveDate = Date.valueOf(jsonObj.effectiveDate);
                    ord.Status = jsonObj.status;
                    ord.Type = jsonObj.type;
                    // ord.TotalAmount = Date.valueOf(jsonObj.totalAmount);
                    ord.Commission_if_Any__c = jsonObj.commissionIfAny;
                    ord.Agent_Name__c = jsonObj.agentName;
                    // ord.Previous_Order_No__c = Decimal.valueOf(jsonObj.previousOrderNo);
                    ord.Prior_Approval_from_Third_Party__c = jsonObj.priorApprovalFromThirdParty;
                    ord.Prior_Approval_from_Third_Party_Remark__c = jsonObj.priorApprovalFromThirdPartyRemark;
                    ord.Any_Other_Specification__c = jsonObj.anyOtherSpecification;
                    ord.Order_Source__c = jsonObj.orderSource;
                    ord.Other_Order_Source__c = jsonObj.otherOrderSource;
                    ord.Customer_Courier_Address__c = jsonObj.customerCourierAddress;
                    ord.Approved_Date__c = Date.valueOf(jsonObj.approvedDate);
                    ord.Customer_Purchase_Order_No__c = jsonObj.customerPurchaseOrderNo;
                    ord.Order_Rec_Date__c = Date.valueOf(jsonObj.orderRecDate);
                    ord.Revision_Date__c = Date.valueOf(jsonObj.revisionDate);
                    ord.LC_No__c = jsonObj.lcNo;
                    ord.Approval_status__c = jsonObj.approvalStatus;
                    ord.Order_Lost_Reason__c = jsonObj.orderLostReason;
                    ord.LC_Date__c = Date.valueOf(jsonObj.lcDate);
                    ord.SIGNED_COPY_OF_SALES_Order__c = jsonObj.signedCopyOfSalesOrder;
                    ord.Order_Type__c = jsonObj.orderType;
                    ord.SO_Series__c = jsonObj.soSeries;
                    ord.Prepared_by__c = jsonObj.preparedBy;
                    ord.Customer_Owner__c = jsonObj.customerOwner;
                    ord.CustomerCode__c = jsonObj.customerCodeField;
                    ord.GST_No__c = jsonObj.gstNo;
                    ord.PAN_No__c = jsonObj.panNo;
                    ord.Exchange_Rate__c = checkNullDecimal(jsonObj.exchangeRate);
                    ord.Contact_Info_for_Logistic_Purpose__c = jsonObj.contactInfoForLogisticPurpose;
                    ord.ECGC_Status__c = jsonObj.ecgcStatus;
                    ord.Customer_required_Shipment_Date__c = Date.valueOf(jsonObj.customerRequiredShipmentDate);
                    ord.Customer_Approve_Limit_from_ECGC__c = checkNullDecimal(jsonObj.customerApproveLimitFromEcgc);
                    ord.Total_Amount_in_INR__c = checkNullDecimal(jsonObj.totalAmountInInr);
                    ord.Tentative_Dispatch_Date_from_Plant__c = Date.valueOf(jsonObj.tentativeDispatchDateFromPlant);
                    ord.Tentative_Vessel_Planning__c = jsonObj.tentativeVesselPlanning;
                    ord.Shipment__c = jsonObj.shipment;
                    ord.Shipment_Remarks__c = jsonObj.shipmentRemarks;
                    ord.Container_size__c = jsonObj.containerSize;
                    ord.Additional_Detention_period_if_required__c = checkNullDecimal(jsonObj.additionalDetentionPeriodIfRequired);
                    ord.Type_of_Pallet__c = jsonObj.typeOfPallet;
                    ord.Special_Remark_for_Packing__c = jsonObj.specialRemarkForPacking;
                    ord.VOL_Logo_on_Packing__c = jsonObj.volLogoOnPacking;
                    ord.Shipping_mark__c = jsonObj.shippingMark;
                    ord.Payment_Terms__c = jsonObj.paymentTerms;
                    ord.Other_Payment_Terms__c = jsonObj.otherPaymentTerms;
                    ord.Inco_Terms__c = jsonObj.incoTerms;
                    ord.Payment_Method__c = jsonObj.paymentMethod;
                    ord.Description = jsonObj.description;
                    ord.Location_Name__c = jsonObj.Location_Name;
                    ord.Branch_Name__c = jsonObj.Branch_Name;
                    insertSalesOrderList.add(ord);
                }
            }


            if(!insertSalesOrderList.isEmpty()){
                Insert insertSalesOrderList;
                for (Integer i = 0; i < jsonDataAccountList.size(); i++) {
                    Order ord = insertSalesOrderList[i];
                    JSON2ApexSaveWebToLead req = jsonDataAccountList[i];
                    for (OrderLineItemWrapper z : req.OrderLineItems) {
                        Order exord = [SELECT Id, CurrencyIsoCode FROM Order WHERE Id = :ord.Id];
                        OrderItem oli = new OrderItem();
                        oli.OrderId = ord.Id;
                        if (prodCodeProdIdMap.containskey(z.productCode)) {
                            oli.Product2Id = String.valueOf(prodCodeProdIdMap.get(z.productCode));
                            if (pbentryMap.containskey(z.productCode+exord.CurrencyIsoCode)) {
                                oli.PricebookEntryId = String.valueOf(pbentryMap.get(z.productCode+exord.CurrencyIsoCode));
                            } else {
                                delete insertSalesOrderList;
                                throw new IllegalArgumentException('Pricebook Entry not present');
                            }
                        } else {
                            delete insertSalesOrderList;
                            throw new IllegalArgumentException('Product Not Found');
                        }
                        oli.Product_Code__c = z.productCode;
                        oli.Quality__c = z.quality;
                        oli.Packaging_Quantity__c = checkNullDecimal(z.packagingQuantity);
                        oli.Packing_Type__c = z.packingType;
                        oli.Rejected_Purchase_Price__c = Boolean.valueOf(z.rejectedPurchasePrice);
                        oli.Purchase_Price_Status__c = z.purchasePriceStatus;
                        oli.Reject_Reason__c = z.rejectReason;
                        oli.Item_Group_Code__c = z.itemGroupCode;
                        oli.Pallet_Required_or_Not__c = z.palletRequiredOrNot;
                        oli.No_Pallet__c = checkNullDecimal(z.noPallet);
                        oli.Specification__c = z.specification;
                        oli.FOB_Price__c = checkNullDecimal(z.fobPrice);
                        oli.Freight_Amount__c = checkNullDecimal(z.freightAmount);
                        oli.Total_Value__c = checkNullDecimal(z.totalValue);
                        oli.GST__c = checkNullDecimal(z.gst);
                        oli.Line_Total__c = checkNullDecimal(z.lineTotal);
                        oli.Item_Group_Name__c = z.itemGroupName;
                        oli.HSN_SAC__c = z.hsnSAC;
                        oli.UoM__c = z.uom;
                        oli.Discount__c = checkNullDecimal(z.discount);
                        oli.Price_After_Discount__c = checkNullDecimal(z.priceAfterDiscount);
                        oli.Item_Amount_before_Tax__c = checkNullDecimal(z.itemAmountBeforeTax);
                        oli.Tax_Code__c = z.taxCode;
                        oli.Tax_Amount__c = checkNullDecimal(z.taxAmount);
                        oli.Item_Amount_after_Tax__c = checkNullDecimal(z.itemAmountAfterTax);
                        oli.Item_Amount_after_Tax_INR__c = checkNullDecimal(z.itemAmountAfterTaxINR);
                        oli.Quantity = checkNullDecimal(z.quantity);
                        oli.Purchase_Price_in_INR__c = checkNullDecimal(z.purchasePriceInINR);
                        oli.Converter__c = checkNullDecimal(z.converter);
                        oli.Margin_Type__c = z.marginType;
                        oli.Margin_Value__c = checkNullDecimal(z.marginValue);
                        oli.Margin_Percent__c = checkNullDecimal(z.marginPercent);
                        oli.Dispatch_Quantity__c = checkNullDecimal(z.dispatchQuantity);
                        oli.UnitPrice = checkNullDecimal(z.unitPrice);
                        oli.Commission_Type__c = z.commissionType;
                        oli.Commission_Value__c = checkNullDecimal(z.commissionValue);
                        oli.Commission_Percent__c = checkNullDecimal(z.commissionPercent);
                        oli.Freight_Value__c = checkNullDecimal(z.freightValue);
                        oli.Description = z.description;

                        insertSalesOrderLineList.add(oli);
                    }
                }
                
                if(!insertSalesOrderLineList.isEmpty()){
                    insert insertSalesOrderLineList;
                }
            }

            responseMap.put('status', 'success');
            responseMap.put('message', 'Sales Order created Successfully');

            String resp = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 200;

            api_log.Status__c = 'Success';
            api_log.Response_Code__c = '200';
            api_log.Response__c = String.valueOf(resp);
            api_log.response_time__c = Datetime.now();

        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            // errorResMap.put('Message', 'Something went wrong');
            // errorResMap.put('Error1', e.getMessage());
            // errorResMap.put('Error2', '' + e.getlineNumber());
            // errorResMap.put('Error3', '' + String.valueOf(e));

            errorResMap.put('status', 'fail');
            errorResMap.put('message', e.getMessage());

            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;

            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.response_time__c = Datetime.now();

        }

        insert api_log;
    }

    public static Decimal checkNullDecimal (String val){

        if(val == null || val == ''){
            return 0.0;
        } else {
            return Decimal.valueOf(val);
        }
    }

    public class JSON2ApexSaveWebToLead {
        public String salesOrderNumber;
        public String customerCode;
        public String effectiveDate;
        public String status;
        public String type;
        // public String totalAmount;
        public String commissionIfAny;
        public String agentName;
        public String previousOrderNo;
        public String priorApprovalFromThirdParty;
        public String priorApprovalFromThirdPartyRemark;
        public String anyOtherSpecification;
        public String orderSource;
        public String otherOrderSource;
        public String customerCourierAddress;
        public String approvedDate;
        public String customerPurchaseOrderNo;
        public String orderRecDate;
        public String revisionDate;
        public String lcNo;
        public String approvalStatus;
        public String orderLostReason;
        public String lcDate;
        public String signedCopyOfSalesOrder;
        public String orderType;
        public String soSeries;
        public String preparedBy;
        public String customerOwner;
        public String customerCodeField;
        public String gstNo;
        public String panNo;
        public String exchangeRate;
        public String contactInfoForLogisticPurpose;
        public String ecgcStatus;
        public String customerRequiredShipmentDate;
        public String customerApproveLimitFromEcgc;
        public String totalAmountInInr;
        public String tentativeDispatchDateFromPlant;
        public String tentativeVesselPlanning;
        public String shipment;
        public String shipmentRemarks;
        public String containerSize;
        public String additionalDetentionPeriodIfRequired;
        public String typeOfPallet;
        public String specialRemarkForPacking;
        public String volLogoOnPacking;
        public String shippingMark;
        public String paymentTerms;
        public String otherPaymentTerms;
        public String incoTerms;
        public String paymentMethod;
        public String description;
        public String Location_Name;
        public String Branch_Name;
        public String currencyCode;
        public List<OrderLineItemWrapper> OrderLineItems;
    }

    public class OrderLineItemWrapper {
        public String productCode;
        public String quality;
        public String packagingQuantity;
        public String packingType;
        public String rejectedPurchasePrice;
        public String purchasePriceStatus;
        public String rejectReason;
        public String itemGroupCode;
        public String palletRequiredOrNot;
        public String noPallet;
        public String specification;
        public String fobPrice;
        public String freightAmount;
        public String totalValue;
        public String gst;
        public String lineTotal;
        public String itemGroupName;
        public String hsnSAC;
        public String uom;
        public String discount;
        public String priceAfterDiscount;
        public String itemAmountBeforeTax;
        public String taxCode;
        public String taxAmount;
        public String itemAmountAfterTax;
        public String itemAmountAfterTaxINR;
        public String quantity;
        public String purchasePriceInINR;
        public String converter;
        public String marginType;
        public String marginValue;
        public String marginPercent;
        public String dispatchQuantity;
        public String unitPrice;
        public String commissionType;
        public String commissionValue;
        public String commissionPercent;
        public String freightValue;
        public String description;
    }


    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead > ) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead > .class);
    }

}