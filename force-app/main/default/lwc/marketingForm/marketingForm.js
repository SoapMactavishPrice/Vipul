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
import getAccountCurrency1 from '@salesforce/apex/MarketingForm.getAccountCurrency1';
import getPinCodeDetails from '@salesforce/apex/MarketingForm.getPinCodeDetails';
import getaccountdetails from '@salesforce/apex/MarketingForm.getaccountdetails';
import findRecentPrices from '@salesforce/apex/MarketingForm.findRecentPrices';
import fetchListPrice from '@salesforce/apex/MarketingForm.fetchListPrice';
import getUserInfoWithLeadType from '@salesforce/apex/MarketingForm.getUserInfoWithLeadType'; // Apex method to fetch filtered picklist
import sendEmailNotification from '@salesforce/apex/SendEmail.sendEmailNotification';
import sendEmailNotification1 from '@salesforce/apex/ManagerEmailSender.sendEmailToManager';
import getSampleReferenceNumbers from '@salesforce/apex/MarketingForm.getSampleReferenceNumbers';

export default class MarketingForm extends NavigationMixin(LightningElement) {
    //export default class MarketingForm extends LightningElement {
    filledByName = '';
    filledByID = '';
    opportunityName = '';
    closeDate = '';
    enquiryMode = '';
    enquiryType = '';
    customerType = '';
    accountId = '';
    whoWillAttend = '';
    description = '';
    countryId = '';
    countryId1 = '';
    userDivision = '';
    incoTerms = '';
    @track isOpenFileView = false;
    @track lastFivePrices = [];
    @track currentProductIndex = 0;
    @track productPricesList = [];
    @track showProductSelector = false; // New trackable property

    @track currencyfilter;
    @track selectedCurrency = '';
    @api filter;

    // Add this property to track sample reference numbers
    @track sampleReferenceNumbers = [];
    @track selectedSampleReference = '';

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
    @track isLeadTypeEnabled = false;

    @track lastFivePrices = [];
    @track optionsProductFamily = [];

    // Add these properties
    @track isSampleModalOpen = false;
    @track sampleReferences = [];
    @track currentSampleIndex = 0;

    isSubmitting = false;

    isModalOpen = false;
    lastFivePrices = [];

    leadName = '';
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
    pincode = '';
    territory = 'Domestic';
    leadcurrency = '';
    js = '';

    enquiryType1;

    optionsenquirytype = [];
    optionsincoTerms = [];
    @track optionsaccountcurrency = [];


