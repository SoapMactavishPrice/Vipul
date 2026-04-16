@IsTest
public class CompanyBankHandlerTest {
    
    @IsTest
    static void testUpdateBankAddresses() {
        
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
        
        Company_Name__c comName = new Company_Name__c(Name = 'Vipul Organics Limited');
        insert comName;

        Company_Bank__c accountWithPostalCode = new Company_Bank__c(
            Name = 'Account with Postal Code',
            Pin_Code__c = postalCode.Id,
            Company_Information__c = comName.id
            
        );
        Company_Bank__c accountWithArea = new Company_Bank__c(
            Name = 'Account with Area',
            Area__c = area.Id,
            Company_Information__c = comName.id
        );
        Company_Bank__c accountWithCity = new Company_Bank__c(
            Name = 'Account with City',
            City__c = city.Id,
            Company_Information__c = comName.id
        );
        Company_Bank__c accountWithState = new Company_Bank__c(
            Name = 'Account with State',
            State__c = state.Id,
            Company_Information__c = comName.id
        );
        
        Company_Bank__c companyName = new Company_Bank__c(
            Name = 'Vipul Organics Limited',
            Company_Information__c = comName.id
        );

        insert new List<Company_Bank__c> { accountWithPostalCode, accountWithArea, accountWithCity, accountWithState, companyName };
            
        List<Company_Bank__c> accounts = [SELECT Id, Name, Pin_Code__c, Area__c, City__c, State__c, Country__c FROM Company_Bank__c];
        
        Test.startTest();
        CompanyBankHandler.updateBankAddresses(accounts);
        Test.stopTest();


    }

}