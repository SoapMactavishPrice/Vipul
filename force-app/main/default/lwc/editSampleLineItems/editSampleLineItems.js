import { LightningElement, api, wire, track } from 'lwc';
import getSampleOuts from '@salesforce/apex/SampleLineItemController.getSampleOuts';
import updateSampleOuts from '@salesforce/apex/SampleLineItemController.updateSampleOuts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getUnitOfMeasureOptions from '@salesforce/apex/SampleLineItemController.getUnitOfMeasureOptions';
import getStatus from '@salesforce/apex/SampleLineItemController.getStatus';
import modalWidthInLwc from '@salesforce/resourceUrl/modalWidthInLwc';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class SampleOutLineItemsLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track sampleOutLineItems = [];
    @track isLoading = false;
    @track unitOfMeasureOptions = [];
    @track statusOptions = [];

    @wire(getSampleOuts, { sampleRequestId: '$recordId' })
    wiredSampleOutsResult({ error, data }) {
        if (data) {
            this.sampleOutLineItems = data.map(item => ({ ...item }));
        } else if (error) {
            this.sampleOutLineItems = [];
            this.showToast('Error', 'Error retrieving Sample Out Line Items', 'error');
        }
    }

    @wire(getUnitOfMeasureOptions)
    wiredUnitOfMeasureOptionsResult({ error, data }) {
        if (data) {
            this.unitOfMeasureOptions = data;
        } else if (error) {
            this.unitOfMeasureOptions = [];
            this.showToast('Error', 'Error retrieving Unit of Measure options', 'error');
        }
    }

    @wire(getStatus)
    wiredStatusOptionsResult({ error, data }) {
        if (data) {
            this.statusOptions = data;
        } else if (error) {
            this.statusOptions = [];
            this.showToast('Error', 'Error retrieving Status options', 'error');
        }
    }

    handleChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        const value = event.target.value;
    
        if (index !== undefined && field) {
            let updatedItems = [...this.sampleOutLineItems];
            updatedItems[index][field] = value;
            this.sampleOutLineItems = updatedItems;
        }
    }
    

    handleUnitChange(event) {
        const index = event.target.dataset.index;
        const selectedRecordId = event.detail.recordId;

        if (selectedRecordId) {
            this.sampleOutLineItems[index] = {
                ...this.sampleOutLineItems[index],
                Sample_Sent_to_Unit__c: selectedRecordId
            };
        }
    }

    handleSave() {
        this.isLoading = true;
        updateSampleOuts({ sampleOutRecords: this.sampleOutLineItems })
            .then(() => {
                this.showToast('Success', 'Sample Out Line Items updated successfully', 'success');
                this.redirectToSampleRequest();
            })
            .catch(error => {
                console.error('Error updating records:', error);
                this.showToast('Error', 'An error occurred while updating Sample Out Line Items: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.redirectToSampleRequest();
    }

    connectedCallback() {


        loadStyle(this, modalWidthInLwc)
            .then(() => {
                console.log('CSS loaded successfully!');
            })
            .catch(error => {
                console.log('Error loading CSS:', error);
            });
        }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    redirectToSampleRequest() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Sample_Request__c',
                actionName: 'view'
            }
        });
    }
}