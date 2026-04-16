public class UtilityCls {


    
    public static Map<String, String> mapGstType =  new Map<String, String>{
        '1' => 'Regular/TDS/ISD', 
        '2' => 'Causual Taxable Person', 
        '3' => 'Composition Levy',
        '4' => 'Government Department or PSU',
        '5' => 'Non Resident Taxable Person',
        '6' => 'UN Agency or Embassy'
        };
    public static Map<String, String> mapDiscountGrp = new Map<String, String>{
        'L' => 'Lowest Discount', 
        'H' => 'Highest Discount', 
        'A' => 'Average',
        'S' => 'Total',
        'M' => 'Discount Multiple'
    };
    public static Map<String, String> mapEffecGrp = new Map<String, String>{
          'D' => 'Default Priority', 
          'L' => 'Lowest Price', 
          'H' => 'Highest Price'

    };
    //public static Map<String, String> mapGstType = new Map<String, String>();    
    
     public static Map < String, String > getAllFields(String sobjectname) {
        if (!Schema.getGlobalDescribe().containsKey(sobjectname)) return new Map < String, String > {
            'Exception' => 'Invalid object name'
        };
        Map < String, Schema.SObjectField > fields = Schema.getGlobalDescribe().get(sobjectname).getDescribe().SObjectType.getDescribe().fields.getMap();

        List < String > accessiblefields = new List < String > ();

        for (Schema.SObjectField field: fields.values()) {
            if (field.getDescribe().isAccessible())
                accessiblefields.add(field.getDescribe().getName());
        }

        String allfields = '';

        for (String fieldname: accessiblefields)
            allfields += fieldname + ',';

        allfields = allfields.subString(0, allfields.length() - 1);

        return new Map < String, String > {
            sobjectname => allfields
        };
    } 



    public static Map<string,string>  query(List<SObject>  SObjectList,Schema.DescribeFieldResult dfr ){
        Map<string,string>  rmap = new Map<string,string>();
        
                        System.debug('Object msg=' + SObjectList.size());
                       // Schema.DescribeFieldResult dfr = Schema.sObjectType.Item_Group_Master__c.fields.Id;
                       
                        Schema.sObjectField T = dfr.getSObjectField();
                        Database.UpsertResult[] srList = Database.upsert(SObjectList, T, false);
                        string error_msg='';
                       // Database.upsert(List<SObject> sobjects, Schema.field, allOrNothing)
                        // Iterate through each returned result
                        rmap.put('code','200');
                        for (Integer i = 0; i < srList.size(); i++) {
                            if (!srList[i].isSuccess()) {
                                for (Database.Error err: srList[i].getErrors()) {
                                    error_msg = error_msg + 'The following error has occurred1' + err.getStatusCode() + ': ' + err.getMessage() + 'Fields that affected this error: ' + err.getFields();
                                    System.debug('The following error has occurred. 1===' + error_msg);
                                   rmap.put('code','0');
                                    
                            if (err instanceof Database.DuplicateError) {
         						Database.DuplicateError duplicateError = (Database.DuplicateError)err;
         						Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                                System.debug('System ==='+duplicateResult.getErrorMessage());

         
                           
                                     }
                                    
                                    
                                 //===========================   
                                }
                                system.debug(SObjectList[i].Id);
                            }
                         }
                       rmap.put('error',error_msg);
                       
        return rmap;
    } 

     public static  Map<String, Pricebook2>  getPriceList(){
          List<Pricebook2> pr2 = new List<Pricebook2>();
                  Map < String, String > s3 = UtilityCls.getAllFields('Pricebook2');
                  
                  String query3 = 'Select ' + s3.get('Pricebook2') + '  from Pricebook2 ';
                  pr2 = database.query(query3);
                  Map<String, Pricebook2> mapP2 = new Map<String, Pricebook2>();
                  for (Pricebook2 p: pr2) {
                      //mapP2.put(p.Price_List_Code__c,p);
                  }
          return mapP2;
     }


      public static Date getDateFormate(String dstr){
          
          if(dstr.length()==8){
                String yearStr = dstr.substring(0, 4);
                String monthStr = dstr.substring(4, 6);
                 String dateStr = dstr.substring(6, 8);
                 return date.parse(monthStr+'/'+dateStr+'/'+yearStr);
          }
          return null;
    }



}