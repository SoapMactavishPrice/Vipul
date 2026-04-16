import { LightningElement, track, wire, api } from 'lwc';
import createSampleRequest from '@salesforce/apex/NewSampleRequest.createSampleRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUserOptions from '@salesforce/apex/NewSampleRequest.getUserOptions';
import getSamplesRequestSentToOptions from '@salesforce/apex/NewSampleRequest.getSamplesRequestSentToOptions';
import getProductOptions from '@salesforce/apex/NewSampleRequest.getProductOptions';
import getAccountAndCountryDetails from '@salesforce/apex/NewSampleRequest.getAccountAndCountryDetails';
//import getOpportunityById from '@salesforce/apex/NewSampleRequest.getOppcountryById';
//import getaccountdetails from '@salesforce/apex/NewSampleRequest.getopptails';
//import getOpportunityAccountAndCountry from '@salesforce/apex/NewSampleRequest.getOpportunityAccountAndCountry';
import { NavigationMixin } from 'lightning/navigation';
import getCurrentUserName from '@salesforce/apex/MarketingForm.getCurrentUserName';
import getUnitOfMeasureOptions from '@salesforce/apex/NewSampleRequest.getUnitOfMeasureOptions';
import fetchCI from '@salesforce/apex/MarketingForm.fetchCI';



export default class LwcSampleRequest extends NavigationMixin(LightningElement) {
    @track sampleType = '';
    @track sampleTypeOptions = [
        { label: 'Sample In', value: 'SampleIn' },
        { label: 'Sample Out', value: 'SampleOut' }
    ];
    opportunity;
    error;
    @track addAnswer = [];
    @track sampleOutSentTo = ''; // Picklist for Samples_Request_Sent_to__c
    @track sampleOutSentToOptions = []; // Options for Samples_Request_Sent_to__c
    @track requestDate = ''; // Date for Request_Date__c
    @track receivedDate = ''; // Date for Received_Date__c
    @track personId = ''; // Person (lookup to User)
    @track filledByName = '';
    @track accountId = ''; // Company (lookup to Account)
    @track enquiryId = '';
    @track countryId = ''; // Country (lookup to Country__c)
    @track delayDays = 0; // Delay Days
    @track companyOptions = [];  // List of Companies to show in search
    @track countryOptions = [];  // List of Countries to show in search


    @track isPageLoad = true;
    @track userOptions = [];
    @track productOptions = []; // To hold Product Name options (e.g., Product_Name__c)
    @track products = [
        {
            index: 0,
            prodId: '',
            quantity: '',
            ciNo: '',
            packet: '',
            quality: '',
            colourIndex: '',
            application: '',
            ci: '',
            srefno: '',
            courierno: '',
            productName: '',
            unitOfMeasure: '',
            unitId: '',

        }
    ];
    // @track recordId = '';
    @api recordId;
    unitOfMeasureOptions = [];
    unitOfMeasure = '';

    get validAccountId() {
        return this.accountId && this.accountId.length === 18 ? this.accountId : undefined;
    }
    
    @wire(getAccountAndCountryDetails, { accountId: '$validAccountId' })
    accountData({ error, data }) {
        if (data) {
            this.accountId = data.accountId;
            this.companyName = data.accountName;
            this.countryId = data.countryId;
            this.countryName = data.countryName;
        } else if (error) {
            console.error('Error fetching account and country details', error);
            this.showErrorToast(error);
        }
    }
    


    @wire(getUnitOfMeasureOptions)
    wiredUnitOfMeasureOptions({ data, error }) {
        if (data) {
            // Populate the options for the picklist
            this.unitOfMeasureOptions = data.map(option => ({
                label: option.label,
                value: option.value
            }));
        } else if (error) {
            console.error('Error fetching Unit of Measure picklist values:', error);
        }
    }

    // Handle the selection of the Unit of Measure picklist
    handleUnitOfMeasureChange(event) {
        this.unitOfMeasure = event.target.value;
        console.log('unitOfMeasure', this.unitOfMeasure);
    }

    @wire(getCurrentUserName)
    currentUserName({ data, error }) {
        if (data) {

            this.filledByName = data.Name;
            this.personId = data.Id;


            //   this.personId = data.Id;
        } else if (error) {
            console.error('Error fetching user name: ', error);
        }
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        const selectedProduct = selectedRecord;

        // Update product details in the products array
        this.products[index] = {
            ...this.products[index],
            prodId: selectedProduct.Id,
            prodName: selectedProduct.Name,
            prodCode: selectedProduct.ProductCode,
            ciNo: selectedProduct.CI_no__c,

        };

        console.log('Updated Product:', index, this.products[index]);

        this.fetchCIForProduct(selectedRecord.Id, index);
    }


