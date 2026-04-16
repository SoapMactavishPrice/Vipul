@IsTest
public class CompanyNameHandlerTest {
    
    @IsTest
    static void testUpdateCompanyAddresses() {
        
        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c state = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert state;
        
        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;
        
        Area__c area = new Area__c(Name = 'Test Area', City__c = city.Id);
        insert area;
        
        Pin_Code__c postalCode = new Pin_Code__c(Name = '12345', Area__c = area.Id);
        insert postalCode;

        Company_Name__c accountWithPostalCode = new Company_Name__c(
            Name = 'Account with Postal Code',
            Pin_Code__c = postalCode.Id
        );
        Company_Name__c accountWithArea = new Company_Name__c(
            Name = 'Account with Area',
            Area__c = area.Id
        );
        Company_Name__c accountWithCity = new Company_Name__c(
            Name = 'Account with City',
            City__c = city.Id
        );
        Company_Name__c accountWithState = new Company_Name__c(
            Name = 'Account with State',
            State__c = state.Id
        );

        insert new List<Company_Name__c> { accountWithPostalCode, accountWithArea, accountWithCity, accountWithState };
            
        List<Company_Name__c> accounts = [SELECT Id, Name, Pin_Code__c, Area__c, City__c, State__c, Country__c FROM Company_Name__c];
        
        Test.startTest();
        CompanyNameHandler.updateComNameAddresses(accounts);
        Test.stopTest();


    }

}