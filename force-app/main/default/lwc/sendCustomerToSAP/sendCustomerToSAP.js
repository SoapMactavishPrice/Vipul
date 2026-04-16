import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import customerValidation from '@salesforce/apex/CustomerUpsertToSAP.customerValidation';
import sendCustomerData from '@salesforce/apex/CustomerUpsertToSAP.sendCustomerData';
import updateCustomerData from '@salesforce/apex/CustomerUpsertToSAP.updateCustomerData';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

export default class SendCustomerToSAP extends LightningElement {

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
            this.handleCustomerCheck();
        }, 2000);
    }

    handleCustomerCheck() {
        customerValidation({
            accId: this.recordId
        }).then((result) => {
            console.log('customerValidation result ', result);
            let data = result;
            if (data == 'ok') {
                this.showToast('Please wait for callout response', '', 'info');
                this.handleCallout();
            } else {
                this.showToast(data, '', 'error');
                this.errorResponseMessage = data;
                this.showSpinner = false;
            }
        }).catch((error) => {
            console.log('= erorr customerValidation : ', error);
            this.showSpinner = false;
        })
    }

    handleCallout() {
        sendCustomerData({
            accId: this.recordId
        }).then((result) => {
            console.log('result ', result);
            let data = JSON.parse(result);
            if (data[0].Status == 'Success') {
                this.ResponseMessage = 'Customer No. ' + data[0].ReferenceNo + ' added successfully!';
                this.handleUpdateCustomer(data[0].ReferenceNo);
                // this.showToast('Success', data[0].ResponseDescription, 'success');
            } else {
                this.errorResponseMessage = data[0].ResponseDescription;
                this.showToast('Error', 'Something went wrong!!!', 'error');
                this.showSpinner = false;
            }
            this.showSpinner = false;

            // const customEvent = new CustomEvent('getresponsemsg', {
            //     detail: { resmsg: this.ResponseMessage } // Set the parameter in the detail object
            // });
            // this.dispatchEvent(customEvent);

            // history.replaceState(null, document.title, location.href);
        }).catch((error) => {
            console.log('= erorr', error);
            this.showToast('Error', 'Something went wrong!!!', 'error');
            this.errorResponseMessage = error;
            this.showSpinner = false;
        })
    }

    handleUpdateCustomer(cNum) {
        updateCustomerData({
            custNumber: cNum,
            cId: this.recordId
        }).then((data) => {
            if (data == 'ok') {
                this.showToast('Success', cNum + ' added successfully!', 'success');
            }
            this.showSpinner = false;
        }).catch((error) => {
            console.log(error);
            this.showSpinner = false;
            this.showToast('Error', 'Something went wrong!', 'error');
        })
    }

}