import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import createSampleOutRequest from '@salesforce/apex/SampleOutRequestLead.createSampleOutRequest';
import getUnitOfMeasureOptions from '@salesforce/apex/SampleOutRequestLead.getUnitOfMeasureOptions';
import getCurrentUserName from '@salesforce/apex/SampleOutRequestLead.getCurrentUserName';
import getAccountDetails from '@salesforce/apex/SampleOutRequestLead.getopptails';
import getLeadDetails from '@salesforce/apex/SampleOutRequestLead.getLeadDetails';
import fetchCI from '@salesforce/apex/MarketingForm.fetchCI';

export default class NewSampleOutLead extends NavigationMixin(LightningElement) {

    @api recordId;
    @track leadId = '';
    @track countryId = '';
    @track personId = '';
    @track unitOfMeasureOptions = [];
    @track accountCurrency = '';
    @track requestDate = '';
    @track receivedDate = '';
    @track delayDays = 0;
    @track countryName = '';
    @track companyName = '';
    @track isSubmitting = false;

    @track products = [this.initializeProductRow()];

    // Load Unit of Measure picklist values
    @wire(getUnitOfMeasureOptions)
    wiredUOM({ error, data }) {
        if (data) {
            this.unitOfMeasureOptions = data;
        } else if (error) {
            this.showErrorToast(error);
        }
    }

    // Fetch user info
    @wire(getCurrentUserName)
    wiredUser({ error, data }) {
        if (data) {
            this.personId = data.Id;
        }
    }

    // Fetch Lead data
    connectedCallback() {
        if (this.recordId) {
            this.leadId = this.recordId;

            // Set today's date as default
            const today = new Date();
            this.requestDate = today.toISOString().split('T')[0]; // yyyy-mm-dd format

            getLeadDetails({ leadId: this.recordId })
                .then(result => {
                    this.leadId = result.leadId;
                    this.companyName = result.companyName;
                    this.countryId = result.countryId;
                    this.countryName = result.countryName;
                    console.log('Auto-set Lead and Country:', this.leadId, this.countryName);
                })
                .catch(error => {
                    console.error('Error fetching lead details:', error);
                    this.showErrorToast(error);
                });
        }
    }




    initializeProductRow() {
        return {
            index: Date.now(),
            New_Product__c: false,
            New_Product_Name__c: '',
            New_Product_CI_No__c: '',
            prodId: null,
            ciNo: '',
            quantity: '',
            packet: '',
            quality: '',
            application: '',
            unitOfMeasure: '',
            unitId: null
        };
    }

    handleFieldChange(event) {
        const field = event.target.dataset.id;
        const value = event.detail?.recordId || event.target.value;

        if (field && this.hasOwnProperty(field)) {
            this[field] = value;
        }

        else if (fieldName === 'requestDate') {
            this.requestDate = event.target.value;
            console.log('Request Date changed to:', this.requestDate);
            this.calculateDelayDays();  // Recalculate delay days whenever the request date changes
        }
        else if (field === 'leadId') {
            this.leadId = value;

            if (this.leadId) {
                getLeadDetails({ leadId: this.leadId })
                    .then(result => {
                        this.leadId = result.leadId;
                        this.companyName = result.companyName;
                        this.countryId = result.countryId;
                        this.countryName = result.countryName;

                        console.log('Lead Country fetched:', this.countryName);
                    })
                    .catch(error => {
                        console.error('Error fetching lead details:', error);
                        this.showErrorToast(error);
                    });
            }
        }

    }


    calculateDelayDays() {
        if (this.requestDate && this.receivedDate) {
            const start = new Date(this.requestDate);
            const end = new Date(this.receivedDate);
            this.delayDays = Math.round((end - start) / (1000 * 3600 * 24));
        } else {
            this.delayDays = 0;
        }
    }

    handleCheckboxChange(event) {
        const index = event.target.dataset.index;
        const isChecked = event.target.checked;
        this.updateProductField(index, 'New_Product__c', isChecked);
    }

    handleTextInputChange(event) {
        const index = event.target.dataset.index;
        const label = event.target.dataset.label;
        const value = event.target.value;
        this.updateProductField(index, label, value);
    }

    handleCIInputChange(event) {
        const index = event.target.dataset.index;
        const label = event.target.dataset.label;
        const value = event.target.value;
        this.updateProductField(index, label, value);
    }