    // Example data for Enquiry Type and Incoterms
    data = [
        { field: 'Enquiry_Type__c', label: 'Domestic', value: 'Domestic' },
        { field: 'Enquiry_Type__c', label: 'International', value: 'International' },
        { field: 'Enquiry_Type__c', label: 'Both', value: 'Both' },
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


    connectedCallback() {
        // Set the options for Enquiry Type
        this.optionsenquirytype = this.data.filter(item => item.field === 'Enquiry_Type__c').map(item => ({
            label: item.label,
            value: item.value
        }));

        // Initially set the options for Inco Terms to include everything
        this.optionsincoTerms = this.data.filter(item => item.field === 'Inco_Terms__c').map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    updateIncoTermsOptions() {
        // Filter based on the selected Enquiry Type
        if (this.enquiryType1 === 'Domestic') {
            // Show only specific Inco Terms for Domestic
            this.optionsincoTerms = this.data.filter(item => item.field === 'Inco_Terms__c' &&
                (item.value === 'EX BHIWANDI' || item.value === 'EX AMBERNATH' || item.value === 'DDP' || item.value === 'EXW'))
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
        } else {
            // Show all Inco Terms except 'EX BHIWANDI' and 'EX AMBERNATH' for International
            this.optionsincoTerms = this.data.filter(item => item.field === 'Inco_Terms__c' &&
                item.value !== 'EX BHIWANDI' && item.value !== 'EX AMBERNATH')
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
        }
        // Log to confirm the filtered options
        console.log('Updated Inco Terms:', this.optionsincoTerms);
    }



    get isTerritoryDomestic() {
        return this.territory === 'Domestic';
    }



    handleLeadInputChange(event) {

        const field = event.target.dataset.id;
        if (field === 'leadName') {
            this.leadName = event.target.value;
        } else if (field === 'fname') {
            this.fname = event.target.value;
        } else if (field === 'companyName') {
            this.companyName = event.target.value;
        } else if (field === 'leadSource') {
            this.leadSource = event.target.value;
        } else if (field === 'enquiryMode') {
            this.enquiryMode = event.target.value;
        } else if (field === 'customerType') {
            this.customerType = event.target.value;
        } else if (field === 'description') {
            this.description = event.target.value;
        } else if (field === 'countryId') {
            this.countryId = event.detail.recordId;
        } else if (field === 'assignedTo') {
            this.assignedTo = event.target.value;
        } else if (field === 'email') {
            this.email = event.target.value;
        } else if (field === 'phone') {
            this.phone = event.target.value;
        } else if (field === 'street') {
            this.street = event.target.value;
        } else if (field === 'areaId') {
            this.areaId = event.detail.recordId;
        } else if (field === 'cityId') {
            this.cityId = event.detail.recordId;
        } else if (field === 'stateId') {
            this.stateId = event.detail.recordId;
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
        }
        else if (field === 'leadcurrency') {
            this.leadcurrency = event.target.value;
        }
    }


    get leadcurrency() {

        return this._leadcurrency || (this.customerType === 'Domestic' ? 'INR' : '');
    }

    set leadcurrency(value) {
        this._leadcurrency = value;
    }

    createLead() {

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
        }));

