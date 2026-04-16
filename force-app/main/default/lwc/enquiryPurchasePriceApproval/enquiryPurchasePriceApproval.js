import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllOpportunities from '@salesforce/apex/PurchasePriceApprovalForOpportunity.getAllOpportunities';
import updateOpportunityLineItems from '@salesforce/apex/PurchasePriceApprovalForOpportunity.updateOpportunityLineItems';
import { NavigationMixin } from 'lightning/navigation';

export default class EnquiryPurchasePriceApproval extends NavigationMixin(LightningElement) {
    @track opportunities = [];
    @track isSaveDisabled = false;

    connectedCallback() {
        this.fetchOpportunities();
    }

    fetchOpportunities() {
        getAllOpportunities()
            .then(result => {
                this.opportunities = result;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.redirectToHome();
            });
    }

    handleLineItemChanges(event) {
        const field = event.target.dataset.field;
        const lineItemId = event.target.dataset.id;
        const parentId = event.target.dataset.parent;
        const value = event.target.value;

        let opp = this.opportunities.find(o => o.id === parentId);
        let item = opp.lineItems.find(li => li.id === lineItemId);

        item[field] = value;
        item.updated = true;
        opp.updated = true;
    }

    saveChanges() {
        this.isSaveDisabled = true;

        updateOpportunityLineItems({ opportunityListStringObject: JSON.stringify(this.opportunities) })
            .then(result => {
                if (result === 'Success') {
                    this.showToast('Success', 'Purchase Price updated successfully', 'success');
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.showToast('Error', result, 'error');
                }
            })
            .catch(error => {
                this.isSaveDisabled = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    redirectToHome() {
        thisNavigationMixin.Navigate;
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        }));
    }
}