import { LightningElement, track, wire, api } from 'lwc';
import createSampleOutRequest from '@salesforce/apex/SampleOutRequestEnquiry.createSampleOutRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountAndCountryDetails from '@salesforce/apex/SampleOutRequestEnquiry.getAccountAndCountryDetails';
import getAccountCurrency from '@salesforce/apex/MarketingForm.getAccountCurrency';
import getaccountdetails from '@salesforce/apex/SampleOutRequestEnquiry.getopptails';
import getOpportunityAccountAndCountry from '@salesforce/apex/SampleOutRequestEnquiry.getOpportunityAccountAndCountry';
import { NavigationMixin } from 'lightning/navigation';
import getCurrentUserName from '@salesforce/apex/MarketingForm.getCurrentUserName';
import getUnitOfMeasureOptions from '@salesforce/apex/SampleOutRequestEnquiry.getUnitOfMeasureOptions';
import fetchCI from '@salesforce/apex/MarketingForm.fetchCI';

export default class NewSampleOutEnquiry extends NavigationMixin(LightningElement) {

    opportunity;
    error;
    @track addAnswer = [];
    @track sampleOutSentTo = ''; // Picklist for Samples_Request_Sent_to__c
    @track sampleOutSentToOptions = []; // Options for Samples_Request_Sent_to__c
    @track requestDate = new Date().toISOString().split('T')[0]; // Date for Request_Date__c
    @track receivedDate = ''; // Date for Received_Date__c
    @track personId = ''; // Person (lookup to User)
    @track filledByName = '';
    @track accountId = ''; // Company (lookup to Account)
    @track enquiryId = '';
    @track countryId = ''; // Country (lookup to Country__c)
    @track delayDays = 0; // Delay Days
    @track companyOptions = [];  // List of Companies to show in search
    @track countryOptions = [];  // List of Countries to show in search
    @track accountCurrency = '';
    @track isSubmitting = false;

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
            New_Product__c: false,
            New_Product_Name__c: '',
            New_Product_Description__c: '',
            New_Product_CI_No__c: ''

        }
    ];
    // @track recordId = '';
    @api recordId;
    unitOfMeasureOptions = [];
    unitOfMeasure = '';

    get validAccountId() {
        return this.accountId && this.accountId.length === 18 ? this.accountId : undefined;
    }

    @track optionsleadcurrency = [
        { label: 'USD', value: 'USD' },
        { label: 'INR', value: 'INR' },
        { label: 'EUR', value: 'EUR' }
        // Add all currencies expected from Account.CurrencyIsoCode
    ];

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

    @wire(getAccountCurrency, { accountId: '$accountId' })
    wiredAccountCurrency({ data, error }) {
        if (data) {
            this.accountCurrency = data;
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

    // Handle checkbox change for New Product
    handleCheckboxChange(event) {
        const index = event.target.dataset.index;
        const isChecked = event.target.checked;

        this.products[index] = {
            ...this.products[index],
            New_Product__c: isChecked,
            // Clear product fields when switching to new product
            prodId: isChecked ? '' : this.products[index].prodId,
            prodName: isChecked ? '' : this.products[index].prodName,
            prodCode: isChecked ? '' : this.products[index].prodCode,
            // Clear new product fields when switching to existing product
            New_Product_Name__c: isChecked ? this.products[index].New_Product_Name__c : '',
            New_Product_CI_No__c: isChecked ? this.products[index].New_Product_CI_No__c : ''
        };
        // Force UI update
        this.products = [...this.products];
        console.log('this.products:', this.products)
    }

    handleTextInputChange(event) {
        const index = event.target.dataset.index;
        this.products[index] = {
            ...this.products[index],
            New_Product_Name__c: event.target.value
        };
    }

    handleCIInputChange(event) {
        const index = event.target.dataset.index;
        this.products[index] = {
            ...this.products[index],
            New_Product_CI_No__c: event.target.value
        };
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
            New_Product__c: false
        };

        console.log('Updated Product:', index, this.products[index]);

        this.fetchCIForProduct(selectedRecord.Id, index);
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




    handleSampleTypeChange(event) {
        this.sampleType = event.detail.value;
        this.isPageLoad = false;
        console.log('Sample Type changed to:', this.sampleType);

        if (this.recordId) {
            this.fetchAccountAndCountry();  // Fetch Account and Country when sampleType changes
        }

    }

    connectedCallback() {
        getOpportunityAccountAndCountry({ opportunityId: this.recordId })
            .then(result => {
                // Set the Account and Country values after fetching them
                this.accountId = result.accountId;
                this.companyName = result.accountName;
                this.countryId = result.countryId;
                this.countryName = result.countryName;
                this.enquiryId = result.enquiryId;

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
        } else if (fieldName === 'accountCurrency') {
            this.accountCurrency = event.target.value;
            console.log('Currency changed to:', this.accountCurrency);
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


    // handleUnitChange(event) {
    //     try {
    //         const index = event.target.dataset.index;
    //         const selectedRecord = event.detail;

    //         if (!selectedRecord) {
    //             console.log("No unit selected");
    //             return;
    //         }

    //         // Update the products array
    //         this.products[index] = {
    //             ...this.products[index],
    //             unitId: selectedRecord.recordId,
    //             unitName: selectedRecord.name
    //         };

    //         // Force reactivity
    //         this.products = [...this.products];

    //         console.log(`Unit selected for product ${index}:`, selectedRecord);
    //     } catch (error) {
    //         console.error('Error handling unit change:', error);
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Error',
    //                 message: 'Failed to select unit',
    //                 variant: 'error',
    //                 mode: 'sticky'
    //             })
    //         );
    //     }
    // }


    handleUnitSelected(event) {
        try {
            const index = event.target.dataset.index;
            const { unitId, unitName } = event.detail;

            if (!unitId) {
                console.log('No unit selected');
                return;
            }

            this.products[index] = {
                ...this.products[index],
                unitId: unitId,
                unitName: unitName
            };

            // Force reactivity
            this.products = [...this.products];

            console.log(`✅ Unit selected for product ${index}:`, unitId, unitName);
        } catch (error) {
            console.error('Error handling unit select:', error);
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

    handleUnitCleared(event) {
        const index = event.target.dataset.index;

        this.products[index] = {
            ...this.products[index],
            unitId: null,
            unitName: null
        };

        this.products = [...this.products];

        console.log(`❌ Unit cleared for product ${index}`);
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
                New_Product__c: false,
                New_Product_Name__c: '',
                New_Product_Description__c: '',
                New_Product_CI_No__c: ''

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
        if (this.isSubmitting) {
            return;
        }

        this.isSubmitting = true;

        console.log('handleSubmitSampleOut - Validating form for Sample Out...');

        const allProductsHaveUnitId = this.products.every(product => product.unitId);


        if (!allProductsHaveUnitId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select a Sample Sent to Units for all rows.',
                variant: 'error'
            }));
            this.isSubmitting = false;
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
            New_Product__c: product.New_Product__c,
            New_Product_Name__c: product.New_Product_Name__c,
            New_Product_CI_No__c: product.New_Product_CI_No__c

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
            accountCurrency: this.accountCurrency,

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
        createSampleOutRequest(requestData)
            .then(result => {
                console.log('Sample Request created successfully:', JSON.stringify(result));
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Sample_Out_Request__c',
                        actionName: 'view'
                    }
                });
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Sample Request created successfully!',
                    variant: 'success'
                }));
                setTimeout(() => window.location.reload(), 1000);
            })
            .catch(error => {
                console.error('Error creating Sample Request:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error creating Sample Request',
                    message: error.body.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Sample_Out_Request__c',
                actionName: 'list' // Shows the Leads list view
            }
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