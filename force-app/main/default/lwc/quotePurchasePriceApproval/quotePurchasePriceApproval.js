import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllQuotes from '@salesforce/apex/PurchasePriceApprovalForQuote.getAllQuotes';
import updateQuoteLineItems from '@salesforce/apex/PurchasePriceApprovalForQuote.updateQuoteLineItems';
import { NavigationMixin } from 'lightning/navigation';

export default class QuotePurchasePriceApproval extends NavigationMixin(LightningElement) {
    @track quotes = [];
    @track isSaveDisabled = false;

    connectedCallback() {
        this.fetchQuotes();
    }

    fetchQuotes() {
        getAllQuotes()
            .then(result => {
                this.quotes = result;
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

        let quote = this.quotes.find(q => q.id === parentId);
        let item = quote.lineItems.find(li => li.id === lineItemId);

        item[field] = value;
        item.updated = true;
        quote.updated = true;
    }

    saveChanges() {
        this.isSaveDisabled = true;

        updateQuoteLineItems({ quoteListStringObject: JSON.stringify(this.quotes) })
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