    get isSampleInSelected() {
        return this.sampleType === 'SampleIn';
    }

    get isSampleOutSelected() {
        return this.sampleType === 'SampleOut';
    }

    get accountAndCountryDetails() {
        if (this.isSampleInSelected || this.isSampleOutSelected) {
            return {
                accountName: this.companyName,
                countryName: this.countryName
            };
        }
        return null;
    }


    getAccCode() {
        getaccountdetails({ opportunityId: this.recordId }).then(result => {
            let data = JSON.parse(result);

            this.countryId = data.countryId;
            this.accountId = data.accountId;
            console.log('Account and Country data:', data);

            // Assuming the countryId and companyNameId are set correctly
        }).catch(error => {
            console.error('Error fetching account details:', error);
        });
    }


    handleCompanyChange(event) {
        this.companyName = event.target.value;
        if (this.companyName) {
            getCompanyOptions({ searchKey: this.companyName })
                .then((result) => {
                    this.companyOptions = result;
                })
                .catch((error) => {
                    this.companyOptions = [];
                    this.showErrorToast(error);
                });
        } else {
            this.companyOptions = []; // Clear options if input is empty
        }
    }

    handleCountryChange(event) {
        this.countryName = event.target.value;
        if (this.countryName) {
            getCountryOptions({ searchKey: this.countryName })
                .then((result) => {
                    this.countryOptions = result;
                })
                .catch((error) => {
                    this.countryOptions = [];
                    this.showErrorToast(error);
                });
        } else {
            this.countryOptions = []; // Clear options if input is empty
        }
    }

    handleCompanySelect(event) {
        this.accountId = event.target.dataset.value;
        this.companyName = event.target.dataset.label;
        this.companyOptions = [];  // Clear options after selection
    }

    handleCountrySelect(event) {
        this.countryId = event.target.dataset.value;
        this.countryName = event.target.dataset.label;
        this.countryOptions = [];  // Clear options after selection
    }

    get isSampleInSelected() {
        return this.sampleType === 'SampleIn';
    }

    get isSampleOutSelected() {
        return this.sampleType === 'SampleOut';
    }

    // @wire(getOpportunityById, { opportunityId: '$opportunityId' })
    // wiredOpportunity({ error, data }) {
    //     if (data) {
    //         this.opportunity = data;
    //         this.error = undefined;
    //         console.log('Opportunity Data: ', this.opportunity);
    //     } else if (error) {
    //         this.error = error;
    //         this.opportunity = undefined;
    //         console.error('Error fetching opportunity:', error);
    //     }
    // }

    connectedCallback() {
        console.log('connectedCallback - Loading options...');
        getUserOptions()
            .then(result => {
                this.userOptions = result.map(user => ({
                    label: user.Name,
                    value: user.Id
                }));
                console.log('User Options loaded:', this.userOptions);
            })
            .catch(error => {
                console.error("Error fetching users", error);
            });

        getSamplesRequestSentToOptions()
            .then(result => {
                this.sampleOutSentToOptions = result.map(option => ({
                    label: option.label,
                    value: option.value
                }));
                console.log('Sample Out Sent To Options loaded:', this.sampleOutSentToOptions);
            })
            .catch(error => {
                console.error("Error fetching picklist options", error);
            });

        getProductOptions()
            .then(result => {
                this.productOptions = result.map(option => ({
                    label: option.Name,
                    value: option.Id
                }));
                console.log('Product Options loaded:', this.productOptions);
            })
            .catch(error => {
                console.error("Error fetching product options", error);
            });

        console.log('recordId:', this.recordId);

        let today = new Date();
        let year = today.getFullYear();
        let month = String(today.getMonth() + 1).padStart(2, '0'); // Months are zero-indexed
        let day = String(today.getDate()).padStart(2, '0');

        // Format the date as 'yyyy-mm-dd'
        this.requestDate = `${year}-${month}-${day}`;

            // Check if accountId is valid
        if (this.accountId && this.accountId.length === 18) {
            console.log('Valid accountId:', this.accountId);
        } else {
            console.error('Invalid accountId:', this.accountId);
        }
    }

    handleSampleTypeChange(event) {
        this.sampleType = event.detail.value;
        this.isPageLoad = false;
        console.log('Sample Type changed to:', this.sampleType);

        if (this.recordId) {
            this.fetchAccountAndCountry();  // Fetch Account and Country when sampleType changes
        }

    }

