import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentUserName from '@salesforce/apex/MarketingForm.getCurrentUserName';
import getAccounts from '@salesforce/apex/MarketingForm.getAccounts';
import getUsers from '@salesforce/apex/MarketingForm.getUsers';
import getCountries from '@salesforce/apex/MarketingForm.getCountries';
import createOpportunityRecord from '@salesforce/apex/MarketingForm.createOpportunityRecord';
// import saveProductInterested from '@salesforce/apex/MarketingForm.saveProductInterested';
import getPicklistValues from '@salesforce/apex/MarketingForm.getPicklistValues';
import getExistingProducts from '@salesforce/apex/MarketingForm.getExistingProducts';
import createLeadRecord from '@salesforce/apex/MarketingForm.createLeadRecord';
import getAccountCurrency from '@salesforce/apex/MarketingForm.getAccountCurrency';
import getPinCodeDetails from '@salesforce/apex/MarketingForm.getPinCodeDetails';
import getaccountdetails from '@salesforce/apex/MarketingForm.getaccountdetails';
import findRecentPrices from '@salesforce/apex/MarketingForm.findRecentPrices';
import fetchListPrice from '@salesforce/apex/MarketingForm.fetchListPrice';
import getUserInfoWithLeadType from '@salesforce/apex/MarketingForm.getUserInfoWithLeadType';
//import getCompanyBusinessOptions from '@salesforce/apex/MarketingForm.getCompanyBusinessOptions';
import getPicklistValue from '@salesforce/apex/MarketingForm.getPicklistValue';
//import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';


import fetchCI from '@salesforce/apex/MarketingForm.fetchCI';






export default class MarketingForm extends NavigationMixin(LightningElement) {
    //export default class MarketingForm extends LightningElement {
    filledByName = ''; // To store the current user name
    filledByID = ''; // To store the current user ID
    opportunityName = '';
    closeDate = '';
    enquiryMode = ''; // No default value, will show "None"
    enquiryType = ''; // No default value, will show "None"
    customerType = ''; // No default value, will show "None"
    rating = '';
    accountId = '';
    whoWillAttend = '';
    description = '';

    countryId = ''; // No default value, will show "None"
    countryId1 = '';
    @track optionsPackaging = [];
    @track exhibitionName;
    @track currencyfilter;
    @api filter;

    accountOptions = [];
    userOptions = [];
    countryOptions = [];
    incoTermsOptions = [];
    @track incoTerms = '';
    @track stage = '';
    @track accountCurrency = '';
    @track cityId = '';
    @track accountId = '';
    @track enquiryType1 = '';
    @track isFreightEditable = 'true';

    @track lastFivePrices = []; // Array to store last 5 prices
    @track optionsProductFamily = []; // Options for product families

    isModalOpen = false;  // Controls modal visibility
    lastFivePrices = [];  // Stores the last 5 prices

    leadName = '';
    isLeadNameEmpty = false;
    isemailEmpty = false;
    iscompanyNameEmpty = false;
    ismobileEmpty = false;
    isphoneEmpty = false;
    iscountryEmpty = false;
    isstateEmpty = false;
    iscityEmpty = false;
    iscurrencyEmpty = false;
    isratingEmpty = false;
    @track hasInteracted = false;
    @track userId;
    @track isLeadTypeEnabled = false;

    fname = '';
    companyName = '';
    leadSource = '';
    enquiryMode = '';
    customerType = '';
    description = '';
    countryId = '';
    assignedTo = '';
    email = '';
    phone = '';
    street = '';
    areaId = '';
    cityId = '';
    stateId = '';
    istateId = '';
    pincode = '';
    territory = '';
    optionsTerritory = [];
    @track optionsleadcurrency = [];
    leadcurrency = 'INR';
    department = '';
    salutation = '';
    designation = '';
    custtype = '';
    phone1 = '';
    // @track combusiness = [];  // Initialize combusiness as an array
    @track companyBusinessOptions = [];  // Initialize options array

    js = '';

    enquiryType1;  // This holds the selected Enquiry Type
    incoTerms;  // This holds the selected Incoterm
    optionsenquirytype = [];  // Will hold the options for Enquiry Type picklist
    optionsincoTerms = [];  // Will hold the filtered options for Incoterms picklist


    // Example data for Enquiry Type and Incoterms
    data = [
        { field: 'Lead_Type__c', label: 'Domestic', value: 'Domestic' },
        { field: 'Lead_Type__c', label: 'International', value: 'International' },
        { field: 'Inco_Terms__c', label: 'EXW', value: 'EXW' },
        { field: 'Inco_Terms__c', label: 'EX BHIWANDI', value: 'EX BHIWANDI' },
        { field: 'Inco_Terms__c', label: 'EX AMBERNATH', value: 'EX AMBERNATH' },
        { field: 'Inco_Terms__c', label: 'FCA', value: 'FCA' },
        { field: 'Inco_Terms__c', label: 'FOB', value: 'FOB' },
        { field: 'Inco_Terms__c', label: 'CFR', value: 'CFR' },
        { field: 'Inco_Terms__c', label: 'CIF', value: 'CIF' },
        { field: 'Inco_Terms__c', label: 'CPT', value: 'CPT' },
        { field: 'Inco_Terms__c', label: 'CIP', value: 'CIP' },
        { field: 'Inco_Terms__c', label: 'DAP', value: 'DAP' },
        { field: 'Inco_Terms__c', label: 'DDP', value: 'DDP' }
    ];

    @track customerTypeOptions = [];
    @track companyBusinessOptions = [];
    @wire(getPicklistValue)
    wiredPicklistValues({ error, data }) {
        if (data) {
            console.log('data-->>', data);
            this.customerTypeOptions = data.customerType;
            console.log('customerTypeOptions-->>', this.customerTypeOptions);

            this.companyBusinessOptions = data.companyBusiness;
            console.log('companyBusinessOptions-->>', this.companyBusinessOptions);

        } else if (error) {
            this.showToast('Error', 'Failed to fetch picklist values', 'error');
            console.error(error);
        }
    }


