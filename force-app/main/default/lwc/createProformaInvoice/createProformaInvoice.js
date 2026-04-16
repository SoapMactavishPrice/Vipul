import { LightningElement, api } from 'lwc';
import createProformaInvoice from '@salesforce/apex/ProformaInvoiceController.createProformaInvoice';

export default class CreateProformaInvoice extends LightningElement {
    @api recordId;

    handleClick() {
        createProformaInvoice({ quoteId: this.recordId })
            .then(result => {
                // Handle success
                console.log('Proforma Invoice created successfully:', result);
            })
            .catch(error => {
                // Handle error
                console.error('Error creating Proforma Invoice:', error);
            });
    }
}