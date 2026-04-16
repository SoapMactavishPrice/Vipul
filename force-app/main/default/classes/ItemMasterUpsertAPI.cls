@RestResource(urlMapping='/ItemMasterUpsert')
global class ItemMasterUpsertAPI {
    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        
        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'ItemMasterUpsert_API';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Created_Time__c = Datetime.now();

        List < JSON2ApexSaveWebToLead > jsonDataProductList = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonDataProductList' + jsonDataProductList);

        try {
            Map<String, Object> responseMap = new Map<String, Object>();
            Map<String, String> existingProductMap = new Map<String, String>();
            Map<String, String> existingHSNCodeMap = new Map<String, String>();

            // ------------------- Build map of existing products by ItemCode -------------------
            Map<String, Product2> existingProductByItemCodeMap = new Map<String, Product2>();
            for(Product2 p : [SELECT Id, Item_No__c FROM Product2]) {
                if(String.isNotBlank(p.Item_No__c)) {
                    existingProductByItemCodeMap.put(p.Item_No__c, p);
                }
            }
            
            // ------------------- Collect all sfprodid values from JSON -------------------
            Set<Id> sfprodIdsFromJSON = new Set<Id>();
            for(JSON2ApexSaveWebToLead jsonObj : jsonDataProductList) {
                if(String.isNotBlank(jsonObj.sfprodid)) {
                    sfprodIdsFromJSON.add(jsonObj.sfprodid);
                }
            }
            
            // ------------------- Query Salesforce for existing sfprodid -------------------
            Map<Id, Product2> existingProductBySfProdIdMap = new Map<Id, Product2>();
            if(!sfprodIdsFromJSON.isEmpty()) {
                for(Product2 p : [SELECT Id, Item_No__c FROM Product2 WHERE Id IN :sfprodIdsFromJSON]) {
                    existingProductBySfProdIdMap.put(p.Id, p);
                }
            }
            
            // ------------------- Process each JSON product -------------------
            List<Product2> upsertProductList = new List<Product2>();
            for(JSON2ApexSaveWebToLead jsonObj : jsonDataProductList) {
                Product2 p = new Product2();
                Boolean found = false;
                
                // 1️⃣ Check ItemCode first
                if(String.isNotBlank(jsonObj.itemCode) && existingProductByItemCodeMap.containsKey(jsonObj.itemCode)) {
                    p.Id = existingProductByItemCodeMap.get(jsonObj.itemCode).Id;
                    found = true;
                    System.debug('Updating product by ItemCode: ' + jsonObj.itemCode + ', Id: ' + p.Id);
                }
                // 2️⃣ Check sfprodid next (only if it exists in Salesforce)
                else if(String.isNotBlank(jsonObj.sfprodid) && existingProductBySfProdIdMap.containsKey(jsonObj.sfprodid)) {
                    p.Id = jsonObj.sfprodid;
                    found = true;
                    System.debug('Updating product by sfprodid: ' + jsonObj.sfprodid);
                }
                // 3️⃣ Neither found → create new
                else if(!found && String.isNotBlank(jsonObj.itemCode)) {
                    p.Item_No__c = jsonObj.itemCode;
                    System.debug('Creating new product with ItemCode: ' + jsonObj.itemCode);
                } else {
                    throw new IllegalArgumentException('itemCode required.');
                }
                
                p.Item_No__c = jsonObj.itemCode;
                
                // Set all fields
                if(String.isNotBlank(jsonObj.Name)) p.Name = jsonObj.Name;
                if(String.isNotBlank(jsonObj.itemDescription)) p.Description = jsonObj.itemDescription;
                if(String.isNotBlank(jsonObj.ciNo)) p.CI_no__c = jsonObj.ciNo;
                if(String.isNotBlank(jsonObj.application)) p.Application__c = jsonObj.application;
                if(String.isNotBlank(jsonObj.unit)) p.Unit__c = jsonObj.unit;
                if(String.isNotBlank(jsonObj.family)) p.Family = jsonObj.family;
                if(String.isNotBlank(jsonObj.segment)) p.Product_Segments__c = jsonObj.segment;
                p.IsActive = true;
                
                upsertProductList.add(p);
            }
            
            System.debug('Total products to upsert: ' + upsertProductList.size());
            upsert upsertProductList;

            responseMap.put('status', 'success');
            responseMap.put('message', 'Inserted/Updated Successfully');


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
            errorResMap.put('message', e.getlineNumber() +' || '+e.getMessage());

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

    public class JSON2ApexSaveWebToLead {
        public String Name;
        public String sfprodid;
        public String itemCode;
        public String itemDescription;
        public String ciNo;
        public String application;
        public String unit;
        public String family;
        public String segment;
        public String isActive;
    }

    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead >) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead >.class);
    }

}