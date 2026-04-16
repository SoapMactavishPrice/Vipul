import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import modalWidthInLwc from '@salesforce/resourceUrl/modalWidthInLwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addOpportunityLineItems from '@salesforce/apex/AddQuoteLineItem.addQuoteLineItems';
// import saveProductInterested from '@salesforce/apex/MarketingForm.saveProductInterested';
import getPicklistValues from '@salesforce/apex/MarketingForm.getPicklistValues';
import getExistingProducts from '@salesforce/apex/MarketingForm.getExistingProducts';
import findRecentPrices from '@salesforce/apex/AddQuoteLineItem.findRecentPricesForQuote';
import fetchListPrice from '@salesforce/apex/MarketingForm.fetchListPrice';
import getUserInfoWithLeadType from '@salesforce/apex/MarketingForm.getUserInfoWithLeadType'; // Apex method to fetch filtered picklist
import sendEmailNotification from '@salesforce/apex/SendEmail.sendEmailNotificationQuote';
import sendEmailToManagerForQuote from '@salesforce/apex/ManagerEmailSender.sendEmailToManagerForQuote';
import getQuoteData from '@salesforce/apex/AddQuoteLineItem.getQuoteData';
import fetchQuoteData from '@salesforce/apex/AddQuoteLineItem.fetchQuoteData';
import fetchAccountIdFromQuote from '@salesforce/apex/AddQuoteLineItem.fetchAccountIdFromQuote';
import getQualityForProductFromQuote from '@salesforce/apex/AddQuoteLineItem.getQualityForProductFromQuote';
import getquoteCurrency from '@salesforce/apex/AddQuoteLineItem.getquoteCurrency';




export default class AddQuoteLineItem extends NavigationMixin(LightningElement) {
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
    @api recordId;
    @track addAnswer = [];
    isLoading = false;
    @track currencyfilter;

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

    @track lastFivePrices = [];
    @track optionsProductFamily = [];
    @track products = [];

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
    incoTerms;
    optionsenquirytype = [];
    optionsincoTerms = [];


