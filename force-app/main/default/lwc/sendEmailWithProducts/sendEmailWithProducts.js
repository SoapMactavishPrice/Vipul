import { LightningElement, wire, api } from 'lwc';
import getProducts from '@salesforce/apex/EmailSenderController.getProducts';
import sendEmail from '@salesforce/apex/EmailSenderController.sendEmail';

export default class ProductListWithAttachment extends LightningElement {
    @api recordId; // This is the Lead ID
    products = [];
    emailSent = false;
    errorMessage = '';
    attachmentIds = []; // To store the uploaded attachment Ids
    subject = 'Products Interested'; // Default subject
    toEmail = ''; // To store the "To" email address (can be multiple)

    // Allowed file formats for upload
    acceptedFormats = '.pdf,.jpg,.png,.docx,.txt';

    // Define columns for the datatable
    columns = [
        { label: 'Product Name', fieldName: 'Vipul_Product_Name__c' },
        { label: 'Product Code', fieldName: 'Product_Code__c' },
        { label: 'Price', fieldName: 'Price__c' },
        { label: 'Quantity', fieldName: 'Quantity__c' }
    ];

    // Fetch products related to the Lead and Lead's email
    @wire(getProducts, { leadId: '$recordId' })
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data;
            this.errorMessage = '';
            // Fetch the Lead's email dynamically from the first product record
            this.toEmail = data[0]?.Lead__r?.Email || '';  // Assuming Lead is related to Product_Interested
        } else if (error) {
            this.errorMessage = 'Error fetching products';
            console.error(error);
        }
    }

    // Handle "To" Email input change (allow comma-separated emails)
    handleToEmailChange(event) {
        this.toEmail = event.target.value;
    }

    // Handle Subject input change
    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    // Handle file upload and store the file Ids
    handleFileUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        // Collect the attachment Ids of uploaded files
        this.attachmentIds = uploadedFiles.map(file => file.documentId);
        console.log('Uploaded File Ids:', this.attachmentIds);
    }

    // Handle Send Email button click
    handleSendEmail() {
        // Generate the email body dynamically from product records
        let emailBody = '<h2>Products Interested</h2><table><tr><th>Name</th><th>Product Code</th><th>Price</th></tr>';

        this.products.forEach(product => {
            emailBody += `<tr><td>${product.Vipul_Product_Name__c}</td>
                              <td>${product.Product_Code__c}</td>
                              <td>${product.Price__c}</td></tr>`;
        });

        emailBody += '</table>';

        // Split email addresses by commas
        let emailList = this.toEmail.split(',').map(email => email.trim()).join(';'); // Salesforce accepts semicolon-separated emails

        // Sending email to the Lead's email (use actual Lead email here)
        sendEmail({
            leadId: this.recordId,
            subject: this.subject, // Use the dynamic subject entered by the user
            body: emailBody,
            toAddress: emailList, // Use the dynamic "To" email entered by the user
            attachmentIds: this.attachmentIds // Attach files if any
        })
            .then(result => {
                this.emailSent = true;
                this.errorMessage = '';
                console.log(result);
            })
            .catch(error => {
                this.emailSent = false;
                this.errorMessage = 'Error sending email';
                console.error(error);
            });
    }

    // Handle Cancel button click
    handleCancel() {
        // Clear the email fields and reset state
        this.emailSent = false;
        this.errorMessage = '';
        this.attachmentIds = [];
        this.subject = 'Products Interested'; // Reset subject to default
        this.toEmail = ''; // Clear "To" email
    }
}