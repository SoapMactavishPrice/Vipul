import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createSalesOrderData from '@salesforce/apex/CreateSalesOrder_ToOracle.createSalesOrderData';
import quoteValidation from '@salesforce/apex/CreateSalesOrder_ToOracle.quoteValidation';
import orderValidation from '@salesforce/apex/CreateSalesOrder_ToOracle.orderValidation';
import updateSOnumberToQuote from '@salesforce/apex/CreateSalesOrder_ToOracle.updateSOnumberToQuote';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class SendQuoteToSAP extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api salesDocNo;
    @track showSpinner = true;
    @track recTypeName = '';
    @track ResponseMessage = '';
    @track errorResponseMessage = '';

    showToast(toastTitle, toastMsg, toastType) {
        const event = new ShowToastEvent({
            title: toastTitle,
            message: toastMsg,
            variant: toastType,
            mode: "dismissable"
        });
        this.dispatchEvent(event);
    }

    connectedCallback() {
        setTimeout(() => {
            console.log('recordId ', this.recordId);
            console.log('objectApiName ', this.objectApiName);
            if (this.recordId) {
                if (this.objectApiName == 'Quote') {
                    this.handleQuoteCheck();
                } else if (this.objectApiName == 'Order') {
                    this.handleOrderCheck();
                }
            } else {
                this.showToast('Error', 'Invalid Record Id', 'error');
            }
        }, 2000);
    }

    // Send Quote as SO to SAP
    handleQuoteCheck() {
        quoteValidation({
            qId: this.recordId
        }).then((result) => {
            console.log('quoteValidation result ', result);
            let data = JSON.parse(result);
            if (data.status == 'true') {
                this.showToast('Please wait for callout response', '', 'info');
                this.handleCallout();
            } else {
                this.showToast(data.message, '', 'error');
                this.errorResponseMessage = data.message;
                this.showSpinner = false;
            }
        }).catch((error) => {
            console.log('= erorr quoteValidation : ', error);
            this.showSpinner = false;
        })
    }

    handleCallout() {
        createSalesOrderData({
            soId: this.recordId,
            objName: this.objectApiName
        })
        .then((result) => {
            console.log('result ', result);

            let data;

            try {
                data = JSON.parse(result);
            } catch (e) {
                // 🔥 THIS IS YOUR FIX
                this.errorResponseMessage = result;
                this.showToast('Error', result, 'error');
                this.showSpinner = false;
                return;
            }

            if (!data || !data.length) {
                throw new Error('Invalid response from server');
            }

            let res = data[0];

            if (res.Status === 'Success') {
                this.ResponseMessage =
                    'SONumber: ' + res.SONumber +
                    ' & ReferenceNo: ' + res.ReferenceNo;
            } else {
                this.errorResponseMessage = res.ResponseDescription || result;
                this.showToast('Error', this.errorResponseMessage, 'error');
                this.showSpinner = false;
            }
        })
        .catch((error) => {
            console.log('ERROR => ', JSON.stringify(error));

            this.errorResponseMessage = error?.body?.message || error.message;

            this.showToast(
                'Error',
                this.errorResponseMessage || 'Something went wrong!!!',
                'error'
            );

            this.showSpinner = false;
        });
    }

    handleUpdateSOnumber(res) {

        updateSOnumberToQuote({
            qId: this.recordId,
            soNum: res.SONumber,
            objName: this.objectApiName
        })
        .then((result) => {

            if (result === 'Success') {
                this.showToast('Success', res.ResponseDescription, 'success');
            }

            this.showSpinner = false; // ✅ always stop

        })
        .catch((error) => {

            console.log('Update failed, retrying...', error);

            // 🔁 retry once
            setTimeout(() => {

                updateSOnumberToQuote({
                    qId: this.recordId,
                    soNum: res.SONumber,
                    objName: this.objectApiName
                })
                .then(() => {
                    this.showToast('Recovered: SO updated', '', 'success');
                    this.showSpinner = false;
                })
                .catch((err) => {
                    console.log('Retry failed', err);

                    this.showToast(
                        'Error',
                        err?.body?.message || 'Update failed',
                        'error'
                    );

                    this.showSpinner = false;
                });

            }, 2000);
        });
    }

    handleOrderCheck() {
        orderValidation({
            qId: this.recordId
        }).then((result) => {
            console.log('orderValidation result ', result);
            let data = JSON.parse(result);
            if (data.status == 'true') {
                this.showToast('Please wait for callout response', '', 'info');
                this.handleCallout();
            } else {
                this.showToast(data.message, '', 'error');
                this.errorResponseMessage = data.message;
                this.showSpinner = false;
            }
        }).catch((error) => {
            console.log('= erorr orderValidation : ', error);
            this.showSpinner = false;
        })
    }

     handleClose() {
        // Close the Quick Action modal
        this.dispatchEvent(new CloseActionScreenEvent());

        // Redirect to the Quote record page
        if (this.recordId && this.objectApiName === 'Quote') {
            window.location.href = `/lightning/r/Quote/${this.recordId}/view`;
        }
    }

    closeModal(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new RefreshEvent());
    }

}