        const js = JSON.stringify(Product_Interested__c);
        console.log('js', js);

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
            pincode: this.pincode,
            territory: this.territory,
            leadcurrency: leadcurrency,
            js: js
        })
            .then(result => {
                this.showToast('Success', 'Lead created successfully', 'success');
                location.reload();
            })
            .catch(error => {
                this.showToast('Error', 'Error creating lead: ' + error.body.message, 'error');
            });
    }





    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }


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



    enquiryTypeOptions = [
        { label: 'None', value: '' },
        { label: 'Lead', value: 'Lead' },
        { label: 'Enquiry', value: 'Opportunity' },
    ];


    customerTypeOptions = [
        { label: 'None', value: '' },
        { label: 'Old', value: 'Old' },
        { label: 'New', value: 'New' },
    ];



    @wire(getCurrentUserName)
    currentUserName({ data, error }) {
        if (data) {

            this.filledByName = data.Name;
            this.filledByID = data.Id;


            this.whoWillAttend = data.Id;
        } else if (error) {
            console.error('Error fetching user name: ', error);
        }
    }




    @wire(getUserInfoWithLeadType)
    wiredUserInfo({ data, error }) {
        if (data) {

            this.optionsenquirytype = data.filteredPicklist;

            const currentUserProfile = data.userInfo.ProfileName;
            const specialProfileName = 'System Administrator';

            // Enable field only if user is a System Administrator
            this.isLeadTypeEnabled = (currentUserProfile === specialProfileName);

            this.userDivision = data.userDivision;


            if (this.optionsenquirytype.length > 0) {

                const defaultEnquiryType = this.optionsenquirytype.find(option => option.value === 'Domestic');
                if (defaultEnquiryType) {
                    this.enquiryType1 = 'Domestic';
                }
                else {

                    const fallbackEnquiryType = this.optionsenquirytype.find(option => option.value === 'International');
                    if (fallbackEnquiryType) {
                        this.enquiryType1 = 'International';
                    }
                }
            }

        } else if (error) {
            console.error('Error fetching user info: ', error);
        }
    }

    get isLeadTypeDisabled() {
        return !this.isLeadTypeEnabled;
    }



    @wire(getAccounts)
    wiredAccounts({ data, error }) {
        if (data) {
            // this.accountOptions = data.map(account => ({
            //     label: account.Name,
            //     value: account.Id
            // }));
            this.accountOptions = data
                .filter(account => {
                    if (this.enquiryType1 === 'Domestic') {
                        return account.CurrencyIsoCode === 'INR';
                    } else if (this.enquiryType1 === 'International') {
                        return account.CurrencyIsoCode === 'USD';
                    }
                    return false;
                })
                .map(account => ({
                    label: account.Name,
                    value: account.Id
                }));

            console.log('Filtered Account Options:', this.accountOptions);
        } else if (error) {
            console.error('Error fetching accounts: ', error);
        }
    }


    @wire(getAccountCurrency, { accountId: '$accountId' })
    wiredAccountCurrency({ data, error }) {
        if (data) {
            // Set the currency of the selected account
            this.accountCurrency = data;
            this.currencyfilter = `Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '${data}')`;
            //   this.countryId1 = data;
        } else if (error) {

        }
    }

    @wire(getAccountCurrency1, { accountId: '$accountId' })
    wiredAccountCurrency1({ data, error }) {
        if (data) {
            // Set the currency of the selected account
            //  this.accountCurrency = data;
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
            this.incoTerms = data.incoTerms;


        })
    }



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
        return this.enquiryType === 'Opportunity';
    }

    get enquiryTypeIsLead() {
        return this.enquiryType === 'Lead';
    }



    // handleShowPricesClick() {
    //     if (this.accountId && this.addAnswer && this.addAnswer.length > 0) {
    //         this.productPricesList = new Array(this.addAnswer.length);
    //         this.showProductSelector = this.addAnswer.length > 1; // Set visibility flag

    //         this.addAnswer.forEach((answer, index) => {
    //             if (answer.prodId) {
    //                 this.fetchLastFivePrices(this.accountId, answer.prodId, index);
    //             }
    //         });

    //         this.isOpenFileView = true;
    //     }
    // }

    handleShowPricesClick(event) {
        // Get the index from the clicked button's data attribute
        const clickedIndex = event.currentTarget.dataset.index;
        console.log('Clicked index:', clickedIndex);

        if (this.accountId && this.addAnswer && this.addAnswer[clickedIndex]) {
            const clickedProduct = this.addAnswer[clickedIndex];
            console.log('Fetching prices for:', this.accountId, clickedProduct.prodId, clickedIndex);

            // Open modal immediately
            this.isOpenFileView = true;
            this.showProductSelector = this.addAnswer.length > 1;
            this.currentProductIndex = clickedIndex;

            // Fetch data after opening modal
            this.fetchLastFivePrices(this.accountId, clickedProduct.prodId, clickedIndex);
        } else {
            console.error('Missing required data:', {
                hasAccountId: !!this.accountId,
                hasAddAnswer: !!this.addAnswer,
                clickedIndexValid: clickedIndex !== undefined
            });
        }
    }

    fetchLastFivePrices(accountId, productId, index) {
        findRecentPrices({ accountId, productId })
            .then(result => {
                console.log('Prices received:', result);
                this.lastFivePrices = result;
                // Force UI update
                this.lastFivePrices = [...this.lastFivePrices];
            })
            .catch(error => {
                console.error('Error fetching prices:', error);
                this.lastFivePrices = [];
            });
    }

    get productOptions() {
        return this.addAnswer.map((product, index) => ({
            label: product.productName || `Product ${index + 1}`,
            value: index.toString()
        }));
    }

    handleClose() {
        this.isOpenFileView = false;
    }




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
            this.closeDate = event.target.value;
        } else if (field === 'stage') {
            this.stage = event.target.value;
        } else if (field === 'accountCurrency') {
            this.accountCurrency = event.target.value;
            this.selectedCurrency = event.target.value;
        } else if (field === 'enquiryType1') {
            this.enquiryType1 = event.target.value;
            this.updateIncoTermsOptions();
        }

        let value = event.target.value;

        if (field === 'accountCurrency') {
            this.accountCurrency = event.target.value;
            this.selectedCurrency = event.target.value;
            
            // Update currency filter for lookup
            this.currencyfilter = `Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '${event.target.value}')`;
            
            // Refresh list prices for all products
            this.refreshAllListPrices();
        }

        this.setFreightEditability(0, this.addAnswer[0].listPrice);
        console.log('this.accountId', event.detail.recordId);
        console.log(' this.accountCurrency', this.accountCurrency, event.target.value);

    }

    refreshAllListPrices() {
        this.addAnswer.forEach((answer, index) => {
            if (answer.prodId && this.accountCurrency) {
                this.fetchProductListPrice(answer.prodId, index);
            }
        });
    }

    submitClicked = false; // Flag to prevent duplicate submissions

    createOpportunity() {
        
        if (this.submitClicked) {
            return; // Guard against duplicate clicks
        }

        // ✅ Start validation (no flag set yet)
        let validate = this.validateData();
        if (!validate) return;

        if (!this.opportunityName) {
            this.showToast('Error', 'Please select the Enquiry Name.', 'error');
            return;
        }

        if (!this.accountId) {
            this.showToast('Error', 'Please select the Client Name.', 'error');
            return;
        }

        if (!this.incoTerms) {
            this.showToast('Error', 'Please select the Incoterms.', 'error');
            return;
        }

        let opportunityLineItems = this.addAnswer.map(item => ({
            prodFamily: item.prodFamily,
            prodId: item.prodId,
            prodName: item.prodName,
            prodCode: item.prodCode,
            volume: item.volume,
            price: item.price,
            quality: item.quality,
            packaging: item.packaging,
            PackingType: item.PackingType,
            CommissionType: item.CommissionType,
            commissionval: item.commissionval,
            commissionper: item.commissionper,
            freightval: item.freightval,
            totalprice: item.totalprice,
            finalprice: item.finalprice,
            totalpricefinal: item.totalpricefinal
        }));

        for (let i = 0; i < opportunityLineItems.length; i++) {
            const item = opportunityLineItems[i];
            if (!item.prodId) {
                this.showToast('Error', `Select Product For Creating Enquiry ${item.prodName}`, 'error');
                return;
            }

            if (!item.volume || isNaN(item.volume) || parseFloat(item.volume) <= 0) {
                this.showToast('Error', `Quantity is required for product ${item.prodName}`, 'error');
                return;
            }
        }

        // ✅ All validations passed — now set the flag
        this.submitClicked = true;

        const closeDate = new Date(new Date().setDate(new Date().getDate() + 30)).toISOString().split('T')[0];
        const JS = JSON.stringify(opportunityLineItems);

        createOpportunityRecord({
            opportunityName: this.opportunityName,
            closeDate: closeDate,
            filledBy: this.filledByID,
            enquiryMode: this.enquiryMode,
            enquiryType: this.enquiryType,
            customerType: this.customerType,
            accountId: this.accountId,
            whoWillAttend: this.whoWillAttend,
            countryId1: this.countryId1,
            stage: this.stage,
            incoTerms: this.incoTerms,
            enquiryType1: this.enquiryType1,
            currencyCode: this.selectedCurrency,
            JS: JS
        })
            .then(result => {
                this.showToast('Success', 'Opportunity created successfully', 'success');

                Promise.all([
                    sendEmailNotification({ oppId: result }),
                    sendEmailNotification1({ oppId: result })
                ]).catch(error => {
                    console.error('Error sending emails:', error);
                });

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Opportunity',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Error', 'Error creating opportunity: ' + error.body.message, 'error');
                this.submitClicked = false; // allow retry
            });
    }



    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }


    get isCommissionValueDisabled() {
        const answer = this.addAnswer[this.index];
        return answer && answer.CommissionType === 'Percentage';
    }

    get isCommissionPercentageDisabled() {
        const answer = this.addAnswer[this.index];
        return answer && answer.CommissionType === 'Value';
    }






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
    optionsPackingType= [];


    @wire(getPicklistValues)
    wiredPicklist({ error, data }) {
        if (data) {

            this.optionsProductFamily = data.filter(item => item.field === 'Product_Family__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionsPackaging = data.filter(item => item.field === 'Packaging__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionsPackingType = data.filter(item => item.field === 'Packing_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionsCommissionType = data.filter(item => item.field === 'Commission_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));


            this.optionsTerritory = data.filter(item => item.field === 'Lead_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));


            this.optionsleadcurrency = data.filter(item => item.field === 'CurrencyIsoCode').map(item => ({
                label: item.label,
                value: item.value
            }));






            this.optionsincoTerms = data.filter(item => item.field === 'Inco_Terms__c').map(item => ({
                label: item.label,
                value: item.value
            }));


            this.optionsstage = data.filter(item => item.field === 'StageName').map(item => ({
                label: item.label,
                value: item.value
            }));

            this.optionsenquirytype = data.filter(item => item.field === 'Enquiry_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));


            if (!this.territory) {
                const defaultTerritory = this.optionsTerritory.find(option => option.value === 'Domestic');
                if (defaultTerritory) {
                    this.territory = 'Domestic';
                }
            }

            this.updateIncoTermsOptions();

            console.log('Territory options:', this.optionsTerritory);
            console.log('Default territory value:', this.territory);
        } else if (error) {
            this.showErrorToast(error.body.message);
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

    // Update handleProductSelection to just fetch options
    handleProductSelection(productId, index) {
        if (productId) {
            getSampleReferenceNumbers({ productId: productId })
                .then(result => {
                    const updatedAnswers = [...this.addAnswer];
                    // Filter out the custom input option since we don't need it for datalist
                    const options = result.filter(opt => opt.value !== 'custom_input');
                    updatedAnswers[index] = {
                        ...updatedAnswers[index],
                        qualityOptions: options || []
                    };
                    this.addAnswer = updatedAnswers;
                })
                .catch(error => {
                    console.error('Error fetching sample references:', error);
                    const updatedAnswers = [...this.addAnswer];
                    updatedAnswers[index] = {
                        ...updatedAnswers[index],
                        qualityOptions: []
                    };
                    this.addAnswer = updatedAnswers;
                });
        } else {
            const updatedAnswers = [...this.addAnswer];
            updatedAnswers[index] = {
                ...updatedAnswers[index],
                qualityOptions: []
            };
            this.addAnswer = updatedAnswers;
        }
    }

    // Add this method to fetch sample references
    handleShowSamplesClick(event) {
        const clickedIndex = event.currentTarget.dataset.index;
        const productId = this.addAnswer[clickedIndex].prodId;

        if (productId) {
            getSampleReferenceNumbers({ productId: productId })
                .then(result => {
                    this.sampleReferences = result;
                    this.currentSampleIndex = clickedIndex;
                    this.isSampleModalOpen = true;
                })
                .catch(error => {
                    console.error('Error fetching sample references:', error);
                    this.showToast('Error', 'Failed to fetch sample references', 'error');
                });
        } else {
            this.showToast('Info', 'Please select a product first', 'info');
        }
    }

    // Add this method to handle sample selection
    handleSampleSelect(event) {
        const referenceNumber = event.currentTarget.dataset.value;
        const index = this.currentSampleIndex;

        // Update the quality field with the selected reference
        const updatedAnswers = [...this.addAnswer];
        updatedAnswers[index] = {
            ...updatedAnswers[index],
            quality: referenceNumber
        };
        this.addAnswer = updatedAnswers;

        // Close the modal
        this.isSampleModalOpen = false;
    }

    // Add this method to close the sample modal
    handleCloseSampleModal() {
        this.isSampleModalOpen = false;
    }

    get qualityListId() {
        return (index) => `quality-list-${index}`;
    }

    // Handle quality input change
    handleQualityInput(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        const updatedAnswers = [...this.addAnswer];
        updatedAnswers[index] = {
            ...updatedAnswers[index],
            quality: value
        };
        this.addAnswer = updatedAnswers;
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        const pbe = selectedRecord;

        if (this.addAnswer && this.addAnswer[index]) {
            // Create a new array to maintain reactivity
            const updatedAnswers = [...this.addAnswer];
            updatedAnswers[index] = {
                ...updatedAnswers[index],
                prodId: pbe.Id,
                prodName: pbe.Name,
                prodCode: pbe.ProductCode,
                qualityOptions: [] // Initialize empty options
            };

            this.addAnswer = updatedAnswers;

            // Fetch sample reference numbers
            this.handleProductSelection(pbe.Id, index);
            this.fetchProductListPrice(pbe.Id, index);
        }

        console.log('Updated Field:', index, this.addAnswer[index]);
    }

    // when user selects Quality (Reference Number)
    handleSampleReferenceChange(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        // Create a new array to maintain reactivity
        const updatedAnswers = [...this.addAnswer];
        updatedAnswers[index] = {
            ...updatedAnswers[index],
            quality: value
        };
        this.addAnswer = updatedAnswers;
    }

    fetchProductListPrice(productId, index) {

        fetchListPrice({ productId: productId, currencyCode: this.accountCurrency })
            .then(result => {

                const listPrice = result !== null ? result : 0;
                this.addAnswer[index].listPrice = listPrice;


                const isDisabled = listPrice === 0;
                this.addAnswer[index].isDisabled = isDisabled;
                this.addAnswer[index].isvaldisabled = isDisabled;
                this.addAnswer[index].isperdisabled = isDisabled;



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

        // If price is greater than 0, then check for Incoterms
        if (listPrice > 0) {
            // Check if Incoterms match the valid list
            if (this.incoTerms && ['CFR', 'CIF', 'CPT', 'CIP', 'DAP', 'DDP'].includes(this.incoTerms)) {
                isFreightEditable = true;  // Enable freightval if valid Incoterms
                console.log('Freight is editable due to valid Incoterms:', this.incoTerms);
            } else {
                isFreightEditable = false; // Disable freightval if Incoterms are not valid
                console.log('Freight is NOT editable due to invalid Incoterms:', this.incoTerms);
            }
        }

        // If price is blank or 0, disable freightval regardless of Incoterms
        if (!listPrice || listPrice === '0') {
            isFreightEditable = false;
            console.log('Freight is disabled due to price being 0 or blank');
        }

        // Update the status of freightval
        this.addAnswer[index].isFreightDisabled = !isFreightEditable;

        console.log(`Freight Disabled status for index ${index}: ${this.addAnswer[index].isFreightDisabled}`);

        // If Freight is disabled, reset the value
        if (this.addAnswer[index].isFreightDisabled) {
            this.addAnswer[index].freightval = '';
            console.log('Freight value reset due to price being 0 or blank or invalid Incoterms');
        }
    }


    handleIncoTermsChange(event) {
        this.incoTerms = event.detail.value;
        console.log("Incoterms selected:", this.incoTerms);


        this.setFreightEditability(event.target.dataset.index, this.addAnswer[event.target.dataset.index].listPrice);
    }






    handleCommissionChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.label;
        const value = event.target.value;


        if (this.addAnswer && this.addAnswer[index]) {

            this.addAnswer[index][field] = value;


            const price = this.addAnswer[index].price;
            const listPrice = this.addAnswer[index].listPrice;

            if (listPrice > 0 && price > 0) {
                if (field === 'commissionval') {

                    const commissionper = ((value / price) * 100).toFixed(2);
                    this.addAnswer[index].commissionper = commissionper;
                } else if (field === 'commissionper') {

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
            PackingType: '',
            CommissionType: '',
            commissionval: '',
            commissionper: '',
            totalprice: '',
            finalprice: '',
            totalpricefinal: '',
            qualityOptions: [] // <-- new field to hold combobox options
        }
    ];

    connectedCallback() {
        this.getExisting();

        const today = new Date();
        this.closeDate = new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0];
        this.stage = 'New';
    }

    handlePackagingChange(event) {
        const index = event.target.dataset.index;
        const packagingValue = event.detail.value;
        this.addAnswer[index].packaging = packagingValue;
    }

    handlePackagingChange(event) {
        const index = event.target.dataset.index;
        const PackingTypeValue = event.detail.value;
        this.addAnswer[index].PackingType = PackingTypeValue;
    }

    handleCommissionTypeChange(event) {
        const index = event.target.dataset.index;
        const CommissionTypeValue = event.detail.value;
        this.addAnswer[index].CommissionType = CommissionTypeValue;
    }

    addAnswerItem() {
        //  let validate = this.validateData();


        this.tempIndex = this.tempIndex + 1;
        const newAnswer = {
            index: this.tempIndex,
            prodFamily: '',
            prodId: '',
            prodName: '',
            prodCode: '',
            volume: '',
            price: '',
            packaging: '',
            PackingType: '',
            quality: '',
            qualityOptions: []// Add this

        };
        this.addAnswer.push(newAnswer);

    }

    removeAnswer(event) {
        let indexToRemove = event.target.dataset.index;
        if (this.addAnswer.length > 1) {
            this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
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

    formatNumber(value, decimals = 2) {
        if (value === null || value === undefined || value === '') return '0.00';
        
        // Convert to number and fix decimals
        const num = parseFloat(value);
        if (isNaN(num)) return '0.00';
        
        // Use toFixed and parseFloat to remove trailing zeros
        return parseFloat(num.toFixed(decimals));
    }

    // Update calculatePrice method
    calculatePrice(data) {
        let temp = JSON.parse(data);
        let totalPrice = this.formatNumber(temp.price);
        
        if (totalPrice <= 0) {
            console.error('Invalid price');
            return totalPrice;
        }
        
        if (temp.CommissionType === 'Value') {
            const commissionValue = this.formatNumber(temp.commissionval);
            if (commissionValue < 0) {
                console.error('Invalid commission value');
            } else {
                totalPrice += commissionValue;
            }
        } else if (temp.CommissionType === 'Percent') {
            const commissionPercent = this.formatNumber(temp.commissionper);
            if (commissionPercent <= 0) {
                console.error('Invalid commission percentage');
            } else {
                let commissionAmount = (commissionPercent / 100) * totalPrice;
                totalPrice += commissionAmount;
            }
        }
        
        return this.formatNumber(totalPrice);
    }

    handleScoreChange(event) {
        let label = event.target.dataset.label; // Field name (like 'price', 'CommissionType', etc.)
        let index = event.target.dataset.index; // Current index in the array

        console.log('Field Label:', label); // For debugging

        // Update the value in the array based on the input field
        this.addAnswer[index][label] = event.target.value;

        if (label === 'packaging') {
            // Add any specific logic for packaging changes
            console.log('Packaging updated:', event.target.value);
        }

        if (label === 'PackingType') {
            console.log('PackingType updated:', event.target.value);
        }

        // Handle CommissionType change specifically
        if (label === 'CommissionType') {
            console.log('Handling CommissionType Change');

            // Update isDisabled based on CommissionType value
            if (this.addAnswer[index].CommissionType === 'Value') {
                console.log('Commission Type is "Value"');
                // Enable CommissionValue if CommissionType is "Value"
                this.addAnswer[index].isvaldisabled = false; // Enable CommissionValue field
                this.addAnswer[index].isperdisabled = true;  // Disable Percentage field
                this.addAnswer[index].commissionper = 0;     // Reset commission per value
            } else if (this.addAnswer[index].CommissionType === 'Percent') {
                console.log('Commission Type is "Percent"');
                // Enable CommissionPer if CommissionType is "Percent"
                this.addAnswer[index].isvaldisabled = true;  // Disable CommissionValue field
                this.addAnswer[index].isperdisabled = false; // Enable Percentage field
                this.addAnswer[index].commissionval = 0;     // Reset commission value
            }
        }

        // Handle Price change and dynamically disable CommissionType, CommissionValue or Percentage if Price is blank
        if (label === 'price') {
            console.log('Handling Price Change for index:', index);
            // Disable CommissionType and CommissionValue/Percentage if price is blank or 0
            if (!event.target.value || event.target.value === '0') {
                this.addAnswer[index].isDisabled = true; // Disable CommissionType
                this.addAnswer[index].isvaldisabled = true; // Disable CommissionValue
                this.addAnswer[index].isperdisabled = true; // Disable Percentage
                this.addAnswer[index].commissionval = 0;   // Reset CommissionValue
                this.addAnswer[index].commissionper = 0;   // Reset CommissionPercentage

                // Disable Freight if Price is removed or 0
                this.addAnswer[index].isFreightDisabled = true;  // Disable Freight
                this.addAnswer[index].freightval = 0; // Reset Freight Value
                console.log('Price is empty or 0, disabling Freight');
            } else {
                this.addAnswer[index].isDisabled = false; // Enable CommissionType if price is set
                // If CommissionType is "Value", enable CommissionValue
                if (this.addAnswer[index].CommissionType === 'Value') {
                    this.addAnswer[index].isvaldisabled = false; // Enable CommissionValue if price is present
                }
                // If CommissionType is "Percent", enable Percentage
                if (this.addAnswer[index].CommissionType === 'Percent') {
                    this.addAnswer[index].isperdisabled = false; // Enable Percentage if price is present
                }

                // Enable Freight if Price is available, but check Incoterms as well
                if (this.incoTerms && ['CFR', 'CIF', 'CPT', 'CIP', 'DAP', 'DDP'].includes(this.incoTerms)) {
                    this.addAnswer[index].isFreightDisabled = false;  // Enable Freight if Incoterms are valid
                    console.log('Freight enabled due to valid Incoterms:', this.incoTerms);
                } else {
                    this.addAnswer[index].isFreightDisabled = true;  // Disable Freight if Incoterms are not valid
                    console.log('Freight disabled due to invalid Incoterms:', this.incoTerms);
                }
            }
        }

        // Recalculate the totalprice based on other fields
        this.addAnswer[index]['totalprice'] = this.calculatePrice(JSON.stringify(this.addAnswer[index]));
        console.log('Total Price:', this.addAnswer[index]['totalprice']);

        // Recalculate final price
        this.addAnswer[index]['finalprice'] = this.calculateFinalPrice(index);
        console.log('Final Price:', this.addAnswer[index]['finalprice']);

        // Recalculate total price final
        this.addAnswer[index]['totalpricefinal'] = this.calculateFinalPrice1(index);
        console.log('Total Price Final:', this.addAnswer[index]['totalpricefinal']);

        // Reset product fields if prodFamily field is updated
        if (label === 'prodFamily') {
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: '', prodName: '', prodCode: '' };
        }

        console.log('Updated Answer for Index:', index, this.addAnswer[index]);
    }

    calculateFinalPrice(index) {
        const answer = this.addAnswer[index];
        const totalprice = parseFloat(answer.totalprice) || 0;
        const freightval = parseFloat(answer.freightval) || 0;
        let finalprice = totalprice + freightval;
        
        // Use Number() to avoid string concatenation issues
        return Number(finalprice.toFixed(2));
    }

    calculateFinalPrice1(index) {
        const answer = this.addAnswer[index];
        const finalprice = parseFloat(answer.finalprice) || 0;
        const volume = parseFloat(answer.volume) || 0;
        let totalpricefinal = finalprice * volume;
        
        return Number(totalpricefinal.toFixed(2));
    }

    validateData() {
        let validate = true;
        for (let element of this.addAnswer) {
            // if (element.prodFamily === '' || element.prodFamily === undefined || element.prodFamily === 0) {
            //     this.showSuccess('Error', `Please Fill family for Product ${element.prodName}`, 'Error');
            //     validate = false;
            //     break;
            // } 
            if (element.prodName === '' || element.prodName === undefined || element.prodName === 0) {
                this.showSuccess('Error', `Please Select Product`, 'Error');
                validate = false;
                break;
            } else if (element.volume === '' || element.volume === undefined || element.volume === 0) {
                this.showSuccess('Error', `Please Fill Quantity in kgs for Product ${element.prodName}`, 'Error');
                validate = false;
                break;
            }
            // else if (element.price === '' || element.price === undefined || element.price === 0) {
            //     this.showSuccess('Error', `Please Fill Price for Product ${element.prodName}`, 'Error');
            //     validate = false;
            //     break;
            // }
        }
        return validate;
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'list' // Shows the Leads list view
            }
        });
    }
}