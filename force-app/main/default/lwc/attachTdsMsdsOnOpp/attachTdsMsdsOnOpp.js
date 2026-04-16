import { LightningElement, wire, track, api } from 'lwc';
import getProductData from '@salesforce/apex/SendTDSFile.getProductData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFiledDisplay from '@salesforce/apex/SendTDSFile.getFiledDisplay';
import getDocumentUrl from '@salesforce/apex/SendTDSFile.getDocumentUrl';
import getEmailDetails from '@salesforce/apex/SendTDSFile.getEmailDetails';
import sendMailToCustomer from '@salesforce/apex/SendTDSFile.sendMailToCustomer';
import { NavigationMixin } from 'lightning/navigation';

export default class AttachTdsMsdsOnOpp extends NavigationMixin(LightningElement) {
    @api rId;
    @track linkIdSet = [];
    @track subject = ' Vipul Organics TDS/MSDS Files';
    @track ToAddress = '';
    @track ccAddress = '';
    @track commnetBody = 'Dear Sir/Madam,<br/><br/>Please find attached Vipul Organics TDS/MSDS Files.';
    @track OpenModal = false;
    @track isLoading = false;
    @track tableData = [];
    @track isSendDisabled = false; // To manage Send Mail button state

    connectedCallback() {
        console.log('Component connected. rId:', this.rId);
        if (!this.rId) {
            this.showErrorToast('Record ID is missing');
        }
        this.getProduct();
        this.getOppDetail();
    }

    getOppDetail() {
        getEmailDetails({ oppId: this.rId }).then(data => {
            let result = JSON.parse(data);
            console.log('data:-->', data);
            //console.log('data:cc', result['cc']);
            if (data != null) {
                if (result.hasOwnProperty('ToAdd')) {
                    this.ToAddress = result['ToAdd'].join(', ');
                }
                if (result.hasOwnProperty('cc')) {
                    this.ccAddress = result['cc'].join(', ');
                }
            } else {
                this.showToast('Error', 'Error', 'Email not found');
            }
        });
    }

    handleToAddressChange(event) {
        this.ToAddress = event.target.value;
    }

    handleCCAddressChange(event) {
        this.ccAddress = event.target.value;
    }

    handleSubChange(event) {
        this.subject = event.target.value;
    }

    handleBodyChange(event) {
        console.log('commnetBody', event.target.value);
        this.commnetBody = event.target.value;
    }

    handleSendMail() {
        if (this.subject === '') {
            this.showToast('Subject', 'Error', 'Please fill Subject');
        } else if (this.commnetBody === '') {
            this.showToast('Email body', 'Error', 'Please fill Email body');
        } else {
            this.sendMail();
        }
    }

    async sendMail() {
        if (this.isSendDisabled) return; // Prevent multiple sends

        this.isSendDisabled = true; // Disable the button
        try {
            const result = await sendMailToCustomer({
                toAdd: this.ToAddress,
                cc: this.ccAddress,
                subject: this.subject,
                body: this.commnetBody,
                fileId: JSON.stringify(this.linkIdSet)
            });
            console.log('result', result);
            let data = JSON.parse(result);
            if (data.Success) {
                this.showToast('Success', 'Success', 'Email sent Successfully');
                this.OpenModal = false;
                this.refreshCmp();
            } else if (data.error) {
                this.showToast('Error', 'Error', data.error);
            }
        } catch (error) {
            this.showToast('Error', 'Error', error.body.message);
        } finally {
            this.isSendDisabled = false; // Re-enable the button
        }
    }

    hideModalBox() {
        this.OpenModal = false;
    }

    getProduct() {
        console.log('Calling getProduct');
        this.tableData = [];
        this.isLoading = true;

        setTimeout(() => {
            getProductData({ oppId: this.rId }).then(data => {
                this.isLoading = false;
                console.log('Data:', data);
                if (data != null) {
                    this.tableData = JSON.parse(data);
                } else {
                    this.showToast('Error', 'error', 'No Data Found');
                }
            });
        }, 1000);
    }

    refreshCmp() {
        window.location.reload();
    }

    openModaltoSend() {
        if (this.linkIdSet.length > 0) {
            this.OpenModal = true; // Open the modal
        } else {
            this.showToast('Error', 'Error', 'Please select at least one file');
        }
    }

    handleOpenChild(event) {
        let pId = event.target.dataset.id;
        let iconlabel = event.target.dataset.label;
        let index = this.tableData.findIndex(row => row.Id === pId);
        console.log('pId:', pId, iconlabel, index);
        if (iconlabel === 'open') {
            this.tableData[index].openFiles = false;
            this.tableData[index].closeFiles = true;
            this.tableData[index].showChildData = true;
            this.getFileDetail(index, pId);
        } else if (iconlabel === 'close') {
            this.tableData[index].openFiles = true;
            this.tableData[index].closeFiles = false;
            this.tableData[index].showChildData = false;
        }
    }

    getFileDetail(index, pId) {
        getFiledDisplay({ prodId: pId }).then(data => {
            if (data != null) {
                this.tableData[index].dataChildFiles = JSON.parse(data);
            } else {
                this.showToast('Error', 'Error', 'File Not Found');
            }
        });
    }

    handleFileSelect(event) {
        let chk = event.target.checked;
        let id = event.target.dataset.id;
        console.log(id, chk);

        if (chk) {
            if (!this.linkIdSet.includes(id)) {
                this.linkIdSet.push(id); // Add the ID to the array
                console.log('add', this.linkIdSet); // Log the array contents
            }
        } else {
            this.linkIdSet = this.linkIdSet.filter(item => item !== id); // Filter out the ID
            console.log('remove', this.linkIdSet); // Log the array contents
        }
    }

    showToast(title, variant, msg) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    viewFile(event) {
        let fileIds = event.target.dataset.id;
        console.log('fileId', fileIds);
        getDocumentUrl({ Id: fileIds }).then(result => {
            if (result) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        selectedRecordId: result
                    }
                });
            }
        });
    }

    backTorecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.rId,
                objectApiName: 'opportunity',
                actionName: 'view'
            }
        });
    }
}