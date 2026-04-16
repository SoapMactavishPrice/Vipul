import { LightningElement, api, wire, track } from 'lwc';
import getSampleIns from '@salesforce/apex/SampleLineItemController.getSampleIns';
import updateSampleIns from '@salesforce/apex/SampleLineItemController.updateSampleIns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class SampleInLineItemsLWC extends NavigationMixin(LightningElement) {
    @api recordId; // Sample Request Id
    @track sampleInLineItems = [];
    @track isLoading = false;
    wiredSampleIns;

    @wire(getSampleIns, { sampleRequestId: '$recordId' })
    wiredSampleInsResult(result) {
        this.wiredSampleIns = result;
        const { error, data } = result;
        if (data) {
            this.sampleInLineItems = data.map(item => ({
                ...item,
                // Ensure Sample_Sent_to_Unit__c is properly set
                Sample_Sent_to_Unit__c: item.Sample_Sent_to_Unit__c || null
            }));
        } else if (error) {
            this.sampleInLineItems = [];
            this.showToast('Error', 'Error retrieving Sample In Line Items', 'error');
        }
    }

    handleChange(event) {
        const field = event.target.dataset.field;
        const index = event.target.dataset.index;
        this.sampleInLineItems[index][field] = event.target.value;
    }

    handleUnitChange(event) {
        const index = event.target.dataset.index;
        const selectedRecordId = event.detail.recordId;

        if (selectedRecordId) {
            this.sampleInLineItems[index].Sample_Sent_to_Unit__c = selectedRecordId;
            // Force reactivity
            this.sampleInLineItems = [...this.sampleInLineItems];
        }
    }

    handleSave() {
        this.isLoading = true;
        updateSampleIns({ sampleInRecords: this.sampleInLineItems })
            .then(() => {
                this.showToast('Success', 'Sample In Line Items updated successfully', 'success');
                this.redirectToSampleRequest();
            })
            .catch(error => {
                console.error('Error updating records:', error);
                this.showToast('Error', 'An error occurred while updating Sample In Line Items: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.redirectToSampleRequest();
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