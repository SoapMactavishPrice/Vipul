import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllQuotes from '@salesforce/apex/SalesPriceApprovalForQuote.getAllQuotes';
import findRecentPrices from '@salesforce/apex/SalesPriceApprovalForQuote.findRecentPrices';
import updateQuoteLineItems from '@salesforce/apex/SalesPriceApprovalForQuote.updateQuoteLineItems';
import { NavigationMixin } from 'lightning/navigation';

export default class QuoteSalesPriceApproval extends NavigationMixin(LightningElement) {
    @track quotes = [];
    @track isSaveDisabled = false;
    @track showPreviewModal = false;
    @track recentPrices = [];
    @track previewProductName = '';
    @track isLoadingRecentPrices = false;

    statusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    connectedCallback() {
        this.fetchQuotes();
    }

    fetchQuotes() {
        getAllQuotes()
            .then(result => {
                // Format the data before assigning
                this.quotes = result.map(quote => {
                    return {
                        id: quote.id,
                        name: quote.name,
                        quoteNumber: quote.quoteNumber,
                        accountId: quote.accountId,
                        accountName: quote.accountName,
                        ownerId: quote.ownerId,
                        ownerEmail: quote.ownerEmail,
                        ownerName: quote.ownerName,
                        link: quote.link,
                        attendeeName: quote.attendeeName,
                        updated: quote.updated,
                        lineItems: quote.lineItems ? quote.lineItems.map(item => ({
                            id: item.id,
                            productId: item.productId,
                            productName: item.productName,
                            productCode: item.productCode,
                            listPrice: item.listPrice,
                            salesPrice: item.salesPrice,
                            quantity: item.quantity,
                            approvalStatus: item.approvalStatus,
                            approvalComments: item.approvalComments,
                            updated: item.updated,
                            formattedListPrice: this.formatCurrency(item.listPrice)
                        })) : []
                    };
                });
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.redirectToHome();
            });
    }

    get hasRecentPrices() {
        return this.recentPrices && this.recentPrices.length > 0;
    }

    handleLineItemChanges(event) {
        try {
            const field = event.target.dataset.field;
            const lineItemId = event.target.dataset.id;
            const parentId = event.target.dataset.parent;
            let value = event.target.value;

            // Convert to number if it's a numeric field
            if (field === 'salesPrice') {
                value = parseFloat(value);
                if (isNaN(value)) {
                    value = 0;
                }
            }

            // Find the quote
            const quoteIndex = this.quotes.findIndex(q => q.id === parentId);
            if (quoteIndex === -1) return;

            // Find the line item
            const itemIndex = this.quotes[quoteIndex].lineItems.findIndex(li => li.id === lineItemId);
            if (itemIndex === -1) return;

            // Update the value
            this.quotes[quoteIndex].lineItems[itemIndex][field] = value;
            this.quotes[quoteIndex].lineItems[itemIndex].updated = true;
            this.quotes[quoteIndex].updated = true;

            // Update formatted value if salesPrice changes
            if (field === 'salesPrice') {
                this.quotes[quoteIndex].lineItems[itemIndex].formattedSalesPrice = this.formatCurrency(value);
            }
            
            // Force reactive update
            this.quotes = [...this.quotes];
        } catch (error) {
            console.error('Error in handleLineItemChanges:', error);
            this.showToast('Error', 'Error updating field: ' + error.message, 'error');
        }
    }

    handlePreviewClick(event) {
        try {
            const accountId = event.target.dataset.accountId;
            const productId = event.target.dataset.productId;
            const productName = event.target.dataset.productName;
            
            this.previewProductName = productName;
            this.isLoadingRecentPrices = true;
            this.showPreviewModal = true;
            this.recentPrices = [];
            
            findRecentPrices({ accountId: accountId, productId: productId })
                .then(result => {
                    this.processRecentPrices(result);
                    this.isLoadingRecentPrices = false;
                    
                    if (result.length === 0) {
                        this.showToast('Info', 'No previous sales prices found for this product and customer.', 'info');
                    }
                })
                .catch(error => {
                    this.isLoadingRecentPrices = false;
                    console.error('Error loading recent prices:', error);
                    this.showToast('Error', 'Error loading recent prices: ' + error.body.message, 'error');
                });
        } catch (error) {
            console.error('Error in handlePreviewClick:', error);
            this.showToast('Error', 'Error opening preview: ' + error.message, 'error');
        }
    }

    processRecentPrices(prices) {
        this.recentPrices = prices.map(price => {
            const totalPrice = (price.UnitPrice || 0) * (price.Quantity || 0);
            return {
                id: price.Id,
                quoteName: price.Quote ? price.Quote.Name : 'N/A',
                quoteNumber: price.Quote ? price.Quote.QuoteNumber : '',
                productName: price.Product2 ? price.Product2.Name : 'N/A',
                listPrice: price.ListPrice || 0,
                formattedListPrice: this.formatCurrency(price.ListPrice),
                unitPrice: price.UnitPrice || 0,
                formattedUnitPrice: this.formatCurrency(price.UnitPrice),
                quantity: price.Quantity || 0,
                totalPrice: totalPrice,
                formattedTotalPrice: this.formatCurrency(totalPrice),
                createdDate: price.CreatedDate,
                formattedCreatedDate: this.formatDate(price.CreatedDate)
            };
        });
    }

    closePreviewModal() {
        this.showPreviewModal = false;
        this.recentPrices = [];
        this.previewProductName = '';
        this.isLoadingRecentPrices = false;
    }

    saveChanges() {
        this.isSaveDisabled = true;

        // Filter to only include updated quotes
        const updatedQuotes = this.quotes.filter(quote => quote.updated);
        
        if (updatedQuotes.length === 0) {
            this.showToast('Info', 'No changes to save.', 'info');
            this.isSaveDisabled = false;
            return;
        }

        updateQuoteLineItems({ quoteListStringObject: JSON.stringify(updatedQuotes) })
            .then(result => {
                if (result === 'Success') {
                    this.showToast('Success', 'Quote Line Items updated successfully', 'success');
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.showToast('Error', result, 'error');
                    this.isSaveDisabled = false;
                }
            })
            .catch(error => {
                console.error('Error saving changes:', error);
                this.isSaveDisabled = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    redirectToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Quote',
                actionName: 'list'
            }
        });
    }

    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    formatCurrency(value) {
        if (value === null || value === undefined || isNaN(value)) return '₹0.00';
        return '₹' + parseFloat(value).toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,');
    }

    formatDate(dateValue) {
        if (!dateValue) return '';
        const date = new Date(dateValue);
        return date.toLocaleDateString('en-IN', {
            day: '2-digit',
            month: 'short',
            year: 'numeric'
        });
    }
}