    // Example data for Enquiry Type and Incoterms
    data = [
        { field: 'Enquiry_Type__c', label: 'Domestic', value: 'Domestic' },
        { field: 'Enquiry_Type__c', label: 'International', value: 'International' },
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

    @wire(getquoteCurrency, { quoteId: '$recordId' })
    wiredCurrency({ error, data }) {
        if (data) {
            this.currencyfilter = "Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '" + data + "')";
        } else if (error) {
            console.error('Error fetching account currency', error);
        }
    }


    connectedCallback() {

        this.products = [];  // Ensure array is initialized

        loadStyle(this, modalWidthInLwc)
            .then(() => {
                console.log('CSS loaded successfully!');
            })
            .catch(error => {
                console.log('Error loading CSS:', error);
            });

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

        this.getExisting();

        const today = new Date();
        this.closeDate = new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0];  // closeDate + 30 days
        this.stage = 'New';  // Default stage to 'New'

        this.addAnswer = this.addAnswer.map((answer) => {
            return {
                ...answer,
                price: answer.price || 0 // If price is not defined, set it to 0
            };
        });

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





    @wire(getUserInfoWithLeadType)
    wiredUserInfo({ data, error }) {
        if (data) {

            this.optionsenquirytype = data.filteredPicklist;
            this.userDivision = data.userDivision;


            if (this.optionsenquirytype.length > 0) {

                const defaultEnquiryType = this.optionsenquirytype.find(option => option.value === 'Domestic');
                if (defaultEnquiryType) {
                    this.enquiryType1 = 'Domestic';
                } else {

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

    @wire(getQuoteData, { QuoteId: '$recordId' })
    wiredOpportunity({ data, error }) {
        if (data) {
            // Set incoTerms based on the Opportunity record data
            this.incoTerms = data.Inco_Terms__c || 'DDP'; // Default to 'DDP' if no value is found
            console.log('Fetched Incoterms:', this.incoTerms);
        } else if (error) {
            console.error('Error fetching Opportunity data:', error);
        }
    }


    handleShowPricesClick(event) {
        // Get the index from the clicked button's data attribute
        const clickedIndex = event.currentTarget.dataset.index;
        console.log('Clicked index:', clickedIndex);

        if (this.recordId) {
            this.isLoading = true;
            this.getOpportunityAccountId()
                .then(accountId => {
                    if (accountId && this.addAnswer[clickedIndex]) {
                        this.accountId = accountId;
                        const clickedProduct = this.addAnswer[clickedIndex];

                        // Open modal immediately
                        this.isOpenFileView = true;
                        this.currentProductIndex = clickedIndex;

                        // Fetch prices for the clicked product only
                        this.fetchLastFivePrices(accountId, clickedProduct.prodId);
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    this.isLoading = false;
                });
        }
    }

    // getAccountIdFromQuote() {
    //     return new Promise((resolve, reject) => {
    //         console.log('Fetching AccountId for Opportunity:', this.recordId);
    //         fetchAccountIdFromQuote({ quoteId: this.recordId })
    //             .then(result => {
    //                 if (result && result.AccountId) {
    //                     console.log('Fetched AccountId:', result.AccountId);
    //                     resolve(result.AccountId);
    //                 } else {
    //                     console.log('No AccountId found for the Opportunity:', this.recordId);
    //                     resolve(null);
    //                 }
    //             })
    //             .catch(error => {
    //                 console.error('Error fetching Opportunity data:', error);
    //                 reject(error);
    //             });
    //     });
    // }




    // Method to get the AccountId from the Quote record
    getAccountIdFromQuote() {
        return new Promise((resolve, reject) => {
            console.log('Fetching AccountId for Quote:', this.recordId); // Log the Quote ID
            // Make a call to Apex to fetch AccountId from the Quote
            fetchAccountIdFromQuote({ quoteId: this.recordId })
                .then(result => {
                    if (result) {
                        console.log('Fetched AccountId:', result); // Log the fetched AccountId
                        resolve(result); // Return the AccountId
                    } else {
                        console.log('No AccountId found for the Quote:', this.recordId); // Log if no AccountId is found
                        resolve(null); // If no AccountId found, resolve with null
                    }
                })
                .catch(error => {
                    console.error('Error fetching AccountId:', error); // Log the error if fetching fails
                    reject(error); // Reject the promise with the error
                });
        });
    }

    // Fetch the last 5 prices for the product and account
    // fetchLastFivePrices(accountId, productId) {
    //     findRecentPricesForProduct({ accountId: accountId, productId: productId })
    //         .then(result => {
    //             console.log(`Last 5 Prices for Product ID ${productId}:`, result);
    //             // You can then update the component state or show the prices in the UI
    //         })
    //         .catch(error => {
    //             console.error(`Error fetching prices for Product ID ${productId}:`, error);
    //         });
    // }

    // Close modal
    closeModal() {
        this.isModalOpen = false;
    }

    @track isOpenFileView = false;

    handleClose() {
        this.isOpenFileView = false;
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



    handleSave() {
        console.log('Opportunity ID:', this.recordId);
        console.log('Products before JSON stringify:', this.addAnswer);

        if (!this.validateData()) {
            console.log('Validation failed.');
            return; // Stop execution if validation fails
        }

        if (!this.recordId) {
            this.showToast('Error', 'Quote ID is required.', 'error');
            return;
        }

        if (!this.addAnswer || this.addAnswer.length === 0) {
            console.error('Products array is undefined or empty');
            this.showToast('Error', 'No products to add.', 'error');
            return;
        }

        this.isLoading = true;

        // Ensure JSON is valid
        let jsonString;
        try {
            jsonString = JSON.stringify(this.addAnswer);
            console.log('JSON Stringified Products:', jsonString);
        } catch (error) {
            console.error('Error serializing JSON:', error);
            this.showToast('Error', 'Invalid product data.', 'error');
            this.isLoading = false;
            return;
        }

        // Call the addOpportunityLineItems method (assuming it's working fine)
        addOpportunityLineItems({ quoteId: this.recordId, jsonLineItems: jsonString })
            .then(() => {
                this.showToast('Success', 'Products added to the Quote.', 'success');
                this.addAnswer = [];
                console.log('Products added successfully');

                // Now call the sendEmailNotificationQuote method
                sendEmailNotification({ quoteId: this.recordId })
                    .then(() => {
                        console.log('Email sent successfully');
                        this.showToast('Success', 'Email sent successfully', 'success');
                    })
                    .catch(error => {
                        console.error('Error sending email: ', error);
                        this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
                    });

                sendEmailToManagerForQuote({ quoteId: this.recordId })
                    .then(() => {
                        console.log('Email sent successfully');
                        this.showToast('Success', 'Email sent successfully', 'success');
                    })
                    .catch(error => {
                        console.error('Error sending email: ', error);
                        this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
                    });

                // Redirect to the Quote Record Page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Quote',
                        actionName: 'view'
                    }
                });

                // Reload the window after a short delay
                setTimeout(() => window.location.reload(), 1000);
            })
            .catch(error => {
                console.error('Error while adding products:', error);
                this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // navigateToOpportunity(recordId) {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: { recordId, objectApiName: 'Opportunity', actionName: 'view' }
    //     });
    // }

    getErrorMessage(error) {
        return error.body ? error.body.message : JSON.stringify(error);
    }


    // Helper function to show error or success toast messages
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





    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }



    @track currencyCode = '';
    optionsProductFamily = [];
    optionsPackaging = [];
    optionsPackaging1 = [];

    // Wire the Apex method to fetch picklist values
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

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }


        const pbe = selectedRecord;


        if (this.addAnswer && this.addAnswer[index]) {

            this.addAnswer[index] = {
                ...this.addAnswer[index],
                prodId: pbe.Id,
                prodName: pbe.Name,
                prodCode: pbe.ProductCode
            };


            this.fetchProductListPrice(pbe.Id, index);
            this.fetchProductQualityForQuote(pbe.Id, index)
        }

        console.log('Updated Field:', index, this.addAnswer[index]);
    }

    fetchProductQualityForQuote(productId, index) {
        console.log('this.recordId (Quote ID):', this.recordId, 'Product ID:', productId, 'Account ID:', this.opportunityAccountId);

        // Call the server-side method to get the product quality based on the Quote's AccountId
        getQualityForProductFromQuote({
            quoteId: this.recordId,  // The quote ID (this.recordId refers to the current Quote)
            productId: productId     // The product ID
        })
            .then(result => {
                console.log('Received quality:', result);

                // If quality is found, update the corresponding answer
                if (result) {
                    this.addAnswer[index].quality = result;
                    this.addAnswer = [...this.addAnswer];  // Trigger UI update by spreading the array
                    console.log('Quality updated in UI:', this.addAnswer[index]);
                }
            })
            .catch(error => {
                console.error('Error fetching quality:', error);
            });
    }


    fetchProductListPrice(productId, index) {

        fetchListPrice({ productId: productId })
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
            price: 0,
            quality: '',
            packaging: '',
            CommissionType: '',
            commissionval: '',
            commissionper: '',
            totalprice: '',
            finalprice: '',
            totalpricefinal: '',
        }
    ];

    // connectedCallback() {
    //     this.getExisting();

    //     const today = new Date();
    //     this.closeDate = new Date(today.setDate(today.getDate() + 30)).toISOString().split('T')[0];  // closeDate + 30 days
    //     this.stage = 'New';  // Default stage to 'New'
    // }

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

    addAnswerItem() {
        let validate = this.validateData();

        if (validate) {
            this.tempIndex = this.tempIndex + 1;
            const newAnswer = {
                index: this.tempIndex,
                prodFamily: '',
                prodId: '',
                prodName: '',
                prodCode: '',
                volume: '',
                price: 0,
                // packaging: '',

            };
            this.addAnswer.push(newAnswer);
        } else {
            console.log('Validation failed');
        }
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




    calculatePrice(data) {
        let temp = JSON.parse(data);
        let totalPrice = Number(temp.price);


        if (isNaN(totalPrice) || totalPrice <= 0) {
            console.error('Invalid price');
            return totalPrice;
        }


        if (temp.CommissionType === 'Value') {
            const commissionValue = Number(temp.commissionval);
            if (isNaN(commissionValue) || commissionValue < 0) {
                console.error('Invalid commission value');
            } else {
                totalPrice += commissionValue;
            }
        } else if (temp.CommissionType === 'Percent') {
            const commissionPercent = Number(temp.commissionper);
            if (isNaN(commissionPercent) || commissionPercent <= 0) {
                console.error('Invalid commission percentage');
            } else {

                let commissionAmount = (commissionPercent / 100) * totalPrice;
                totalPrice += commissionAmount;
            }
        }

        console.log('totalPrice ->', totalPrice);
        return totalPrice;
    }





    handleScoreChange(event) {
        let label = event.target.dataset.label; // Field name (like 'price', 'CommissionType', etc.)
        let index = event.target.dataset.index; // Current index in the array

        console.log('Field Label:', label); // For debugging

        // Update the value in the array based on the input field
        this.addAnswer[index][label] = event.target.value;

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


        return finalprice.toFixed(2);
    }

    calculateFinalPrice1(index) {
        const answer = this.addAnswer[index];


        const finalprice = parseFloat(answer.finalprice) || 0;


        const volume = parseFloat(answer.volume) || 0;


        let totalpricefinal = finalprice * volume;


        return totalpricefinal.toFixed(2);
    }



    validateData() {
        let validate = true;
        for (let element of this.addAnswer) {

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
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }
}