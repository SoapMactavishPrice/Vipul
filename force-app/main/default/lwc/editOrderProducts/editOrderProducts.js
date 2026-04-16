import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/OpportunityLineItemController.getOrderItems';
import updateOpportunityLineItems from '@salesforce/apex/OpportunityLineItemController.updateOrderItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_LINE_ITEM_OBJECT from '@salesforce/schema/QuoteLineItem';
import MARGIN_TYPE_FIELD from '@salesforce/schema/OrderItem.Margin_Type__c';
import COMMISSION_TYPE_FIELD from '@salesforce/schema/OrderItem.Commission_Type__c';
import PACKAGING_FIELD from '@salesforce/schema/OrderItem.Packaging__c';
import { NavigationMixin } from 'lightning/navigation';
import modalWidthInLwc from '@salesforce/resourceUrl/modalWidthInLwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import CURRENCY_FIELD from '@salesforce/schema/Order.CurrencyIsoCode';
import { getRecord } from 'lightning/uiRecordApi';
import Quantity from '@salesforce/schema/Asset.Quantity';
import sendQuoteStatusEmails from '@salesforce/apex/QuoteStatusEmailHelper.sendQuoteStatusEmails';


export default class OpportunityLineItemsLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track lineItems = [];
    @track error;
    @track isLoading = false;
    @track marginTypeOptions = [];
    @track commissionTypeOptions = [];
    @track packagingTypeOptions = [];
    wiredLineItems;
    recordTypeId;
    @track currencyIsoCode;
    incoTermsValue;
    @track purchasePriceStatusOptions = [
        { label: 'None', value: 'None' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ]; // Hardcoded options for Purchase_Price_Status__c


    // Wire to get the Opportunity record and fetch the CurrencyIsoCode
    @wire(getRecord, { recordId: '$recordId', fields: [CURRENCY_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            // Store the currency code from Opportunity
            this.currencyIsoCode = data.fields.CurrencyIsoCode.value;
        } else if (error) {
            console.error('Error fetching Opportunity data:', error);
        }
    }

    // Getter to dynamically return the header text
    get listPriceHeader() {
        // Use the currencyIsoCode for the header text, defaulting to USD if not available
        return `List Price (${this.currencyIsoCode || 'USD'})`;
    }

    get salesPriceHeader() {
        // Use the currencyIsoCode for the header text, defaulting to USD if not available
        return `Sales Price (${this.currencyIsoCode || 'USD'})`;
    }

    get conPriceHeader() {
        // Use the currencyIsoCode for the header text, defaulting to USD if not available
        return `Con Purc Price (${this.currencyIsoCode || 'USD'})`;
    }



    // Wire to fetch Opportunity Line Items for the given Opportunity Id
    @wire(getOpportunityLineItems, { OrderId: '$recordId' })
    wiredLineItemsResult({ error, data }) {
        if (data) {
            this.lineItems = data.map(item => ({
                ...item,
                // Set default Purchase_Price_Status__c value if not set
                Purchase_Price_Status__c: item.Purchase_Price_Status__c || 'Approved', // defaulting to "Approved"
                Reject_Reason__c: item.Reject_Reason__c || '',
                showRejectReason: item.Purchase_Price_Status__c === 'Rejected' // Calculate whether Reject Reason should be visible
            }));
        } else if (error) {
            console.error('Error fetching Opportunity Line Items:', error);
        }
    }

    // Handle purchase price status change
    handlePurchasePriceStatusChange(event) {
        const value = event.detail.value;
        const index = event.target.dataset.index;

        // Update the line item with the selected Purchase_Price_Status__c
        this.lineItems[index].Purchase_Price_Status__c = value;

        // Clear Reject Reason if status is not "Rejected"
        if (value !== 'Rejected') {
            this.lineItems[index].Reject_Reason__c = ''; // Clear Reject Reason when status is not Rejected
        }

        // Update visibility of Reject Reason based on selected status
        this.lineItems[index].showRejectReason = value === 'Rejected';

        // Disable combobox if ListPrice is greater than 0
        this.lineItems[index].isDisabled = this.lineItems[index].ListPrice > 0;
    }


    // Handle Reject Reason change
    handleRejectReasonChange(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;

        // Update the Reject_Reason__c in the lineItems array for the corresponding index
        this.lineItems[index].Reject_Reason__c = value;
    }

    connectedCallback() {
        // Load the external CSS for modal
        loadStyle(this, modalWidthInLwc)
            .then(() => {
                console.log('CSS loaded successfully!');
            })
            .catch(error => {
                console.log('Error loading CSS:', error);
            });
    }

    // Get Object Info
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_LINE_ITEM_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId || '012000000000000AAA';
        } else if (error) {
            console.error('Error fetching object info:', error);
        }
    }

    // Get Picklist Values
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: MARGIN_TYPE_FIELD })
    wiredMarginTypeValues({ error, data }) {
        if (data) {
            this.marginTypeOptions = data.values;
        } else if (error) {
            console.error('Error fetching Margin_Type__c picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: COMMISSION_TYPE_FIELD })
    wiredCommissionTypeValues({ error, data }) {
        if (data) {
            this.commissionTypeOptions = data.values;
        } else if (error) {
            console.error('Error fetching Commission_Type__c picklist values:', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PACKAGING_FIELD })
    wiredPakagingTypeValues({ error, data }) {
        if (data) {
            this.packagingTypeOptions = data.values;
        } else if (error) {
            console.error('Error fetching Packaging__c picklist values:', error);
        }
    }


    @wire(getOpportunityLineItems, { OrderId: '$recordId' })
    wiredLineItemsResult({ error, data }) {
        if (data) {
            console.log('data', data);


            this.lineItems = data.map(item => {
                const isMarginDisabled = item.ListPrice > 0;


                const incoTerms = item.Order.Inco_Terms__c || 'undefined';


                const isFreightValueDisabled = !["CFR", "CIF", "CPT", "CIP", "DAP", "DDP"].includes(incoTerms);


                console.log(`Inco_Terms__c: ${incoTerms}, isFreightValueDisabled: ${isFreightValueDisabled}`);

                // Return the modified line item with flags
                return {
                    ...item,
                    isConverterDisabled: item.ListPrice > 0,
                    isConvertedPriceDisabled: item.ListPrice > 0,
                    isMarginTypeDisabled: isMarginDisabled,
                    isMarginValueDisabled: isMarginDisabled || !item.Margin_Type__c || item.Margin_Type__c === "Percent",
                    isMarginPercentDisabled: isMarginDisabled || !item.Margin_Type__c || item.Margin_Type__c === "Value",
                    isCommissionValueDisabled: !item.Commission_Type__c || item.Commission_Type__c === "Percent",
                    isCommissionPercentDisabled: !item.Commission_Type__c || item.Commission_Type__c === "Value",
                    isFreightValueDisabled: isFreightValueDisabled,

                    // Disable Purchase_Price_Status__c combobox if ListPrice > 0
                    isPurchasePriceStatusDisabled: item.ListPrice > 0
                };
            });
        } else if (error) {
            this.error = error;
            this.lineItems = [];
        }
    }





    handleChange(event) {
        const { field, index } = event.target.dataset;
        let value = event.target.value;

        // Handle checkbox field (Rejected_Purchase_Price__c)
        if (event.target.type === 'checkbox') {
            // Handle Rejected_Purchase_Price__c specifically, just like any other checkbox
            value = event.target.checked;  // true or false
        }

        // Update the field value in the lineItems array
        this.lineItems[index][field] = value;

        // If Purchase_Price_Status__c is unchecked, clear the reject reason
        if (field === 'Purchase_Price_Status__c' && value !== 'Rejected') {
            this.lineItems[index].Reject_Reason__c = '';  // Clear Reject Reason if not 'Rejected'
        }

        if (this.lineItems[index].ListPrice > 0) {
            this.lineItems[index].isConverterDisabled = true;
            this.lineItems[index].isConvertedPriceDisabled = true;
        } else {
            this.lineItems[index].isConverterDisabled = false;
            this.lineItems[index].isConvertedPriceDisabled = false;
        }

        // Update the field value
        this.lineItems[index][field] = value;

        // Disable Margin_Type__c combobox if ListPrice is greater than 0
        if (this.lineItems[index].ListPrice > 0) {
            this.lineItems[index].isMarginTypeDisabled = true;
        } else {
            this.lineItems[index].isMarginTypeDisabled = false;
        }

        // Update the field value
        this.lineItems[index][field] = value;

        // Calculate Base Price (Quantity * Unit Price)
        const quantity = parseFloat(this.lineItems[index].Quantity) || 0;
        const unitPrice = parseFloat(this.lineItems[index].UnitPrice) || 0;

        // Calculate Commission based on Commission Type (Value or Percent)
        let commissionAmount = 0;
        if (this.lineItems[index].Commission_Type__c === 'Percent') {
            const commissionPercent = parseFloat(this.lineItems[index].Commission_Percent__c) || 0;
            commissionAmount = (commissionPercent / 100) * (quantity * unitPrice);
        } else if (this.lineItems[index].Commission_Type__c === 'Value') {
            commissionAmount = parseFloat(this.lineItems[index].Commission_Value__c) || 0;
        }

        // Calculate Margin based on Margin Type (Percent or Value)
        let marginAmount = 0;
        const marginPercent = parseFloat(this.lineItems[index].Margin_Percent__c) || 0;
        const marginValue = parseFloat(this.lineItems[index].Margin_Value__c) || 0;

        if (this.lineItems[index].Margin_Type__c === 'Percent') {
            marginAmount = (marginPercent / 100) * (quantity * unitPrice);
        } else if (this.lineItems[index].Margin_Type__c === 'Value') {
            marginAmount = marginValue;
        }

        // Set the CalculatedPrice field (this value is before adding Freight Value)
        this.lineItems[index].Total_Price_with_Inco_Terms__c = unitPrice + commissionAmount;

        // Include Freight Value (if any)
        const freightValue = parseFloat(this.lineItems[index].Freight_Value__c) || 0;

        // Calculate Final Price (Calculated Price + Freight Value)
        this.lineItems[index].Final_Price__c = this.lineItems[index].Total_Price_with_Inco_Terms__c + freightValue;

        // Calculate the Total Price (Final Price * Quantity)
        this.lineItems[index].Total_Price__c = this.lineItems[index].Final_Price__c * quantity;

        // Calculate Converted Purchase Price (Purchase Price / Converter)
        if (field === "Purchase_Price_in_INR__c" || field === "Converter__c") {
            const purchasePrice = parseFloat(this.lineItems[index].Purchase_Price_in_INR__c) || 0;
            const converter = parseFloat(this.lineItems[index].Converter__c) || 0;

            // Avoid division by zero
            if (converter !== 0) {
                let convertedPrice = purchasePrice / converter;

                // Format the result to 2 decimal places
                this.lineItems[index].Converted_Purchase_Price__c = convertedPrice.toFixed(2);
            } else {
                this.lineItems[index].Converted_Purchase_Price__c = "0.00"; // Handle division by zero case
            }

            // Now update the Unit Price based on the Converted Purchase Price and Margin (if any)
            this.updateUnitPriceBasedOnMargin(index);
        }

        // Update UnitPrice if Margin Type or Margin Value/Percent changes
        if (field === "Margin_Type__c" || field === "Margin_Value__c" || field === "Margin_Percent__c") {
            this.updateUnitPriceBasedOnMargin(index);
        }

        // Freeze fields based on Margin Type selection
        if (field === "Margin_Type__c") {
            if (!value) {
                this.lineItems[index].isMarginValueDisabled = true;
                this.lineItems[index].isMarginPercentDisabled = true;
                this.lineItems[index].Margin_Value__c = null;
                this.lineItems[index].Margin_Percent__c = null;
            } else if (value === "Value") {
                this.lineItems[index].isMarginValueDisabled = false;
                this.lineItems[index].isMarginPercentDisabled = true;
                this.lineItems[index].Margin_Percent__c = null; // Clear Margin Percent
            } else if (value === "Percent") {
                this.lineItems[index].isMarginValueDisabled = true;
                this.lineItems[index].isMarginPercentDisabled = false;
                this.lineItems[index].Margin_Value__c = null; // Clear Margin Value
            }
        }

        // Freeze fields based on Commission Type selection
        if (field === "Commission_Type__c") {
            if (!value) {
                this.lineItems[index].isCommissionValueDisabled = true;
                this.lineItems[index].isCommissionPercentDisabled = true;
                this.lineItems[index].Commission_Value__c = null;
                this.lineItems[index].Commission_Percent__c = null;
            } else if (value === "Value") {
                this.lineItems[index].isCommissionValueDisabled = false;
                this.lineItems[index].isCommissionPercentDisabled = true;
                this.lineItems[index].Commission_Percent__c = null; // Clear Commission Percent
            } else if (value === "Percent") {
                this.lineItems[index].isCommissionValueDisabled = true;
                this.lineItems[index].isCommissionPercentDisabled = false;
                this.lineItems[index].Commission_Value__c = null; // Clear Commission Value
            }
        }

        // if (field === "Freight_Value__c") {

        //     this.lineItems[index].isFreightValueDisabled = !["CFR", "CIF", "CPT", "CIP", "DAP", "DDP"].includes(value);
        // }
        // Trigger reactivity by setting the updated lineItems
        this.lineItems = [...this.lineItems];
    }


    // Helper function to update UnitPrice based on Converted_Purchase_Price__c and Margin
    updateUnitPriceBasedOnMargin(index) {
        const convertedPrice = parseFloat(this.lineItems[index].Converted_Purchase_Price__c) || 0;
        const marginType = this.lineItems[index].Margin_Type__c;
        const marginValue = parseFloat(this.lineItems[index].Margin_Value__c) || 0;
        const marginPercent = parseFloat(this.lineItems[index].Margin_Percent__c) || 0;

        let newUnitPrice = 0;

        if (marginType === 'Percent') {
            // Calculate Unit Price as Converted Price + Margin Percent of Converted Price
            newUnitPrice = convertedPrice * (1 + marginPercent / 100);
        } else if (marginType === 'Value') {
            // Calculate Unit Price as Converted Price + Margin Value
            newUnitPrice = convertedPrice + marginValue;
        }

        // Set the calculated Unit Price
        this.lineItems[index].UnitPrice = newUnitPrice;
    }


    handleSave() {
        this.isLoading = true;

        // Validate if any line item with "Rejected" status has no reject reason
        for (let i = 0; i < this.lineItems.length; i++) {
            if (this.lineItems[i].Purchase_Price_Status__c === 'Rejected' && !this.lineItems[i].Reject_Reason__c) {
                this.showToast('', `Reject Reason is mandatory`, 'error');
                this.isLoading = false; // Stop the loading spinner
                return; // Prevent saving if validation fails
            }
        }

        // Proceed with saving line items if all validations pass
        updateOpportunityLineItems({ lineItems: this.lineItems })
            .then(() => {
                this.showToast('Success', 'Enquiry Updated Successfully', 'success');

                sendQuoteStatusEmails({ oppIds: [this.recordId] })
                    .then(() => {
                        console.log('Email sent successfully.');
                    })
                    .catch((error) => {
                        this.showToast('Error', 'Error while sending email: ' + error.body.message, 'error');
                    });

                // Navigate to the Opportunity record page
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Order',
                        actionName: 'view'
                    }
                });

                // Reload the window after a short delay to ensure navigation is complete
                setTimeout(() => window.location.reload(), 1000);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }




    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}