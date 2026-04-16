import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import modalWidthInLwc from '@salesforce/resourceUrl/modalWidthInLwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addOpportunityLineItems from '@salesforce/apex/AddOppLineItem.addOpportunityLineItems';
// import saveProductInterested from '@salesforce/apex/MarketingForm.saveProductInterested';
import getPicklistValues from '@salesforce/apex/MarketingForm.getPicklistValues';
import getExistingProducts from '@salesforce/apex/MarketingForm.getExistingProducts';
import findRecentPrices from '@salesforce/apex/AddOppLineItem.findRecentPrices';
import fetchListPrice from '@salesforce/apex/MarketingForm.fetchListPrice';
import getUserInfoWithLeadType from '@salesforce/apex/MarketingForm.getUserInfoWithLeadType';
import sendEmailNotification from '@salesforce/apex/SendEmail.sendEmailNotification';
import sendEmailNotification1 from '@salesforce/apex/ManagerEmailSender.sendEmailToManager';
import getOpportunityData from '@salesforce/apex/AddOppLineItem.getOpportunityData';
import fetchOpportunityData from '@salesforce/apex/AddOppLineItem.fetchOpportunityData';
import getQualityForProduct from '@salesforce/apex/AddOppLineItem.getQualityForProduct';
import getenquiryCurrency from '@salesforce/apex/AddOppLineItem.getenquiryCurrency';
import { getRecord } from 'lightning/uiRecordApi';


const OPPORTUNITY_FIELDS = ['Opportunity.AccountId'];



export default class AddOppLineItem extends NavigationMixin(LightningElement) {
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
    opportunityAccountId
    hasIncoTerms = false;
    @track isOpenFileView = false;
    @track lastFivePrices = [];
    @track currentProductIndex = 0;
    @track showProductSelector = false;
    @track isLoading = false;


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
    productId = '';

    enquiryType1;
    incoTerms;
    optionsenquirytype = [];
    optionsincoTerms = [];
    @track currencyfilter;


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


    @wire(getenquiryCurrency, { enquiryId: '$recordId' })
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

