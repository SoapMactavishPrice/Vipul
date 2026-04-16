import { LightningElement, wire, track } from 'lwc';
import getPendingApprovals from '@salesforce/apex/ApprovalProcessController.getPendingApprovals';
import updateApprovalStatus from '@salesforce/apex/ApprovalProcessController.updateApprovalStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Opportunity Name', fieldName: 'OpportunityName', type: 'text' },
    { label: 'Product Name', fieldName: 'ProductName', type: 'text' },
    { label: 'Sales Price', fieldName: 'TotalPrice', type: 'currency' },
    { label: 'List Price', fieldName: 'UnitPrice', type: 'currency' }
];

export default class ApprovalComponent extends LightningElement {
    @track opportunityLineItems = [];
    selectedRecordId;
    columns = COLUMNS;

    @wire(getPendingApprovals)
    wiredRecords({ error, data }) {
        if (data) {
            this.opportunityLineItems = data.map(item => ({
                ...item,
                OpportunityName: item.Opportunity.Name,
                ProductName: item.PricebookEntry.Product2.Name
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to fetch approval requests', 'error');
        }
    }

    handleApprove() {
        this.updateStatus('Approved');
    }

    handleReject() {
        this.updateStatus('Rejected');
    }

    updateStatus(status) {
        updateApprovalStatus({ recordId: this.selectedRecordId, status })
            .then(() => {
                this.showToast('Success', `Record ${status} successfully!`, 'success');
                this.opportunityLineItems = this.opportunityLineItems.filter(item => item.Id !== this.selectedRecordId);
                this.selectedRecordId = null;
            })
            .catch(error => {
                this.showToast('Error', `Error updating record: ${error.body.message}`, 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }
}