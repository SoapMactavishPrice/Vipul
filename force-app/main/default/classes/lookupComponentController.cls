public class lookupComponentController {
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> findRecords(
        String indusId,
        String deptId,
        String searchKey,
        String objectName,
        String recdataid,
        String returnFields,
        List<String> queryFields,
        String displayFields,
        String filter,
        String sortColumn,
        String maxResults,
        Boolean searchWithMiddle,
        String family
    ) {
        String a = '';
        if (returnFields != null && returnFields.trim() != '') {
            a = returnFields;
        }
        if (displayFields != null && displayFields.trim() != '') {
            a = (a == '' ? displayFields : a + ',' + displayFields);
        }
        
        Set<String> b = new Set<String>();
        String col = '';
        if (a.trim() != '') {
            for (String t : a.split(',')) {
                b.add(t.trim());
            }
            for (String t : b) {
                col = col + ',' + t;
            }
        }
        
        String searchText = '\'%' + searchKey + '%\'';
        
        String vQuery = '';
        
        if (objectName == 'Product2') {
            // Start the query and enforce Product2.IsActive = true
            vQuery = 'SELECT Id, Name, Family' + col + ' FROM Product2 WHERE IsActive = true';
            
            if (String.isNotBlank(searchKey)) {
                vQuery += ' AND (Name LIKE ' + searchText + ' OR ProductCode LIKE ' + searchText + ')';
            }
            
            if (String.isNotBlank(family)) {
                vQuery += ' AND Family = \'' + family + '\'';
            }
            
            if (filter != null && filter != '') {
                vQuery += ' AND (' + filter + ')';
            }
            
            if (sortColumn != null && sortColumn != '') {
                vQuery += ' ORDER BY ' + sortColumn;
            }
        } else {
            // For other objects, keep existing behavior
            vQuery = 'SELECT Id, Name' + col + ' FROM ' + objectName;
            if (String.isNotBlank(searchKey)) {
                vQuery += ' WHERE Name LIKE ' + searchText;
            }
            if (String.isNotBlank(filter)) {
                vQuery += ' AND (' + filter + ')';
            }
            if (sortColumn != null && sortColumn != '') {
                vQuery += ' ORDER BY ' + sortColumn;
            }
        }
        
        System.debug('SOQL Query: ' + vQuery);
        
        List<SObject> returnList = Database.query(vQuery);
        return returnList;
    }

    
    @AuraEnabled
    public static sObject fetchDefaultRecord(string recordId , string sObjectApiName, string returnFields) {
        string sRecId = recordId;
        
        if (returnFields != null && returnFields != '') {
            returnFields = ',' + returnFields;
        } else {
            returnFields = '';
        }
        
        string sQuery = 'Select Id,Name ,Family'+ returnFields + ' From ' + sObjectApiName + ' Where Id = : sRecId LIMIT 1';
        system.debug('sQuery'+sQuery);
        for (sObject obj: database.query(sQuery)) {
            return obj;
        }
        return null;
    }
    
    
    
    public class Wrapper{
        public string Id;
        public string Name;
        public string productCode;
    }
    
}