            // this.incoTerms = this.optionsincoTerms.length > 0 ? this.optionsincoTerms[0].value : 'DDP';
        } else if (error) {
            console.error('Error fetching user info: ', error);
        }
    }

    // @wire(getOpportunityData, { opportunityId: '$recordId' })
    // wiredOpportunity({ data, error }) {
    //     if (data) {
    //         // Set incoTerms based on the Opportunity record data
    //         this.incoTerms = data.Inco_Terms__c || ''; 
    //         console.log('Fetched Incoterms:', this.incoTerms);
    //     } else if (error) {
    //         console.error('Error fetching Opportunity data:', error);
    //     }
    // }


    // handleShowPricesClick() {
    //     if (this.recordId) {
    //         this.getOpportunityAccountId()
    //             .then(accountId => {
    //                 if (accountId) {
    //                     this.accountId = accountId;
    //                     this.addAnswer.forEach(answer => {
    //                         if (answer.prodId) {
    //                             console.log(`Fetching prices for Product ID: ${answer.prodId}`);
    //                             this.fetchLastFivePrices(this.accountId, answer.prodId);
    //                         } else {
    //                             console.log('No Product ID found for one of the selected products.');
    //                         }
    //                     });
    //                 } else {
    //                     console.log('No AccountId found for the Opportunity.');
    //                 }
    //             })
    //             .catch(error => {
    //                 console.log('Error fetching Opportunity AccountId:', error);
    //             });
    //     }
    // }

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

    getOpportunityAccountId() {
        return new Promise((resolve, reject) => {
            console.log('Fetching AccountId for Opportunity:', this.recordId);
            fetchOpportunityData({ opportunityId: this.recordId })
                .then(result => {
                    if (result && result.AccountId) {
                        console.log('Fetched AccountId:', result.AccountId);
                        resolve(result.AccountId);
                    } else {
                        console.log('No AccountId found for the Opportunity:', this.recordId);
                        resolve(null);
                    }
                })
                .catch(error => {
                    console.error('Error fetching Opportunity data:', error);
                    reject(error);
                });
        });
    }



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
                console.log('Last 5 Prices for Product ID:', productId); // Log the Product ID being used
                console.log('Fetched Last 5 Prices:', this.lastFivePrices); // Log the result from Apex
            })
            .catch(error => {
                console.error('Error fetching prices for Product ID:', productId, error); // Log error
            });
    }




    // @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    // wiredOpportunity({ error, data }) {
    //     if (data) {
    //         this.opportunityAccountId = data.fields.AccountId.value;
    //         console.log('Account ID loaded:', this.opportunityAccountId);
    //     } else if (error) {
    //         console.error('Error loading opportunity account:', error);
    //     }

    //     if (data) {
    //         // Set incoTerms based on the Opportunity record data
    //         this.incoTerms = data.Inco_Terms__c || 'DDP'; // Default to 'DDP' if no value is found
    //         console.log('Fetched Incoterms:', this.incoTerms);
    //     } else if (error) {
    //         console.error('Error fetching Opportunity data:', error);
    //     }
    // }

    // 2. Consolidated lookup handler
    // async handleLookupSelection(event) {
    //     try {
    //         const index = event.target.dataset.index;
    //         const productId = event.detail.recordId;
    //         const productName = event.detail.selectedRecord?.Name || '';

    //         console.log('Product selected - ID:', productId, 'Index:', index);

    //         if (!productId) {
    //             console.error('No product ID received');
    //             return;
    //         }

    //         // Update product info
    //         this.updateProductInfo(index, productId, productName);
    //         this.fetchProductQuality(productId, index)

    //         // Fetch quality in parallel with price
    //         await Promise.all([
    //             this.fetchProductListPrice(productId, index),
    //             //   this.fetchProductQuality(productId, index)
    //         ]);

    //     } catch (error) {
    //         console.error('Error in product selection:', error);
    //     }
    // }

    updateProductInfo(index, productId, productName) {
        this.addAnswer[index] = {
            ...this.addAnswer[index],
            prodId: productId,
            prodName: productName,
            quality: '' // Reset quality when product changes
        };
        this.addAnswer = [...this.addAnswer]; // Trigger reactivity
        console.log('Product info updated:', this.addAnswer[index]);
    }

    // 3. Specialized quality fetcher
    // async fetchProductQuality(productId, index) {
    //     console.log('this.recordId,', this.recordId, productId, this.opportunityAccountId);


    //     try {
    //         console.log('Fetching quality for product:', productId);

    //         const quality = await getQualityForProduct({
    //             opportunityId: this.recordId,
    //             productId: productId,
    //             accountId: this.opportunityAccountId
    //         });

    //         console.log('Received quality:', quality);

    //         if (quality) {
    //             this.addAnswer[index].quality = quality;
    //             this.addAnswer = [...this.addAnswer]; // Trigger reactivity
    //             console.log('Quality updated in UI:', this.addAnswer[index]);
    //         }
    //     } catch (error) {
    //         console.error('Quality fetch failed:', error);
    //     }
    // }

    // Your existing price fetch method
    fetchProductListPrice(productId, index) {
        // ... your existing implementation ...
    }

    handleSave() {
        console.log('Opportunity ID:', this.recordId);
        console.log('Products before JSON stringify:', this.addAnswer);

        // Validate Opportunity ID
        if (!this.recordId) {
            this.showToast('Error', 'Opportunity ID is required.', 'error');
            return;
        }

        // Validate Products data using validateData()
        let validate = this.validateData(); // This is where the validation now happens before save
        if (!validate) {
            console.log('Validation failed');
            return;
        }
        // Validate Products data
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

        // Add Opportunity Line Items
        addOpportunityLineItems({ opportunityId: this.recordId, jsonLineItems: jsonString })
            .then((result) => {
                this.showToast('Success', 'Products added to the Opportunity.', 'success');
                this.addAnswer = [];
                console.log('Opportunity line items added successfully.');

                // Send email notifications (after success)
                sendEmailNotification({ oppId: this.recordId })
                    .then(() => {
                        console.log('Email sent successfully for Opportunity');
                    })
                    .catch(error => {
                        console.error('Error sending email notification 1: ', error);
                    });

                sendEmailNotification1({ oppId: this.recordId })
                    .then(() => {
                        console.log('Email sent successfully for Opportunity (second notification)');
                    })
                    .catch(error => {
                        console.error('Error sending email notification 2: ', error);
                    });

                // Redirect to the Opportunity Record Page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Opportunity',
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

    @api recordId;

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
            // Clear quality if no product is selected
            if (this.addAnswer && this.addAnswer[index]) {
                this.addAnswer[index].quality = null; // or ''
                this.addAnswer = [...this.addAnswer]; // Trigger reactivity
            }
            return;
        }

        const pbe = selectedRecord;

        if (this.addAnswer && this.addAnswer[index]) {
            // Update product details
            this.addAnswer[index] = {
                ...this.addAnswer[index],
                prodId: pbe.Id,
                prodName: pbe.Name,
                prodCode: pbe.ProductCode
            };

            // Fetch the price and quality
            this.fetchProductListPrice(pbe.Id, index);
            this.fetchProductQuality(pbe.Id, index);
            this.updateProductInfo(pbe.Id, index);
        }

        console.log('Updated Field:', index, this.addAnswer[index]);
    }


    fetchProductQuality(productId, index) {
        console.log('this.recordId,', this.recordId, productId, this.opportunityAccountId);
        getQualityForProduct({
            opportunityId: this.recordId,
            productId: productId,
            accountId: this.opportunityAccountId
        }).then(result => {
            console.log('Received quality:', result);
            if (result) {
                this.addAnswer[index].quality = result;
                this.addAnswer = [...this.addAnswer];
                console.log('Quality updated in UI:', this.addAnswer[index]);
            }
        })
    }

    removeAnswer(event) {
        const index = event.target.dataset.index;
        console.log('Removing product at index:', index);

        // Remove the item from addAnswer array
        this.addAnswer.splice(index, 1);

        // Trigger reactivity
        this.addAnswer = [...this.addAnswer];

        // Optionally log the updated array
        console.log('Updated addAnswer after removal:', this.addAnswer);
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
            price: '',
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
        // Remove validation from this method
        this.tempIndex = this.tempIndex + 1;
        const newAnswer = {
            index: this.tempIndex,
            prodFamily: '',
            prodId: '',
            prodName: '',
            prodCode: '',
            volume: '',
            price: '',
            quality: '',
            // packaging: '',

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
                this.addAnswer[index].freightval = ''; // Reset Freight Value
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
    @wire(getOpportunityData, { opportunityId: '$recordId' })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.hasIncoTerms = !!data.Inco_Terms__c;
            this.incoTerms = data.Inco_Terms__c;
            if (!this.hasIncoTerms) {
                const errorMsg = 'Inco Terms must be specified on the Enquiry before adding Products.';
                this.showToast('Error', errorMsg, 'error');
                // Redirect ONLY if Inco_Terms__c is empty
                setTimeout(() => this.handleCancel(), 1000); // 1-sec delay for toast
            }
            // If Inco_Terms__c is valid, DO NOT redirect (stay on page)
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }



    // Manual Cancel button (for user-triggered navigation)
    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }

    // Show toast message
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }
}