    handleProductFieldChange(event) {
        const index = event.target.dataset.index;
        const label = event.target.dataset.label;
        const value = event.target.value;
        this.updateProductField(index, label, value);
    }

    // handleUnitChange(event) {
    //     const index = event.target.dataset.index;
    //     const recordId = event.detail.recordId;
    //     this.updateProductField(index, 'unitId', recordId);
    // }

    handleUnitSelected(event) {
        const index = event.target.dataset.index;
        const { unitId, unitName } = event.detail;

        // if you want to keep your existing helper
        this.updateProductField(index, 'unitId', unitId);
        this.updateProductField(index, 'unitName', unitName);
    }

    handleUnitCleared(event) {
        const index = event.target.dataset.index;

        this.updateProductField(index, 'unitId', null);
        this.updateProductField(index, 'unitName', null);
    }


    lookupRecord(event) {
        const index = event.target.dataset.index;
        const label = event.target.dataset.label;
        const selectedRecord = event.detail.selectedRecord;

        if (!selectedRecord) {
            console.warn('No product selected.');
            return;
        }

        const recordId = selectedRecord.Id;
        const ciNo = selectedRecord.CI_no__c;

        this.updateProductField(index, label, recordId);

        if (ciNo) {
            this.updateProductField(index, 'ciNo', ciNo);
        } else {
            this.fetchCIForProduct(recordId, index);
        }
    }


    fetchCIForProduct(productId, index) {
        fetchCI({ productId })
            .then((result) => {
                const updated = [...this.products];
                const idx = updated.findIndex(p => p.index == index);
                if (idx !== -1) {
                    // ✅ Create a new object to trigger reactivity
                    updated[idx] = { ...updated[idx], ciNo: result };
                    this.products = updated;
                    console.log('CI number fetched for product:', result);
                }
            })
            .catch((error) => {
                console.error('Error fetching CI_no__c:', error);
            });
    }

    updateProductField(index, field, value) {
        const updated = [...this.products];
        const idx = updated.findIndex(p => p.index == index);
        if (idx !== -1) {
            updated[idx] = { ...updated[idx], [field]: value }; // ✅ create new object
            this.products = updated;
        }
    }


    addProduct() {
        this.products = [...this.products, this.initializeProductRow()];
    }

    removeProduct(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.products = this.products.filter(p => p.index !== index);
    }


    handleSubmitSampleOut() {

        if (this.isSubmitting) {
            return;
        }
        this.isSubmitting = true;

        const validUnits = this.products.every(p => p.unitId);
        if (!validUnits) {
            this.showToast('Error', 'Please select a Sample Sent to Units for all rows.', 'error');
            this.isSubmitting = false;
            return;
        }

        if (!this.leadId) {
            this.showToast('Error', 'Please select a Lead before submitting.', 'error');
            this.isSubmitting = false;
            return;
        }


        const productData = this.products.map(p => ({
            prodId: p.prodId,
            quantity: p.quantity,
            ciNo: p.ciNo,
            packet: p.packet,
            quality: p.quality,
            application: p.application,
            unitOfMeasure: p.unitOfMeasure,
            unitId: p.unitId,
            New_Product__c: p.New_Product__c,
            New_Product_Name__c: p.New_Product_Name__c,
            New_Product_CI_No__c: p.New_Product_CI_No__c
        }));

        createSampleOutRequest({
            leadId: this.leadId,
            sampleOutSentTo: '',
            requestDate: this.requestDate ? new Date(this.requestDate) : null,
            receivedDate: this.receivedDate ? new Date(this.receivedDate) : null,
            companyName: this.companyName,
            personId: this.personId,
            accountId: null,
            countryId: this.countryId,
            UnitId: null,
            packet: null,
            delayDays: this.delayDays,
            sampleout: null,
            samplein: null,
            ciNo: null,
            ci: null,
            srefno: null,
            unitOfMeasure: null,
            accountCurrency: this.accountCurrency,
            products: productData
        })
            .then(result => {
                this.showToast('Success', 'Sample Request created successfully!', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Sample_Out_Request__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                recordId: this.leadId,
                objectApiName: 'Lead',
                actionName: 'list'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showErrorToast(error) {
        this.showToast('Error', error.body?.message || 'Unknown error', 'error');
    }
}