    // Update Incoterms options based on selected Enquiry Type
    // updateIncoTermsOptions() {
    //     if (this.territory === 'Domestic') {
    //         // Show only EX BHIWANDI and EX AMBERNATH for Domestic
    //         this.optionsincoTerms = this.data.filter(item => item.field === 'Inco_Terms__c' &&
    //             (item.value === 'EX BHIWANDI' || item.value === 'EX AMBERNATH' || item.value === 'DDP' || item.value === 'EXW'))
    //             .map(item => ({
    //                 label: item.label,
    //                 value: item.value
    //             }));
    //     } else {
    //         // Hide EX BHIWANDI and EX AMBERNATH, show other options for International or other values
    //         this.optionsincoTerms = this.data.filter(item => item.field === 'Inco_Terms__c' &&
    //             item.value !== 'EX BHIWANDI' &&
    //             item.value !== 'EX AMBERNATH')
    //             .map(item => ({
    //                 label: item.label,
    //                 value: item.value
    //             }));
    //     }
    // }
    updateIncoTermsOptions(territory) {
        if (!this.data) return;

        if (territory === 'Domestic') {
            // Show only specific values for Domestic
            this.optionsincoTerms = this.data.filter(item =>
                item.field === 'Inco_Terms__c' &&
                ['EX BHIWANDI', 'EX AMBERNATH', 'DDP', 'EXW'].includes(item.value)
            ).map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (territory === 'International') {
            // Exclude domestic-specific values
            this.optionsincoTerms = this.data.filter(item =>
                item.field === 'Inco_Terms__c' &&
                !['EX BHIWANDI', 'EX AMBERNATH'].includes(item.value)
            ).map(item => ({
                label: item.label,
                value: item.value
            }));
        } else {
            // Optional: handle "Both" or other values if needed
            this.optionsincoTerms = this.data.filter(item =>
                item.field === 'Inco_Terms__c'
            ).map(item => ({
                label: item.label,
                value: item.value
            }));
        }
    }



    get isTerritoryDomestic() {
        return this.territory === 'Domestic';
    }



    validateLeadForm() {
        // Set the flag to true when the user interacts with the form
        this.hasInteracted = true;

        // Start by assuming the form is valid
        this.isValid = true;

        // Validate Lead Name
        this.isLeadNameEmpty = this.leadName.trim() === '';
        if (this.isLeadNameEmpty) {
            this.isValid = false;
            // return false;
        }

        // Email Validation
        this.isemailEmpty = this.email.trim() === '';
        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        this.isemailInvalid = !emailPattern.test(this.email);
        if (this.isemailEmpty || this.isemailInvalid) {
            this.isValid = false;
        }

        // Mobile Validation
        this.ismobileEmpty = !this.phone || this.phone.trim() === '';
        if (this.ismobileEmpty) {
            this.isValid = false;
        }

        this.isphoneEmpty = !this.phone1 || this.phone1.trim() === '';
        if (this.isphoneEmpty) {
            this.isValid = false;
        }

        this.iscurrencyEmpty = !this.leadcurrency || this.leadcurrency.trim() === '';
        if (this.iscurrencyEmpty) {
            this.isValid = false;
        }

        // this.isratingEmpty = !this.rating || this.rating.trim() === '';
        // if (this.isratingEmpty) {
        //     this.isValid = false;
        // }

        // Company Name Validation
        this.iscompanyNameEmpty = this.companyName.trim() === '';
        if (this.iscompanyNameEmpty) {
            this.isValid = false;
        }

        // Country Validation
        this.iscountryEmpty = !this.countryId || this.countryId.trim() === '';
        if (this.iscountryEmpty) {
            this.isValid = false;
        }

        // City and State Validation for Domestic territory
        if (this.territory === 'Domestic') {
            this.iscityEmpty = !this.cityId || this.cityId.trim() === '';
            this.isstateEmpty = !this.stateId || this.stateId.trim() === '';

            if (this.iscityEmpty || this.isstateEmpty) {
                this.isValid = false;
            }
        }

    }



    get isCityRequiredForDomestic() {
        return this.hasInteracted && this.territory === 'Domestic' && (!this.cityId || this.cityId.trim() === '');
    }

    get isStateRequiredForDomestic() {
        return this.hasInteracted && this.territory === 'Domestic' && (!this.stateId || this.stateId.trim() === '');
    }


    getInputClass(field) {
        switch (field) {
            case 'leadName':
                return this.isLeadNameEmpty ? 'slds-has-error' : '';
            case 'email':
                return this.isemailEmpty || this.isemailInvalid ? 'slds-has-error' : '';
            case 'companyName':
                return this.iscompanyNameEmpty ? 'slds-has-error' : '';
            case 'countryId':
                return this.iscountryEmpty ? 'slds-has-error' : '';
            case 'stateId':
                return this.isStateRequiredForDomestic ? 'slds-has-error' : '';
            case 'cityId':
                return this.isCityRequiredForDomestic ? 'slds-has-error' : '';
            case 'phone':
                return this.ismobileEmpty ? 'slds-has-error' : '';
            case 'phone1':
                return this.isphoneEmpty ? 'slds-has-error' : '';
            case 'leadcurrency':
                return this.iscurrencyEmpty ? 'slds-has-error' : '';
            // case 'rating':
            //     return this.isratingEmpty ? 'slds-has-error' : '';
            default:
                return '';
        }
    }

    get showExhibitionField() {
        return this.leadSource === 'Exhibition';
    }



    // Handle input changes for lead fields
    handleLeadInputChange(event) {

        const field = event.target.dataset.id;
        if (field === 'leadName') {
            this.leadName = event.target.value;
            // if (this.leadName == '') {
            //     this.validateLeadForm();
            // }
        } else if (field === 'fname') {
            this.fname = event.target.value;
        } else if (field === 'companyName') {
            this.companyName = event.target.value;
            //   this.validateLeadForm();
        } else if (field === 'leadSource') {
            this.leadSource = event.target.value;
        }

        else if (field === 'exhibitionName') {
            this.exhibitionName = event.target.value;
        }


        else if (field === 'enquiryMode') {
            this.enquiryMode = event.target.value;
        } else if (field === 'customerType') {
            this.customerType = event.target.value;
        } else if (field === 'description') {
            this.description = event.target.value;
        } else if (field === 'countryId') {
            this.countryId = event.detail.recordId;
            //    this.validateLeadForm();
        } else if (field === 'assignedTo') {
            this.assignedTo = event.target.value;
        } else if (field === 'email') {
            this.email = event.target.value;
            //   this.validateLeadForm();
        } else if (field === 'phone') {
            this.phone = event.target.value;
            //   this.validateLeadForm();
        } else if (field === 'street') {
            this.street = event.target.value;
        } else if (field === 'areaId') {
            this.areaId = event.detail.recordId;
        } else if (field === 'cityId') {
            this.cityId = event.detail.recordId;
            // this.validateLeadForm();
        } else if (field === 'stateId') {
            this.stateId = event.detail.recordId;
            //  this.validateLeadForm();
        } else if (field === 'pincode') {
            this.pincode = event.detail.recordId;
            console.log('event.detail.recordId', event.detail.recordId);
            this.currentPinCodeId = event.detail.recordId;
            if (this.currentPinCodeId != '' && this.currentPinCodeId != null) {
                this.getPinCode();
            } else if (this.currentPinCodeId == null) {


                this.cityId = null;
                this.areaId = null;
                this.stateId = null;
                this.countryId = null;
                console.log('-else ->', this.cityId);
            }

        } else if (field === 'territory') {
            this.territory = event.target.value;
            this.updateIncoTermsOptions();
        }
        else if (field === 'leadcurrency') {
            this.leadcurrency = event.target.value;
            //   this.validateLeadForm();
        }
        else if (field === 'phone1') {
            this.phone1 = event.target.value;
        }

        else if (field === 'salutation') {
            this.salutation = event.target.value;
        }

        else if (field === 'designation') {
            this.designation = event.target.value;
        }

        else if (field === 'custtype') {
            this.custtype = event.target.value;
        }
        else if (field === 'rating') {
            this.rating = event.target.value;
            this.updateIncoTermsOptions();
        }

        // else if (field === 'combusiness') {
        //     this.combusiness = event.detail.value.join(', ');
        //     console.log('Selected Company Business:', this.combusiness);

        // }
        this.updateCurrencyOptions(this.territory);
        this.updateIncoTermsOptions(this.territory);

        let value = event.target.value;

        if (field === 'leadcurrency') {
            // Update the currencyfilter used in lookup components
            this.currencyfilter = `Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '${value}')`;
        }
    }
    @track allValues = [];
    @track selectedCustomerTypes = [];
    @track company_business = [];





    handleCompanyBusiness(event) {
        this.company_business = event.detail.value;
        console.log('this.company_business', this.company_business);

        this.addValue(this.company_business);
    }

    addValue(value) {
        if (value && !this.allValues.includes(value)) {
            this.allValues = [...this.allValues, value];
            console.log('this.allValues', this.allValues);

        }
    }

    handleRemove(event) {
        const valueToRemove = event.detail.name;
        this.allValues = this.allValues.filter(val => val !== valueToRemove);
        console.log('this.allValues2', this.allValues);

    }

    handleCustomerType(event) {
        this.customer_type = event.detail.value;
        console.log('this.customer_type', this.customer_type);

        this.addCustomerType(this.customer_type);
    }

    addCustomerType(type) {
        if (type && !this.selectedCustomerTypes.includes(type)) {
            this.selectedCustomerTypes = [...this.selectedCustomerTypes, type];
        }
    }

    handleRemoveCustomerType(event) {
        const typeToRemove = event.detail.name;
        this.selectedCustomerTypes = this.selectedCustomerTypes.filter(
            (type) => type !== typeToRemove
        );
        console.log('this.selectedCustomerTypes', this.selectedCustomerTypes);
    }


    // Set leadcurrency based on customerType (lead type)
    get leadcurrency() {
        // Default to INR if customerType is Domestic, otherwise return the selected currency
        return this._leadcurrency || (this.customerType === 'Domestic' ? 'INR' : '');
    }

    set leadcurrency(value) {
        this._leadcurrency = value;
    }

    createLead() {
        // Set leadcurrency to INR if customerType is Domestic, else use the existing leadcurrency
        let leadcurrency = this.customerType === 'Domestic' ? 'INR' : this.leadcurrency;



        let Product_Interested__c = this.addAnswer.map(item => ({
            prodFamily: item.prodFamily,
            prodId: item.prodId,
            prodName: item.prodName,
            prodCode: item.prodCode,
            volume: item.volume,
            price: item.price,
            quality: item.quality,
            packaging: item.packaging,
            CommissionType: item.CommissionType,
            CIN: item.CIN,
            New_Product__c: item.New_Product__c,
            New_Product_Name__c: item.New_Product_Name__c,
            New_Product_CI_No__c: item.New_Product_CI_No__c
        }));

        const js = JSON.stringify(Product_Interested__c);
        console.log('js', js);


        if (!this.leadName) {
            this.validateLeadForm();
            return;
        }

        if (!this.companyName) {
            this.validateLeadForm();
            return;
        }

        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

        // let validate = this.validateData(); // This is where the validation now happens before save
        // if (!validate) {
        //     console.log('Validation failed');
        //     return;
        // }

        if (!this.email || !emailPattern.test(this.email)) {
            this.validateLeadForm();
            return;
        }

        if (!this.phone) {
            this.validateLeadForm();
            return;
        }

        if (!this.countryId) {
            this.validateLeadForm();
            return;
        }

        if (!this.countryId) {
            this.leadcurrency();
            return;
        }

        // if (!this.rating) {
        //     this.validateLeadForm();
        //     return;
        // }

        if (this.territory === 'Domestic') {

            if (!this.stateId) {
                this.validateLeadForm();
                return;
            }


            if (!this.cityId) {
                this.validateLeadForm();
                return;
            }
        }

        createLeadRecord({
            leadName: this.leadName,
            fname: this.fname,
            companyName: this.companyName,
            leadSource: this.leadSource,
            customerType: this.customerType,
            description: this.description,
            countryId: this.countryId,
            email: this.email,
            phone: this.phone,
            street: this.street,
            areaId: this.areaId,
            cityId: this.cityId,
            stateId: this.stateId,
            istateId: this.istateId,
            pincode: this.pincode,
            territory: this.territory,
            phone1: this.phone1,
            salutation: this.salutation,
            designation: this.designation,
            custtype: this.custtype,
            rating: this.rating,
            company_business: this.allValues,
            exhibitionName: this.exhibitionName,


            //  combusiness: this.combusiness,

            leadcurrency: leadcurrency,  // Use the default INR if Domestic, otherwise use provided value
            js: js
        })
            .then(result => {
                this.showToast('Success', 'Lead created successfully', 'success');
                //  location.reload();
                console.log('result', result);


                // Navigate to the created Opportunity record page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,  // Use the Opportunity Id returned by the Apex method
                        objectApiName: 'Lead',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Error', 'Error creating lead: ' + error.body.message, 'error');
            });
    }




    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    // Enquiry Mode Options with "None"
    enquiryModeOptions = [
        { label: 'None', value: '' }, // Default empty value for "None"
        { label: 'Website', value: 'Website' },
        { label: 'Direct', value: 'Direct' },
        { label: 'Employee Referral', value: 'Employee Referral' },
        { label: 'Customer Reference', value: 'RefeCustomer Referencerral' },
        { label: 'Email', value: 'Email' },
        { label: 'Exhibition', value: 'Exhibition' },
        { label: 'Linkedin', value: 'Linkedin' },
        { label: 'Google search', value: 'Google search' },
        { label: 'Others', value: 'Others' },
    ];


    // Enquiry Type Options with "None"
    enquiryTypeOptions = [
        // { label: 'None', value: '' }, // Default empty value for "None"
        { label: 'Lead', value: 'Lead' },
        { label: 'Enquiry', value: 'Opportunity' },
    ];

    // Customer Type Options with "None"
    customerTypeOptions = [
        { label: 'None', value: '' }, // Default empty value for "None"
        { label: 'Old', value: 'Old' },
        { label: 'New', value: 'New' },
    ];


    // Wire to fetch current user's name
    @wire(getCurrentUserName)
    currentUserName({ data, error }) {
        if (data) {
            console.log('getCurrentUserName', JSON.stringify(data));
            this.filledByName = data.Name; // Store the logged-in user's name
            this.filledByID = data.Id; // Store the logged-in user's id
        } else if (error) {
            console.error('Error fetching user name: ', error);
        }
    }

    // Wire to fetch Accounts for Client Name
    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            this.accountOptions = data.map(account => ({
                label: account.Name,
                value: account.Id
            }));
        } else if (error) {
            console.error('Error fetching accounts: ', error);
        }
    }


    @wire(getAccountCurrency, { accountId: '$accountId' })
    wiredAccountCurrency({ data, error }) {
        if (data) {
            // Set the currency of the selected account
            this.accountCurrency = data;
            this.countryId1 = data;
        } else if (error) {

        }
    }



    @track currentPinCodeId = '';
    getPinCode() {
        getPinCodeDetails({ pincode: this.currentPinCodeId }).then(result => {
            let data = JSON.parse(result);
            this.cityId = data.cityId;
            this.areaId = data.areaId;
            this.stateId = data.stateId;
            this.countryId = data.countryId;


        })
    }

    @track currentaccountId = '';
    getAccCode() {
        getaccountdetails({ account: this.currentaccountId }).then(result => {
            let data = JSON.parse(result);

            this.countryId1 = data.countryId1;


        })
    }


    // Wire to fetch Users for "Who will attend"
    @wire(getUsers)
    wiredUsers({ data, error }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        } else if (error) {
            console.error('Error fetching users: ', error);
        }
    }

    // Wire to fetch Country options
    @wire(getCountries)
    wiredCountries({ data, error }) {
        if (data) {
            this.countryOptions = data.map(country => ({
                label: country.Name,
                value: country.Id
            }));
        } else if (error) {
            console.error('Error fetching countries: ', error);
        }
    }

    get enquiryTypeIsEnquiry() {
        return this.enquiryType === 'Opportunity'; // Assuming "Opportunity" is the label for "Enquiry"
    }

    get enquiryTypeIsLead() {
        return this.enquiryType === 'Lead'; // Assuming "Lead" is the label for "Enquiry"
    }



    handleShowPricesClick() {
        console.log('Selected Account ID:', this.accountId);

        if (this.accountId && this.addAnswer && this.addAnswer.length > 0) {
            this.addAnswer.forEach(answer => {
                if (answer.prodId) {
                    console.log(`Fetching prices for Product ID: ${answer.prodId}`);
                    this.fetchLastFivePrices(this.accountId, answer.prodId);
                } else {
                    console.log('No Product ID found for one of the selected products.');
                }
            });
            this.isModalOpen = true;
        } else {
            console.log('Please select both Account and at least one Product.');
        }
    }

    @track isOpenFileView = false;

    handleClose() {
        this.isOpenFileView = false;  // Close the modal
    }

    fetchLastFivePrices(accountId, productId) {
        findRecentPrices({ accountId: accountId, productId: productId })
            .then(result => {
                this.isOpenFileView = true;
                this.lastFivePrices = result;
                console.log(`Last 5 Prices for Product ID ${productId}:`, this.lastFivePrices);
            })
            .catch(error => {
                console.error(`Error fetching prices for Product ID ${productId}:`, error);
            });
    }




    // Handle input changes
    handleInputChange(event) {
        console.log('field-->', event.target.value);
        console.log('fieldset-->', event.target.recordId);

        const field = event.target.dataset.id;

        if (field === 'opportunityName') {
            this.opportunityName = event.target.value;
        } else if (field === 'enquiryMode') {
            this.enquiryMode = event.target.value;
        } else if (field === 'enquiryType') {
            this.enquiryType = event.target.value;
        } else if (field === 'customerType') {
            this.customerType = event.target.value;
        } else if (field === 'accountId') {
            this.accountId = event.detail.recordId;
            console.log('Selected Account ID:', this.accountId);

            this.currentaccountId = event.detail.recordId;
            if (this.currentaccountId != '' && this.currentaccountId != null) {
                this.getAccCode();
            } else if (this.currentaccountId == null) {
                this.countryId1 = null;
                console.log('-else ->', this.cityId);
            }
        } else if (field === 'whoWillAttend') {
            this.whoWillAttend = event.target.value;
        } else if (field === 'description') {
            this.description = event.target.value;
        } else if (field === 'countryId1') {
            this.countryId1 = event.detail.recordId;
        } else if (field === 'incoTerms') {
            this.incoTerms = event.target.value;
        } else if (field === 'closeDate') {
            this.closeDate = event.target.value; // Store the selected close date
        } else if (field === 'stage') {
            this.stage = event.target.value;
        } else if (field === 'currency') {
            this.accountCurrency = event.target.value;
        } else if (field === 'enquiryType1') {
            this.enquiryType1 = event.target.value;
            this.updateIncoTermsOptions();
        }

        // After the change in Incoterms, handle the Freight Editability
        this.setFreightEditability(0, this.addAnswer[0].listPrice); // Update Freight Editability for the first index
        console.log('this.accountId', event.detail.recordId, event.detail.value);
    }

    // Create Opportunity function
    createOpportunity() {
        const today = new Date();
        const closeDate = new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0];
        const stage = 'New';  // Default stage to 'New'

        let opportunityLineItems = this.addAnswer.map(item => ({



            prodFamily: item.prodFamily,
            prodId: item.prodId,
            prodName: item.prodName,
            prodCode: item.prodCode,
            volume: item.volume,
            price: item.price,
            quality: item.quality,
            packaging: item.packaging,
            CommissionType: item.CommissionType,
            commissionval: item.commissionval,
            commissionper: item.commissionper,
            freightval: item.freightval,
            totalprice: item.totalprice,
            finalprice: item.finalprice
        }));

        // Validate OpportunityLineItems before proceeding
        for (let i = 0; i < opportunityLineItems.length; i++) {
            const item = opportunityLineItems[i];

            // Check if product ID is missing
            if (!item.prodId) {
                this.showToast('Error', `Select Product For Creating Enquiry ${item.prodName}`, 'error');
                return; // Exit the function and don't proceed with the creation
            }

            // Check if price is missing or not a valid decimal
            // if (!item.price || isNaN(item.price) || parseFloat(item.price) <= 0) {
            //     this.showToast('Error', `Valid Sales Price is required for product ${item.prodName}`, 'error');
            //     return; // Exit the function and don't proceed with the creation
            // }

            // Check if volume is missing or not a valid decimal
            // if (!item.volume || isNaN(item.volume) || parseFloat(item.volume) <= 0) {
            //     this.showToast('Error', `Quantity is required for product ${item.prodName}`, 'error');
            //     return; // Exit the function and don't proceed with the creation
            // }




        }

        const JS = JSON.stringify(opportunityLineItems);
        console.log('JS', JS);

        // Call Apex method to create Opportunity record
        createOpportunityRecord({
            opportunityName: this.opportunityName,
            closeDate: closeDate,
            filledBy: this.filledByID, // Use the filledByName for creating opportunity
            enquiryMode: this.enquiryMode,
            enquiryType: this.enquiryType,
            customerType: this.customerType,
            accountId: this.accountId,
            whoWillAttend: this.whoWillAttend,
            countryId1: this.countryId1,
            stage: this.stage,
            incoTerms: this.incoTerms,
            enquiryType1: this.enquiryType1,
            JS: JS
        })
            .then(result => {
                this.showToast('Success', 'Opportunity created successfully', 'success');
                // location.reload();
                console.log('result', result);


                // Navigate to the created Opportunity record page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,  // Use the Opportunity Id returned by the Apex method
                        objectApiName: 'Opportunity',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Error', 'Error creating opportunity: ' + error.body.message, 'error');
            });
    }

    get isCommissionValueDisabled() {
        const answer = this.addAnswer[this.index];
        return answer && answer.CommissionType === 'Percentage';
    }

    get isCommissionPercentageDisabled() {
        const answer = this.addAnswer[this.index];
        return answer && answer.CommissionType === 'Value';
    }



    // handleCommissionTypeChange(event) {
    //     const index = event.target.dataset.index;
    //     const commissionType = event.target.value;

    //     // Ensure the row exists
    //     if (this.addAnswer && this.addAnswer[index]) {
    //         // Update the CommissionType field
    //         this.addAnswer[index].CommissionType = commissionType;

    //         // Recalculate totalprice and finalprice when CommissionType changes
    //         this.calculateTotalAndFinalPrice(index);
    //     }
    // }

    // handleCommissionChange(event) {
    //     const index = event.target.dataset.index;
    //     const field = event.target.dataset.label;  // 'commissionval' or 'commissionper'
    //     const value = parseFloat(event.target.value);

    //     // Ensure that the row exists
    //     if (this.addAnswer && this.addAnswer[index]) {
    //         // Update the value for the changed field (either commissionval or commissionper)
    //         this.addAnswer[index][field] = value;

    //         // Recalculate the totalprice and finalprice after updating commission fields
    //         this.calculateTotalAndFinalPrice(index);
    //     }
    // }



    // calculateTotalAndFinalPrice(index) {
    //     const item = this.addAnswer[index];
    //     const price = item.price;
    //     const quantity = 5; // Fixed quantity
    //     const commissionval = item.commissionval;
    //     const commissionper = item.commissionper;
    //     const freightval = item.freightval;
    //     const commissionType = item.CommissionType;

    //     // Calculate the total price: Price * Quantity
    //     let totalprice = price * quantity;

    //     // If CommissionType is 'Value', add commissionval to totalprice
    //     if (commissionType === 'Value' && !isNaN(commissionval)) {
    //         totalprice += commissionval;
    //     }

    //     // If CommissionType is 'Percentage', add the calculated commission percentage to totalprice
    //     if (commissionType === 'Percentage' && !isNaN(commissionper)) {
    //         const commissionAmount = (totalprice * commissionper) / 100;
    //         totalprice += commissionAmount;
    //     }

    //     // Update the totalprice
    //     item.totalprice = totalprice.toFixed(2);

    //     // Calculate final price = totalprice + freightval
    //     const finalprice = totalprice + (freightval || 0);
    //     item.finalprice = finalprice.toFixed(2);
    //     console.log('finalprice', finalprice);
    //     console.log('item.finalprice', item.finalprice);

    // }


    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    @api recordId;

    @track currencyCode = '';
    optionsProductFamily = [];
    optionsPackaging = [];
    optionsPackaging1 = [];

    // Wire the Apex method to fetch picklist values
    @wire(getPicklistValues)
    wiredPicklist({ error, data }) {
        if (data) {
            // Separate picklist values for Product_Family__c, Packaging__c, Lead_Type__c, and other fields
            this.optionsProductFamily = data.filter(item => item.field === 'Product_Family__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionsPackaging = data.filter(item => item.field === 'Packaging__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionsCommissionType = data.filter(item => item.field === 'Commission_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            // Territory picklist
            this.optionsTerritory = data.filter(item => item.field === 'Lead_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            // // Lead Currency picklist
            // this.optionsleadcurrency = data.filter(item => item.field === 'CurrencyIsoCode').map(item => ({
            //     label: item.label,
            //     value: item.value
            // }));

            // Inco Terms picklist
            this.optionsincoTerms = data.filter(item => item.field === 'Inco_Terms__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            // Stage picklist
            this.optionsstage = data.filter(item => item.field === 'StageName').map(item => ({
                label: item.label,
                value: item.value
            }));

            // Enquiry_Type__c picklist
            this.optionsenquirytype = data.filter(item => item.field === 'Enquiry_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            // Set default territory value to 'Domestic' if available
            if (!this.territory) {
                const defaultTerritory = this.optionsTerritory.find(option => option.value === 'Domestic');
                if (defaultTerritory) {
                    this.territory = 'Domestic';  // Set default territory to Domestic
                }
            }



            this.optionsdepartment = data.filter(item => item.field === 'Department__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionssalutation = data.filter(item => item.field === 'Salutation').map(item => ({
                label: item.label,
                value: item.value
            }));


            this.optionsdesignation = data.filter(item => item.field === 'Job_Title_Designation__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionscusttype = data.filter(item => item.field === 'Customer_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            // this.optionscombusiness = data.filter(item => item.field === 'Company_Business__c').map(item => ({
            //     label: item.label,
            //     value: item.value
            // }));

            this.optionsrating = data.filter(item => item.field === 'Rating').map(item => ({
                label: item.label,
                value: item.value
            }));



            // If you want to check if the territory was set and log it
            console.log('Territory options:', this.optionsTerritory);
            console.log('Default territory value:', this.territory);
        } else if (error) {
            this.showErrorToast(error.body.message);
        }
    }


    @wire(getUserInfoWithLeadType)
    wiredUserInfo({ error, data }) {
        if (data) {
            this.optionsTerritory = data.filteredPicklist;

            const currentUserProfile = data.userInfo.ProfileName;
            const specialProfileName = 'System Administrator';

            // Enable field only if user is a System Administrator
            this.isLeadTypeEnabled = (currentUserProfile === specialProfileName);

            if (this.optionsTerritory.length > 0) {
                const defaultTerritory = this.optionsTerritory.find(option => option.value === 'Domestic');
                if (defaultTerritory) {
                    this.territory = 'Domestic';
                    this.updateCurrencyOptions('Domestic');
                    this.updateIncoTermsOptions('Domestic');
                } else {
                    const fallbackTerritory = this.optionsTerritory.find(option => option.value === 'International');
                    if (fallbackTerritory) {
                        this.territory = 'International';
                        this.updateCurrencyOptions('International');
                        this.updateIncoTermsOptions('International');
                    } else {
                        const bothTerritory = this.optionsTerritory.find(option => option.value === 'Both');
                        if (bothTerritory) {
                            this.territory = 'Both';
                            this.updateCurrencyOptions('Both');
                        }
                    }
                }
            }
        } else if (error) {
            console.error(error);
        }
    }

    get isLeadTypeDisabled() {
        return !this.isLeadTypeEnabled;
    }

    @wire(getPicklistValues, { recordTypeId: '$leadObject.data.defaultRecordTypeId', fieldApiName: CurrencyIsoCode })
    wiredCurrencyIsoCode({ data, error }) {
        if (data) {
            this.optionsleadcurrency = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }


    // Update currency options based on the territory
    updateCurrencyOptions(territoryType) {
        if (territoryType === 'Domestic') {
            // Only show Indian Rupee for Domestic territory
            this.optionsleadcurrency = [
                { label: 'Indian Rupee', value: 'INR' }
            ];
        } else if (territoryType === 'International') {
            // Show other currencies except Indian Rupee for International territory
            this.optionsleadcurrency = [
                { label: 'Indian Rupee', value: 'INR' },
                { label: 'UAE Dirham', value: 'AED' },
                { label: 'Euro', value: 'EUR' },
                { label: 'U.S. Dollar', value: 'USD' }
            ];
        } else if (territoryType === 'Both') {
            // Show all currencies for Both territory
            this.optionsleadcurrency = [
                { label: 'Indian Rupee', value: 'INR' },
                { label: 'UAE Dirham', value: 'AED' },
                { label: 'Euro', value: 'EUR' },
                { label: 'U.S. Dollar', value: 'USD' }
            ];
        }
    }



    @track where = '';
    @track Exist = [];
    getExisting() {
        getExistingProducts({ Id: this.recordId }).then(result => {
            if (result.length > 0) {
                this.Exist = result;
            } else {
                this.Exist = [];
            }

            this.where = `'Id NOT IN : '${this.Exist}'`;
        });
    }


    fetchCIForProduct(productId, index) {
        fetchCI({ productId: productId })
            .then((result) => {
                if (this.addAnswer[index]) {
                    this.addAnswer[index].ciNo = result;  // Update the CI field in the addAnswer array
                }
                console.log('CI number fetched for product:', result);
            })
            .catch((error) => {
                console.error('Error fetching CI_no__c:', error);
            });
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        // The selected product record
        const pbe = selectedRecord;

        // Update addAnswer array for the selected product
        if (this.addAnswer && this.addAnswer[index]) {
            // Assign product details
            this.addAnswer[index] = {
                ...this.addAnswer[index],
                prodId: pbe.Id,
                prodName: pbe.Name,
                prodCode: pbe.ProductCode,
                New_Product__c: false

            };

            this.fetchCIForProduct(selectedRecord.Id, index);

            // Fetch the List Price for the selected product using an Apex call
            this.fetchProductListPrice(pbe.Id, index);
        }

        console.log('Updated Field:', index, this.addAnswer[index]);
    }

    fetchProductListPrice(productId, index) {

        fetchListPrice({ productId: productId })
            .then(result => {

                const listPrice = result !== null ? result : 0;
                this.addAnswer[index].listPrice = listPrice;


                const isDisabled = listPrice === 0;
                this.addAnswer[index].isDisabled = isDisabled;


                console.log(`List Price for product ${productId}: ${listPrice}`);
                console.log(`isDisabled set to: ${isDisabled}`);


                this.setFreightEditability(index, listPrice);
            })
            .catch(error => {
                console.error("Error fetching List Price:", error);
                this.addAnswer[index].listPrice = 0;
                this.addAnswer[index].isDisabled = true;


                this.addAnswer[index].isFreightDisabled = true;


                console.log(`Error in fetching list price for product ${productId}:`, error);
            });
    }

    setFreightEditability(index, listPrice) {
        const answer = this.addAnswer[index];
        let isFreightEditable = false;

        console.log('List Price:', listPrice);
        console.log(`Enquiry Type: ${this.enquiryType1}, Incoterms: ${this.incoTerms}`);

        if (listPrice > 0) {
            // Check the conditions for when Freight should be editable
            if (this.enquiryType1 === 'Domestic' && this.incoTerms === 'DDP') {
                isFreightEditable = true;
                console.log('Freight is editable due to Domestic and DDP');
            } else if (this.enquiryType1 === 'International' &&
                ['CFR', 'CIF', 'CPT', 'CIP', 'DAP', 'DDP'].includes(this.incoTerms)) {
                isFreightEditable = true;
                console.log('Freight is editable due to International and Incoterms:', this.incoTerms);
            }
        }

        // Set the 'isFreightDisabled' property based on whether freight should be editable
        this.addAnswer[index].isFreightDisabled = !isFreightEditable;

        // Log the final state of isFreightDisabled
        console.log(`Freight Disabled status for index ${index}: ${this.addAnswer[index].isFreightDisabled}`);

        // If freight is disabled, reset its value
        if (this.addAnswer[index].isFreightDisabled) {
            this.addAnswer[index].freightval = '';  // Clear the freight value
            console.log('Freight value reset due to Incoterms change');
        }
    }


    handleIncoTermsChange(event) {
        this.incoTerms = event.detail.value; // Update incoTerms with the selected value
        console.log("Incoterms selected:", this.incoTerms); // Log to verify the correct value

        // Now, call the method to check if Freight is editable again after Incoterms is updated
        this.setFreightEditability(event.target.dataset.index, this.addAnswer[event.target.dataset.index].listPrice);
    }






    handleCommissionChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.label;  // 'commissionval' or 'commissionper'
        const value = event.target.value;

        // Ensure that the row exists
        if (this.addAnswer && this.addAnswer[index]) {
            // Update the value for the changed field (either commissionval or commissionper)
            this.addAnswer[index][field] = value;

            // Recalculate the other field if needed
            const price = this.addAnswer[index].price;
            const listPrice = this.addAnswer[index].listPrice;

            if (listPrice > 0 && price > 0) {
                if (field === 'commissionval') {
                    // Recalculate commissionper if commissionval changes
                    const commissionper = ((value / price) * 100).toFixed(2);
                    this.addAnswer[index].commissionper = commissionper;
                } else if (field === 'commissionper') {
                    // Recalculate commissionval if commissionper changes
                    const commissionval = (price * value) / 100;
                    this.addAnswer[index].commissionval = commissionval.toFixed(2);
                }
            }
        }
    }




    @track tempIndex = 0;
    @track addAnswer = [
        {
            index: this.tempIndex,
            prodFamily: '',
            prodId: '',
            prodName: '',
            prodCode: '',
            volume: '',
            price: '',
            quality: '',
            packaging: '',
            CommissionType: '',
            commissionval: '',
            commissionper: '',
            totalprice: '',
            finalprice: '',
            CIN: '',
            New_Product__c: false,
            New_Product_Name__c: '',
            New_Product_CI_No__c: ''
        }
    ];

    connectedCallback() {
        this.getExisting();

        const today = new Date();
        this.closeDate = new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0];  // closeDate + 30 days
        this.stage = 'New';  // Default stage to 'New'
    }

    handleCheckboxChange(event) {
        const index = parseInt(event.target.dataset.index, 10); // Ensure index is a number
        const isChecked = event.target.checked;

        // Create a deep copy of the array to avoid mutation issues
        const updatedAnswers = JSON.parse(JSON.stringify(this.addAnswer));

        // Ensure the index exists in the array
        if (index >= 0 && index < updatedAnswers.length) {
            updatedAnswers[index] = {
                ...updatedAnswers[index],
                New_Product__c: isChecked,
                Add_In_Opty: true,
                prodId: isChecked ? null : updatedAnswers[index].prodId,
                prodName: isChecked ? null : updatedAnswers[index].prodName,
                prodCode: isChecked ? null : updatedAnswers[index].prodCode,
                ciNo: isChecked ? null : updatedAnswers[index].ciNo,
                New_Product_Name__c: isChecked ? updatedAnswers[index].New_Product_Name__c || '' : '',
                New_Product_CI_No__c: isChecked ? updatedAnswers[index].New_Product_CI_No__c || '' : '',
                New_Product_Description__c: isChecked ? updatedAnswers[index].New_Product_Description__c || '' : ''
            };

            // Set the new array (this will trigger reactivity)
            this.addAnswer = updatedAnswers;
        } else {
            console.error('Invalid index in handleCheckboxChange:', index);
        }
    }

    handleTextInputChange(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        const updatedAnswers = [...this.addAnswer];
        updatedAnswers[index] = {
            ...updatedAnswers[index],
            New_Product_Name__c: value
        };
        this.addAnswer = updatedAnswers;

        console.log(`Text input changed at index ${index}, value: ${value}`);
        console.log('Updated addAnswer:', JSON.stringify(this.addAnswer));
    }

    handleCITextInputChange(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        const updatedAnswers = [...this.addAnswer];
        updatedAnswers[index] = {
            ...updatedAnswers[index],
            New_Product_CI_No__c: value
        };
        this.addAnswer = updatedAnswers;

        console.log(`Text input changed at index ${index}, value: ${value}`);
        console.log('Updated addAnswer:', JSON.stringify(this.addAnswer));
    }


    handlePackagingChange(event) {
        const index = event.target.dataset.index;
        const packagingValue = event.detail.value;
        this.addAnswer[index].packaging = packagingValue;
    }

    handleCommissionTypeChange(event) {
        const index = event.target.dataset.index;
        const CommissionTypeValue = event.detail.value;
        this.addAnswer[index].CommissionType = CommissionTypeValue;
    }

    // addAnswerItem() {
    //     //   let validate = this.validateData();


    //     this.tempIndex = this.tempIndex + 1;
    //     const newAnswer = {
    //         index: this.tempIndex,
    //         prodFamily: '',
    //         prodId: '',
    //         prodName: '',
    //         prodCode: '',
    //         volume: '',
    //         price: '',
    //         // packaging: '',
    //         New_Product__c: false,
    //         New_Product_Name__c: ''

    //     };
    //     this.addAnswer.push(newAnswer);

    // }

    addAnswerItem(event) {
        const newAnswer = {
            index: this.addAnswer.length,
            New_Product__c: false,
            Add_In_Opty: true,
            prodId: null,
            prodName: '',
            prodCode: '',
            ciNo: '',
            New_Product_Name__c: '',
            New_Product_CI_No__c: '',
            New_Product_Description__c: '',
            prodFamily: this.productFamily
        };
        this.addAnswer = [...this.addAnswer, newAnswer];
    }

    // removeAnswer(event) {
    //     let indexToRemove = event.target.dataset.index;
    //     if (this.addAnswer.length > 1) {
    //         this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
    //     }
    // }

    removeAnswer(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if (index >= 0 && index < this.addAnswer.length) {
            // Create new array without mutating the original
            const updatedAnswers = [
                ...this.addAnswer.slice(0, index),
                ...this.addAnswer.slice(index + 1)
            ];

            // Reindex the remaining items
            this.addAnswer = updatedAnswers.map((item, idx) => ({
                ...item,
                index: idx
            }));
        }
    }

    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;

        try {
            // Any initialization code
        } catch (error) {
            console.error('Component initialization error:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error initializing component',
                    message: error.message,
                    variant: 'error'
                })
            );
        }
    }

    showSuccess(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    calculatePrice(data) {
        let temp = JSON.parse(data);
        let totalPrice = 0;


        totalPrice = temp.volume * temp.price;

        if (temp.CommissionType == 'Value') {

            if (temp.commissionval >= 0) {
                totalPrice += Number(temp.commissionval);
            }
        }
        else if (temp.CommissionType == 'Percent') {

            if (temp.commissionper > 0) {
                let commissionAmount = (Number(temp.commissionper) / 100) * totalPrice;
                totalPrice += commissionAmount;
            }
        }

        console.log('totalPrice ->', totalPrice);
        return totalPrice;
    }


    // handleScoreChange(event) {
    //     let label = event.target.dataset.label;
    //     let index = event.target.dataset.index;
    //     this.addAnswer[index][label] = event.target.value;
    //     console.log(index + '-->' + JSON.stringify(this.addAnswer[index]));


    //     this.addAnswer[index]['totalprice'] = this.calculatePrice(JSON.stringify(this.addAnswer[index]));

    //     if (label == 'prodFamily') {
    //         this.addAnswer[index] = { ...this.addAnswer[index], prodId: '', prodName: '', prodCode: '' };
    //     }
    //     console.log('label', label, index, this.addAnswer[index][label]);


    // }

    handleScoreChange(event) {
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;

        // Update the corresponding value in the 'addAnswer' array
        this.addAnswer[index][label] = event.target.value;
        console.log(index + '-->' + JSON.stringify(this.addAnswer[index]));

        // Recalculate total price based on updated fields
        this.addAnswer[index]['totalprice'] = this.calculatePrice(JSON.stringify(this.addAnswer[index]));

        // Recalculate final price by adding freight value
        this.addAnswer[index]['finalprice'] = this.calculateFinalPrice(index);

        // If 'prodFamily' changes, reset product fields
        if (label == 'prodFamily') {
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: '', prodName: '', prodCode: '' };
        }
        console.log('Updated answer for index', index, this.addAnswer[index]);
    }


    calculateFinalPrice(index) {
        const answer = this.addAnswer[index];

        // Ensure totalprice is a valid number
        const totalprice = parseFloat(answer.totalprice) || 0; // Default to 0 if totalprice is invalid

        // Ensure freightval is valid, if blank or invalid, default it to 0
        const freightval = parseFloat(answer.freightval) || 0; // Default to 0 if freightval is invalid

        // Calculate final price: total price + freight value
        let finalprice = totalprice + freightval;

        // Return the final price, formatted to 2 decimals
        return finalprice.toFixed(2);
    }


    validateData() {
        let validate = true;

        for (let element of this.addAnswer) {
            const isNewProduct = element.New_Product__c;
            const hasNewProductName = element.New_Product_Name__c && element.New_Product_Name__c.trim() !== '';
            const hasExistingProduct = element.prodId && element.prodId.trim() !== '';

            const productAdded = isNewProduct ? hasNewProductName : hasExistingProduct;

            if (productAdded) {
                if (!element.volume || element.volume === 0) {
                    const productName = isNewProduct ? element.New_Product_Name__c : 'Selected Product';
                    this.showSuccess('Error', `Please enter Quantity for ${productName}`, 'error');
                    validate = false;
                    break;
                }
            }
        }

        return validate;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead',
                actionName: 'list' // Shows the Leads list view
            }
        });
    }
}