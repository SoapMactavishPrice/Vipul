import { LightningElement, track } from 'lwc';
import getDefaultFilterValues from '@salesforce/apex/TargetModule.getDefaultFilterValues';
import getTargetQuantityByEmpId from '@salesforce/apex/TargetModule.getTargetQuantityByEmpId';
import getProductTargetQtyByProdCatVal from '@salesforce/apex/TargetModule.getProductTargetQtyByProdCatVal';

export default class Targetvsactual extends LightningElement {
    @track filters;
    @track employees;
    @track employes = false;
    @track account = false;
    @track prodcategory = false;

    @track EWTarget_Flag = false;
    @track EWTarget_value = 0;

    @track EWPCTarget_Flag = false;
    @track EWPCTarget_value = 0;

    @track remaining_value = 0;

    @track compId;
    @track fiscId;
    @track empId;
    @track accId;
    @track prodCatVal;

    @track showSpinner = true;

    @track parentTabLabel;
    @track childTabLabel;

    @track employeeWise = false;
    @track employeeProductWise = false;
    @track employeeCategoryWise = false;

    connectedCallback() {
        this.getDefaultFilterValues();
    }

    getDefaultFilterValues() {
        new Promise((resolve, reject) => {
            setTimeout(() => {
                getDefaultFilterValues()
                    .then((data) => {
                        this.filters = JSON.parse(data);
                        this.fiscId = this.filters.Fiscal_Year__c;
                        resolve('Ok');
                    })
                    .catch((error) => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error.message
                        }));
                        reject('Error');
                    })
                    .finally(() => {
                        this.showSpinner = false;
                    });
            }, 0);
        });
    }

    onFilterInputChange(event) {
        if (event.target.fieldName == 'Fiscal_Year__c') {
            this.fiscId = event.target.value;
            this.empId = null;
            this.prodCatVal = null;
            this.EWTarget_value = 0;
            this.EWPCTarget_value = 0;
            this.remaining_value = 0;
        }
        if (event.target.fieldName == 'Employee__c') {
            this.empId = event.target.value;
            this.prodCatVal = null;
            this.EWTarget_value = 0;
            this.EWPCTarget_value = 0;
            this.remaining_value = 0;
            this.getEWTQuantitybyEmpId(this.empId);
        }
        if (event.target.fieldName == 'Account__c') {
            this.accId = event.target.value;
        }
        if (event.target.fieldName == 'Product_Category1__c') {
            this.prodCatVal = event.target.value;
            this.EWPCTarget_value = 0;
            this.remaining_value = 0;
            if (this.empId != null && this.empId != undefined) {
                this.getEWPCTQtybyProdCatVal(this.prodCatVal, this.empId);
            }
        }

        if (event.target.value) {
            this.filters[event.target.fieldName] = event.target.value;
        } else {
            delete this.filters[event.target.fieldName];
        }
    }

    getEWTQuantitybyEmpId(ID) {
        new Promise((resolve, reject) => {
            getTargetQuantityByEmpId({ empId: ID })
                .then((data) => {
                    this.EWTarget_value = data == '' ? 0 : parseFloat(data);
                    resolve('ok');
                })
                .catch((error) => {
                    console.error('getEWTQuantitybyEmpId error', error);
                    reject(error);
                });
        });
    }

    getEWPCTQtybyProdCatVal(VAL, ID) {
        new Promise((resolve, reject) => {
            getProductTargetQtyByProdCatVal({
                empId: ID,
                prodCatVal: VAL
            })
                .then((data) => {
                    this.EWPCTarget_value = data == '' ? 0 : parseFloat(data);
                    resolve('ok');
                })
                .catch((error) => {
                    console.error('getEWPCTQtybyProdCatVal error', error);
                    reject(error);
                });
        });
    }

    handleparentTabChange(event) {
        this.parentTabLabel = event.currentTarget.dataset.label;

        this.employeeWise = false;
        this.employeeProductWise = false;
        this.employeeCategoryWise = false;

        this.employes = false;
        this.account = false;
        this.prodcategory = false;

        this.EWTarget_Flag = false;
        this.EWPCTarget_Flag = false;

        this.empId = null;
        this.prodCatVal = null;
        this.EWTarget_value = 0;
        this.EWPCTarget_value = 0;
        this.remaining_value = 0;

        if (this.parentTabLabel === 'Employee_Wise_Target__c') {
            this.employeeWise = true;
        } else if (this.parentTabLabel === 'Employee_Wise_Account_Target__c') {
            this.employeeProductWise = true;
            this.employes = true;
            this.EWTarget_Flag = true;
        } else if (this.parentTabLabel === 'Account_Wise_Product_Target__c') {
            this.employeeProductWise = true;
            this.employes = true;
            this.account = true;
            this.EWPCTarget_Flag = true;
        }
    }

    handleChildTabChange(event) {
        this.childTabLabel = event.currentTarget.dataset.label;
    }

    handleToggleSpinner(event) {
        this.showSpinner = event.detail;
    }

    handleRemainingValueCheck(event) {
        this.remaining_value = event.detail.value;
    }
}