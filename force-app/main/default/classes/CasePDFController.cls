// Apex Controller Variable Declarations
public class CasePDFController {
    public Case caseRecord{ get; set; }
    public Datetime createdDate {get;set;}
    public Date correctiveImpDate {get;set;}
    public Date correctiveComDate {get;set;}
    public Date preventiveImpDate {get;set;}
    public Date preventiveComDate {get;set;}
    
    // Constructor to load Case by Id
    public CasePDFController() {
        Id caseId = ApexPages.currentPage().getParameters().get('id');
        
        if (caseId == null) {
            caseId = '5007100000FxX4EAAV';
        }
        
        if (caseId != null) {
            caseRecord = [SELECT AccountId, AssetId, BusinessHoursId, Case_Comments__c, CurrencyIsoCode, CaseNumber, Origin, Reason, SourceId, IsClosedOnCreate,
                          Comments, ContactEmail, ContactFax, ContactMobile, ContactId, ContactPhone, Corrective_Description__c, CreatedById, Date_Completed__c, 
                          Date_Completed_Prevent__c, Date_Implemented_Prevent__c, Date_Implemented__c, ClosedDate, CreatedDate, Description_Prevent__c, Description, OwnerId, 
                          IsEscalated, Expected_Date__c, Genuine_Complaint_Remark__c, Genuine_Complaint__c, Impact__c, LastModifiedById, Management_Comments__c, Order__c, 
                          Order_Product__c, Order_Remark__c, Others_Types_of_Complaint__c, ParentId, Person_Attendee__c,  Person_Responsible__c, Person_Responsible_Prevent__c,  
                          Plant__c,  Priority, Product__c, Reference_Lot_No__c, Responsible_Person__c, Root_Cause__c, Status, Subject, Target_Closing_Date_for_the_Deviation__c,
                          Type,  Types_of_Complaint__c, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, Owner.Name, Parent.CaseNumber, Additional_Comments__c, Account.Name
                          FROM Case
                          WHERE Id = :caseId
                          LIMIT 1
                         ];
        } else {
            caseRecord = new Case(); 
        }
        
        createdDate = caseRecord.CreatedDate;
        correctiveImpDate = caseRecord.Date_Implemented__c;
        correctiveComDate = caseRecord.Date_Completed__c;
        preventiveImpDate = caseRecord.Date_Implemented_Prevent__c;
        preventiveComDate = caseRecord.Date_Completed_Prevent__c;
        
    }
}