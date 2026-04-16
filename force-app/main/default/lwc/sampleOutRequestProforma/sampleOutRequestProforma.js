import { LightningElement, track, api } from 'lwc';
import getProformaInvoiceData from '@salesforce/apex/ProformaSampleOutRequest.getProformaInvoiceData';
import createSampleOutRequest from '@salesforce/apex/ProformaSampleOutRequest.createSampleOutRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getProductCI from '@salesforce/apex/ProformaSampleOutRequest.getProductCI';


export default class ProformaSampleOutRequest extends NavigationMixin(LightningElement) {

    /* ================= PROPERTIES ================= */
    @api recordId;

    @track accountId;
    @track enquiryId;
    @track quoteId;
    @track proformaInvoiceId;
    @track countryId;
    @track personId;

    @track products = [];
    @track isSubmitting = false;

    /* ================= INIT ================= */
    connectedCallback() {
        console.log('[INIT] recordId:', this.recordId);
        if (this.recordId) {
            this.loadProformaInvoiceData();
        }
    }

    /* ================= LOAD DATA ================= */
    loadProformaInvoiceData() {
        console.log('[LOAD PROFORMA] START', this.recordId);

        getProformaInvoiceData({ proformaInvoiceId: this.recordId })
            .then(res => {
                console.log('[LOAD PROFORMA] RESPONSE', JSON.stringify(res));

                this.accountId = res.accountId;
                this.enquiryId = res.enquiryId;
                this.quoteId = res.quoteId;
                this.countryId = res.countryId;
                this.personId = res.personId;
                this.proformaInvoiceId = this.recordId;

                this.products = (res.lineItems || []).map((li, index) => ({
                    index,
                    prodId: li.productId,
                    ciNo: li.ciNo || '',
                    quantity: li.quantity || '',
                    packet: '',
                    quality: '',
                    application: '',
                    unitId: null,
                    New_Product__c: false,
                    New_Product_Name__c: '',
                    New_Product_CI_No__c: ''
                }));

                if (this.products.length === 0) {
                    console.warn('[LOAD PROFORMA] No line items → adding empty row');
                    this.addProduct();
                }

                console.log('[LOAD PROFORMA] PRODUCTS', JSON.stringify(this.products));
            })
            .catch(e => {
                console.error('[LOAD PROFORMA ERROR]', e);
                this.showError(e.body?.message || e.message);
            });
    }

    /* ================= HEADER FIELDS ================= */
    handleFieldChange(e) {
        console.log('[FIELD CHANGE]', e.target.dataset.id, e.detail.recordId);
        this[e.target.dataset.id] = e.detail.recordId;
    }

    handleQuoteChange(e) {
        console.log('[QUOTE CHANGE]', e.detail.recordId);
        this.quoteId = e.detail.recordId;
    }

    handlePersonChange(e) {
        console.log('[PERSON CHANGE]', e.detail.recordId);
        this.personId = e.detail.recordId;
    }

    /* ================= PRODUCT LOOKUP ================= */
    lookupRecord(e) {
        const index = e.target.dataset.index;
        const rec = e.detail.selectedRecord;

        console.log('[PRODUCT LOOKUP RAW]', rec);

        if (!rec || !rec.Id) return;

        // set product Id first
        this.products[index] = {
            ...this.products[index],
            prodId: rec.Id,
            ciNo: '',
            New_Product__c: false
        };
        this.products = [...this.products];

        // 🔥 FETCH CI FROM APEX
        getProductCI({ productId: rec.Id })
            .then(prod => {
                console.log('[CI FROM APEX]', prod);

                this.products[index] = {
                    ...this.products[index],
                    ciNo: prod?.CI_no__c || ''
                };
                this.products = [...this.products];
            })
            .catch(err => {
                console.error('[CI FETCH ERROR]', err);
            });
    }


    /* ================= ROW HANDLERS ================= */
    handleCheckboxChange(e) {
        const index = e.target.dataset.index;
        const checked = e.target.checked;

        console.log('[NEW PRODUCT CHECKBOX]', index, checked);

        this.products[index].New_Product__c = checked;
        this.products = [...this.products];
    }

    handleTextInputChange(e) {
        const index = e.target.dataset.index;
        const field = e.target.dataset.label;

        console.log('[TEXT CHANGE]', index, field, e.target.value);

        this.products[index][field] = e.target.value;
    }

    handleProductFieldChange(e) {
        const index = e.target.dataset.index;
        const field = e.target.dataset.label;

        this.products[index][field] = e.target.value;
    }

    handleUnitSelected(e) {
        const index = e.target.dataset.index;

        console.log('[UNIT SELECTED]', index, e.detail.unitId);

        this.products[index].unitId = e.detail.unitId;
        this.products = [...this.products];
    }

    handleUnitCleared(e) {
        const index = e.target.dataset.index;
        console.log('[UNIT CLEARED]', index);

        this.products[index].unitId = null;
        this.products = [...this.products];
    }

    /* ================= ROW CONTROLS ================= */
    addProduct() {
        console.log('[ADD PRODUCT]');
        this.products = [
            ...this.products,
            {
                index: this.products.length,
                prodId: null,
                ciNo: '',
                quantity: '',
                packet: '',
                quality: '',
                application: '',
                unitId: null,
                New_Product__c: false,
                New_Product_Name__c: '',
                New_Product_CI_No__c: ''
            }
        ];
    }

    removeProduct(e) {
        const index = Number(e.target.dataset.index);
        console.log('[REMOVE PRODUCT]', index);

        this.products = this.products.filter((_, i) => i !== index);
    }

    /* ================= SUBMIT ================= */
    handleSubmitSampleOut() {
        console.log('[SUBMIT CLICK]');
        console.log('[SUBMIT PAYLOAD]', JSON.stringify(this.products));

        // REQUIRED VALIDATION ONLY
        for (let i = 0; i < this.products.length; i++) {
            const p = this.products[i];
            console.log('[VALIDATE] Row', i, p);

            if (!p.unitId) {
                return this.showError('Sample Request From Unit is required.');
            }
            if (!p.New_Product__c && !p.prodId) {
                return this.showError('Product is required.');
            }
            if (p.New_Product__c && !p.New_Product_Name__c) {
                return this.showError('New Product Name is required.');
            }
        }

        this.isSubmitting = true;

        const apexPayload = {
            requestData: {
                proformaInvoiceId: this.proformaInvoiceId,
                accountId: this.accountId,
                enquiryId: this.enquiryId,
                quoteId: this.quoteId,
                countryId: this.countryId,
                personId: this.personId,
                products: this.products
            }
        };

        console.log('[APEX CALL PAYLOAD]', JSON.stringify(apexPayload));

        createSampleOutRequest(apexPayload)
            .then(id => {
                console.log('[APEX SUCCESS] Sample Out Request Id:', id);

                this.showSuccess('Sample Out Request created successfully');

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: id,
                        objectApiName: 'Sample_Out_Request__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(e => {
                console.error('[APEX ERROR]', e);
                this.showError(e.body?.message || e.message);
            })
            .finally(() => {
                this.isSubmitting = false;
                console.log('[SUBMIT END]');
            });
    }

    /* ================= NAVIGATION ================= */
    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.proformaInvoiceId,
                objectApiName: 'Proforma_Invoice__c',
                actionName: 'view'
            }
        });
    }

    /* ================= TOASTS ================= */
    showError(msg) {
        console.error('[ERROR]', msg);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error'
        }));
    }

    showSuccess(msg) {
        console.log('[SUCCESS]', msg);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success'
        }));
    }
}