    fetchAccountAndCountry() {
        getOpportunityAccountAndCountry({ opportunityId: this.recordId })
            .then(result => {
                // Set the Account and Country values after fetching them
                this.accountId = result.accountId;
                this.companyName = result.accountName;
                this.countryId = result.countryId;
                this.countryName = result.countryName;

                console.log('Account and Country fetched:', this.companyName, this.countryName);
            })
            .catch(error => {
                console.error('Error fetching Account and Country:', error);
                this.showErrorToast(error);
            });
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.id;
        if (fieldName === 'sampleOutSentTo') {
            this.sampleOutSentTo = event.target.value;
            console.log('Sample Out Sent To changed to:', this.sampleOutSentTo);
        } else if (fieldName === 'requestDate') {
            this.requestDate = event.target.value;
            console.log('Request Date changed to:', this.requestDate);
            this.calculateDelayDays();  // Recalculate delay days whenever the request date changes
        } else if (fieldName === 'receivedDate') {
            this.receivedDate = event.target.value;
            console.log('Received Date changed to:', this.receivedDate);
            this.calculateDelayDays();  // Recalculate delay days whenever the received date changes
        } if (fieldName === 'personId') {
            this.personId = event.detail.recordId; // Ensure recordId is correctly assigned
            console.log('Person (User) changed to:', this.personId);
        } else if (fieldName === 'accountId') {
            this.accountId = event.detail.recordId;
        } else if (fieldName === 'countryId') {
            this.countryId = event.detail.recordId;
            console.log('Country changed to:', this.countryId);
        }

        else if (fieldName === 'enquiryId') {
            this.enquiryId = event.detail.recordId;
            console.log('Enquiry changed to:', this.enquiryId);
        }
    }


    calculateDelayDays() {
        if (this.requestDate && this.receivedDate) {
            const requestDate = new Date(this.requestDate);
            const receivedDate = new Date(this.receivedDate);
            const timeDifference = receivedDate - requestDate;
            this.delayDays = timeDifference / (1000 * 3600 * 24); // Convert milliseconds to days
            console.log('Calculated Delay Days:', this.delayDays);
        } else {
            this.delayDays = 0; // Reset delay days if either date is missing
            console.log('Reset Delay Days to 0');
        }
    }

    fetchCIForProduct(productId, index) {
        fetchCI({ productId: productId })
            .then((result) => {
                if (this.products[index]) {
                    this.products[index].ciNo = result;  // Update the CI field in products array
                    this.products = [...this.products];  // Ensure reactivity
                    console.log('CI number fetched for product:', result);
                }
            })
            .catch((error) => {
                console.error('Error fetching CI_no__c:', error);
            });
    }


    handleProductFieldChange(event) {
        const fieldName = event.target.dataset.label;
        const index = event.target.dataset.index;

        // Check if it's a lightning-record-picker
        const value = event.detail && event.detail.recordId ? event.detail.recordId : event.target.value;

        // Update the product field at the specific index
        this.products[index][fieldName] = value;
        console.log(`Product at index ${index} updated - ${fieldName}:`, value);

        this.addAnswer[index] = {
            ...this.addAnswer[index],
            prodId: this.products[index].prodId,
            prodName: this.products[index].prodName,
            prodCode: this.products[index].prodCode,
            ciNo: this.products[index].ciNo,
            unitOfMeasure: this.products[index].unitOfMeasure,
            unitId: this.products[index].unitId // <-- Corrected line
        };
    }


    handleUnitChange(event) {
        try {
            const index = event.target.dataset.index;
            const selectedRecord = event.detail;

            if (!selectedRecord) {
                console.log("No unit selected");
                return;
            }

            // Update the products array
            this.products[index] = {
                ...this.products[index],
                unitId: selectedRecord.recordId,
                unitName: selectedRecord.name
            };

            // Force reactivity
            this.products = [...this.products];

            console.log(`Unit selected for product ${index}:`, selectedRecord);
        } catch (error) {
            console.error('Error handling unit change:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to select unit',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }

    addProduct() {
        // Add a new product entry to the products array
        this.products = [
            ...this.products,
            {
                index: this.products.length,
                prodId: '',  // Empty initially, will be filled on lookup selection
                prodName: '',
                prodCode: '',
                ciNo: '',
                quantity: '',
                packet: '',
                quality: '',
                colourIndex: '',
                application: '',
                ci: '',
                srefno: '',
                productName: '',
                unitOfMeasure: '',
                unitId: '',

            }
        ];
        console.log('Added new product:', this.products);
    }


    removeProduct(event) {
        const index = event.target.dataset.index;
        console.log('Removing product at index:', index);

        // Remove product from the array by index
        this.products = this.products.filter((product, i) => i !== parseInt(index));
        console.log('Updated products array:', this.products);
    }


    handlePersonChange(event) {
        console.log('Person ID changed to:', this.personId);
        console.log('Person ID changed to:', event.detail.recordId);
        this.personId = event.detail.recordId;  // Ensure the value is a valid User ID
        console.log('Person ID changed to:', this.personId);
    }

    handleSubmitSampleOut() {
        console.log('handleSubmitSampleOut - Validating form for Sample Out...');


        // Check if all products have a product selected
        const allProductsHaveProdId = this.products.every(product => product.prodId);

        // Check if all products have a unit selected
        const allProductsHaveUnitId = this.products.every(product => product.unitId);

        if (!allProductsHaveProdId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select a Product for all rows.',
                variant: 'error'
            }));
            return;
        }

