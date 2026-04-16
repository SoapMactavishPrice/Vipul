import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllOpportunities from '@salesforce/apex/SalesPriceApprovalForOpportunity.getAllOpportunities';
import findRecentPrices from '@salesforce/apex/SalesPriceApprovalForOpportunity.findRecentPrices';
import updateOpportunityLineItems from '@salesforce/apex/SalesPriceApprovalForOpportunity.updateOpportunityLineItems';
import { NavigationMixin } from 'lightning/navigation';

export default class OpportunitySalesPriceApproval extends NavigationMixin(LightningElement) {
    @track opportunities = [];
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
        this.fetchOpportunities();
    }

    fetchOpportunities() {
        getAllOpportunities()
            .then(result => {
                // Format the data before assigning - DON'T use spread operator on Apex response
                this.opportunities = result.map(opp => {
                    return {
                        id: opp.id,
                        name: opp.name,
                        enqNo: opp.enqNo,
                        stageName: opp.stageName,
                        accountId: opp.accountId,
                        accountName: opp.accountName,
                        ownerId: opp.ownerId,
                        ownerEmail: opp.ownerEmail,
                        ownerName: opp.ownerName,
                        link: opp.link,
                        attendeeName: opp.attendeeName,
                        updated: opp.updated,
                        lineItems: opp.lineItems ? opp.lineItems.map(item => ({
                            id: item.id,
                            productId: item.productId,
                            productName: item.productName,
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

            // Find the opportunity
            const oppIndex = this.opportunities.findIndex(o => o.id === parentId);
            if (oppIndex === -1) return;

            // Find the line item
            const itemIndex = this.opportunities[oppIndex].lineItems.findIndex(li => li.id === lineItemId);
            if (itemIndex === -1) return;

            // Update the value
            this.opportunities[oppIndex].lineItems[itemIndex][field] = value;
            this.opportunities[oppIndex].lineItems[itemIndex].updated = true;
            this.opportunities[oppIndex].updated = true;

            // Update formatted value if salesPrice changes
            if (field === 'salesPrice') {
                this.opportunities[oppIndex].lineItems[itemIndex].formattedSalesPrice = this.formatCurrency(value);
            }
            
            // Force reactive update
            this.opportunities = [...this.opportunities];
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
            return {
                id: price.Id,
                opportunityName: price.Opportunity ? price.Opportunity.Name : 'N/A',
                productName: price.Product2 ? price.Product2.Name : 'N/A',
                listPrice: price.ListPrice || 0,
                formattedListPrice: this.formatCurrency(price.ListPrice),
                unitPrice: price.UnitPrice || 0,
                formattedUnitPrice: this.formatCurrency(price.UnitPrice),
                quantity: price.Quantity || 0,
                totalPrice: price.TotalPrice || 0,
                formattedTotalPrice: this.formatCurrency(price.TotalPrice),
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

        // Filter to only include updated opportunities
        const updatedOpportunities = this.opportunities.filter(opp => opp.updated);
        
        if (updatedOpportunities.length === 0) {
            this.showToast('Info', 'No changes to save.', 'info');
            this.isSaveDisabled = false;
            return;
        }

        updateOpportunityLineItems({ opportunityListStringObject: JSON.stringify(updatedOpportunities) })
            .then(result => {
                if (result === 'Success') {
                    this.showToast('Success', 'Opportunity Line Items updated successfully', 'success');
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
                objectApiName: 'Opportunity',
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