        if (!allProductsHaveUnitId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select a Sample Sent to Units for all rows.',
                variant: 'error'
            }));
            return;
        }




        const productData = this.products.map(product => ({


            prodId: product.prodId,
            quantity: product.quantity,
            ciNo: product.ciNo,
            packet: product.packet,
            quality: product.quality,
            colourIndex: product.colourIndex,
            application: product.application,
            courierno: product.courierno,
            annualQtyOfBusiness: product.annualQtyOfBusiness,
            unitOfMeasure: product.unitOfMeasure,
            unitId: product.unitId,

        }));

        console.log('this.product', productData);
        // Prepare request data
        const requestData = {
            recordId: this.recordId,
            sampleout: this.sampleType,
            sampleOutSentTo: this.sampleOutSentTo,
            delayDays: this.delayDays,
            accountId: this.accountId || null,
            enquiryId: this.enquiryId || null,
            countryId: this.countryId || null,

            products: productData
        };

        // Only add optional fields if they have a value
        if (this.requestDate) {
            requestData.requestDate = this.requestDate;
        }
        if (this.receivedDate) {
            requestData.receivedDate = this.receivedDate;
        }
        if (this.personId) {
            requestData.personId = this.personId;
        }

        console.log('requestData', requestData);

        // Call Apex method to create the Sample Request
        createSampleRequest(requestData)
            .then(result => {
                console.log('Sample Request created successfully:', JSON.stringify(result));
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Sample_Request__c',
                        actionName: 'view'
                    }
                });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Sample Request created successfully!',
                    variant: 'success'
                }));
            })
            .catch(error => {
                console.error('Error creating Sample Request:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error creating Sample Request',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Sample_Request__c',
                actionName: 'list' // Shows the Leads list view
            }
        });
    }

    handleSubmitSampleIn() {
        console.log('handleSubmitSampleIn - Validating form for Sample In...');

        let missingProductName = false;
        let missingUnitId = false;

        // Validate all products
        for (let product of this.products) {
            if (!product.productName) {
                missingProductName = true;
            }
            if (!product.unitId) {
                missingUnitId = true;
            }
        }

        // Show appropriate error messages
        if (missingProductName) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select Product Name for all rows.',
                variant: 'error'
            }));
            return;
        }

        if (missingUnitId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select Sample Sent to Units for all rows.',
                variant: 'error'
            }));
            return;
        }

        // Prepare the product data for submission
        const productData = this.products.map(product => ({
            prodId: product.prodId || null,

            productName: product.productName,  // Assuming this is used somewhere else
            quantity: product.quantity,
            quality: product.quality,
            colourIndex: product.colourIndex,
            application: product.application,
            unitId: product.unitId,
            ci: product.ci,
            srefno: product.srefno,
            courierno: product.courierno,
            annualQtyOfBusiness: product.annualQtyOfBusiness ? product.annualQtyOfBusiness : null

        }));

        // Prepare request data
        const requestData = {
            recordId: this.recordId,
            samplein: this.sampleType,
            sampleOutSentTo: this.sampleOutSentTo,
            accountId: this.accountId || null,
            enquiryId: this.enquiryId || null,
            countryId: this.countryId || null,
            delayDays: this.delayDays,
            products: productData
        };

        if (this.receivedDate) {
            requestData.receivedDate = this.receivedDate;
        }
        if (this.personId) {
            requestData.personId = this.personId;
        }

        console.log('Submitting requestData:', JSON.stringify(requestData));

        // Call Apex method to create the Sample Request
        createSampleRequest(requestData)
            .then(result => {
                console.log('Sample Request created successfully:', result);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Sample_Request__c',
                        actionName: 'view'
                    }
                });
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Sample Request created successfully!',
                        variant: 'success'
                    })
                );
                // Optionally reset form
                // this.resetForm();
            })
            .catch(error => {
                console.error('Error creating Sample Request:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating Sample Request',
                        message: error.body.message || 'Something went wrong',
                        variant: 'error'
                    })
                );
            });
    }



    showErrorToast(error) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body.message,
                variant: 'error'
            })
        );
    }
}