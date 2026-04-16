import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getYearly from '@salesforce/apex/TargetModule.getYearly';
import getMonthly from '@salesforce/apex/TargetModule.getMonthly';
import saveRecords from '@salesforce/apex/TargetModule.saveRecords';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';



const PAGINATION_STEP = 2;
const PREVIOUS_BUTTON = '&#9668;';
const NEXT_BUTTON = '&#9658;';
const THREE_DOTS = '...';

export default class AssignTargetEmployeeWise extends LightningElement {
    @track showSpinner;
    @track _compId;
    @track _fiscId;
    @track _empId;
    @track _accId;
    @track __prodCatVal;
    @track ____ProductCode;
    @track _parentTabLabel;
    @track _childTabLabel;
    @track _paginatorString;
    @track yearly;
    @track monthly;
    @track isDataModified = false;
    @track parameterLabel;
    @track pageSize;
    @track pageNumber = 1;
    @track hasRendered = false;
    @track searchThrottlingTimeout;
    @track filteredRecordHolder = [];
    @track paginationCode = [];
    @track pageSizeOptions = [10, 25, 50, 100];
    @track searchKeyword;
    @track hasDataInTable;
    @track productcategory = false;
    @track records = [];
    @track data = [];
    @track isEmployeeWiseTarget = false;
    @track allModifiedRecords = {};
    @track isSystemAdmin = false;
    @track item = {};


    @api
    set fiscId(value) {
        this._fiscId = value;
        if (this.parentTabLabel == 'Employee_Wise_Target__c') {
            console.log('getdata__from__here__111');
            if (this.fiscId) {
                this.getData();
            } else {
                this.data = null;
                this.isDataModified = false;
            }
        }
    }

    get fiscId() {
        return this._fiscId;
    }

    @api
    set empId(value) {
        this._empId = value;

        if (this.parentTabLabel == 'Employee_Wise_Product_Target__c') {
            if (this.fiscId != null && this.fiscId != undefined && this.empId != null && this.empId != undefined) {
                console.log('getdata__from__here__333');
                this.getData();
            } else {
                this.data = null;
                this.isDataModified = false;
            }
        }

        if (this.parentTabLabel == 'Employee_Wise_Account_Target__c') {
            if (this.fiscId != null && this.fiscId != undefined && this.empId != null && this.empId != undefined) {
                console.log('getdata__from__here__444');
                this.getData();
            } else {
                this.data = null;
                this.isDataModified = false;
            }
        }

        if (this.parentTabLabel == 'Account_Wise_Product_Target__c') {
            if (this.fiscId != null && this.fiscId != undefined && this.empId != null && this.empId != undefined) {
                console.log('getdata__from__here__555');
                this.getData();
            } else {
                this.data = null;
                this.isDataModified = false;
            }
        }
    }

    get empId() {
        return this._empId;
    }

    @api
    set accId(value) {
        this._accId = value;

        if (this.parentTabLabel == 'Account_Wise_Product_Target__c') {
            if (this.fiscId != null && this.fiscId != undefined && this.accId != null && this.accId != undefined && this.empId != null && this.empId != undefined) {
                console.log('getdata__from__here__666');
                this.getData();
            } else {
                this.data = null;
                this.isDataModified = false;
            }
        }
    }

    get accId() {
        return this._accId;
    }

    @api
    set parentTabLabel(value) {
        this._parentTabLabel = value;
        this.isEmployeeWiseTarget = value === 'Employee_Wise_Target__c';

        switch (this.parentTabLabel) {
            case 'Employee_Wise_Target__c':
                this.parameterLabel = 'Employee Name';
                break;
            case 'Employee_Wise_Product_Target__c':
                this.parameterLabel = 'Product';
                break;
            case 'Employee_Wise_Account_Target__c':
                this.parameterLabel = 'Account';
                break;
            case 'Account_Wise_Product_Target__c':
                this.parameterLabel = 'Product';
                break;
        }
    }

    get parentTabLabel() {
        return this._parentTabLabel;
    }

    @api
    set childTabLabel(value) {
        if (this._childTabLabel != value) {
            this._childTabLabel = value;
            if (value) {
                this.yearly = false;
                this.monthly = false;
                if (value == 'Yearly') { this.yearly = true; }
                else if (value == 'Monthly') { this.monthly = true; }
                console.log('getdata__from__here__222');
                this.getData();
            }
        }
    }

    get childTabLabel() {
        return this._childTabLabel;
    }

    @api targetValFlag;
    @track newTargetValFlag;
    @api targetAmountFlag;
    @track newTargetAmountFlag;

    handleShowSpinner() {
        this.dispatchEvent(new CustomEvent("handletogglespinner", {
            detail: true
        }));
    }

    handleHideSpinner() {
        this.dispatchEvent(new CustomEvent("handletogglespinner", {
            detail: false
        }));
    }

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME_FIELD]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.isSystemAdmin = data.fields.Profile.value.fields.Name.value === 'System Administrator';
            console.log('User is System Admin:', this.isSystemAdmin);
        } else if (error) {
            console.error('Error checking admin status:', error);
            this.isSystemAdmin = false;
        }
    }

    // // Getter methods for disabled states
    // get isQuantityDisabled() {
    //     // Quantity is disabled for non-System Admin
    //     return !this.isSystemAdmin;
    // }

    // get isINRDisabled() {
    //     // INR is disabled for non-System Admin (domestic users can still see it)
    //     return !this.isSystemAdmin;
    // }

    // get isUSDDisabled() {
    //     // USD is disabled for non-System Admin (international users can still see it)
    //     return !this.isSystemAdmin;
    // }

    // get isNotSystemAdmin() {
    //     return !this.isSystemAdmin;
    // }


    // Getter methods for disabled states - updated to only disable for Employee_Wise_Target__c
    get isQuantityDisabled() {
        // Quantity is disabled for non-System Admin ONLY for Employee_Wise_Target__c
        return !this.isSystemAdmin && this.parentTabLabel === 'Employee_Wise_Target__c';
    }

    get isINRDisabled() {
        // INR is disabled for non-System Admin ONLY for Employee_Wise_Target__c
        return !this.isSystemAdmin && this.parentTabLabel === 'Employee_Wise_Target__c';
    }

    get isUSDDisabled() {
        // USD is disabled for non-System Admin ONLY for Employee_Wise_Target__c
        return !this.isSystemAdmin && this.parentTabLabel === 'Employee_Wise_Target__c';
    }

    get isNotSystemAdmin() {
        // For monthly view, disable if not System Admin AND it's Employee_Wise_Target__c
        return !this.isSystemAdmin && this.parentTabLabel === 'Employee_Wise_Target__c';
    }

    getData() {
        console.log('getData__Called:> ');
        console.log('getDataCHECK__HA__1:> ', this.parentTabLabel);
        console.log('getDataCHECK__HA__2:> ', this.childTabLabel);
        console.log('getDataCHECK__HA__3:> ', this.fiscId);
        console.log('getDataCHECK__HA__4:> ', this.empId);
        console.log('getDataCHECK__HA__6:> ', this.accId);
        console.log('getDataCHECK__HA__5:> ', this.prodCatVal);
        this.yearly = false;
        this.monthly = false;

        if (this.childTabLabel == 'Yearly') {
            this.yearly = true;
            if (this.parentTabLabel == 'Employee_Wise_Target__c') {
                if (this.fiscId) {
                    this.getYearlyData();
                    this.productcategory = false;
                }
            }
            else if (this.parentTabLabel == 'Employee_Wise_Product_Target__c') {
                if (this.fiscId && this.empId) {
                    this.getYearlyData();
                    this.productcategory = true;
                }
                else {
                    this.yearly = false;
                }
            }
            else if (this.parentTabLabel == 'Employee_Wise_Account_Target__c') {
                if (this.fiscId && this.empId) {
                    this.getYearlyData();
                    this.productcategory = false;
                }
                else {
                    this.yearly = false;
                }
            }
            else if (this.parentTabLabel == 'Account_Wise_Product_Target__c') {
                if (this.fiscId && this.empId && this.accId) {
                    this.getYearlyData();
                    this.productcategory = true;
                }
                else {
                    this.yearly = false;
                }
            }
        } else if (this.childTabLabel == 'Monthly') {
            this.monthly = true;
            if (this.parentTabLabel != 'Employee_Wise_Product_Target__c') {
                console.log('inside 170 :> ', this.fiscId);
                if (this.fiscId) {
                    this.getMonthlyData();
                }
                else {
                    this.monthly = false;
                }
            }
            else if (this.parentTabLabel == 'Employee_Wise_Product_Target__c') {
                this.productcategory = true;
                if (this.compId && this.fiscId && this.empId) {
                    this.getMonthlyData();
                }
                if (this.fiscId && this.empId) {
                    this.getMonthlyData();
                }
                else {
                    this.monthly = false;
                }
            }
            else if (this.parentTabLabel == 'Account_Wise_Product_Target__c') {
                this.productcategory = true;
                console.log('inside Account_Wise_Product_Target__c:> ', this.fiscId, this.empId, this.accId);
                if (this.fiscId && this.empId && this.accId) {
                    this.getMonthlyData(accId);
                }
                else {
                    this.monthly = false;
                }
            }
        }
    }

    getYearlyData() {
        console.log('getYearlyData called', this.parentTabLabel);
        this.handleShowSpinner();

        this.records = [];
        this.data = [];
        this.filteredRecordHolder = [];
        this.allModifiedRecords = {};

        new Promise((resolve, reject) => {
            setTimeout(() => {
                getYearly({
                    prodId: this.prodId,
                    fiscId: this.fiscId,
                    empId: this.empId,
                    accId: this.accId,
                    parentTab: this.parentTabLabel,
                    prodCatVal: this.prodCatVal,
                })
                    .then((data) => {
                        console.log('getYearlyData data -> ', data);
                        const jsonData = JSON.parse(data);
                        console.log('getYearlyData jsonData -> ', jsonData);

                        if (jsonData.parameterData != undefined || jsonData.parameterData != null) {
                            this.records = jsonData.parameterData.map(record => {
                                const division = record.division || record.User_Division__c || '';
                                const isDomesticUser = division === 'Domestic';
                                const isInternationalUser = division === 'International';

                                return {
                                    ...record,
                                    division: division,
                                    isDomesticUser: isDomesticUser,
                                    isInternationalUser: isInternationalUser,
                                    Target_Amount_INR__c: isDomesticUser ? record.Target_Amount__c : null,
                                    Target_Amount_USD__c: isInternationalUser ? record.Target_Amount__c : null,
                                    currency: isInternationalUser ? 'USD' : 'INR',
                                    Target_Amount__c: record.Target_Amount__c,
                                    Target_Quantity__c: record.Target_Quantity__c,
                                    Target_Quantity_New__c: record.Target_Quantity_New__c,
                                    targetAmountEdit: record.targetAmountEdit !== undefined ?
                                        record.targetAmountEdit :
                                        (!record.Fiscal_Year__r?.is_Complete__c)
                                };
                            });

                            this.hasDataInTable = this.records.length > 0;
                            this.setDefaultView();
                        }
                        this.handleHideSpinner();
                        resolve('Ok');
                    })
                    .catch((error) => {
                        console.log('getYearlyData error ->', error);
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: error.message
                        }));
                        this.handleHideSpinner();
                        reject('Error');
                    })
                    .finally(result => {
                        this.handleIsDataModified();
                        this.startPagination();
                    });
            }, 0);
        });
    }

    getMonthlyData() {
        console.log('getMonthlyData called');
        console.log('getMonthlyData called For acc:> ', this.fiscId, this.empId, this.accId);
        this.handleShowSpinner();

        this.records = [];
        this.data = [];
        this.filteredRecordHolder = [];
        this.allModifiedRecords = {};

        new Promise((resolve, reject) => {
            setTimeout(() => {
                getMonthly({
                    fiscId: this.fiscId,
                    empId: this.empId,
                    accId: this.accId,
                    parentTab: this.parentTabLabel,
                    prodCatVal: this.prodCatVal,
                }).then((data) => {
                    try {
                        const jsonData = JSON.parse(data);
                        console.log('json --> ', data);
                        console.log('getMonthlyData jsonData ->', jsonData);

                        if (jsonData.parameterData != undefined || jsonData.parameterData != null) {
                            this.records = (jsonData.parameterData || []).map(record => {
                                return {
                                    ...record,
                                    childData: (record.childData || []).map(child => {
                                        return {
                                            ...child,
                                            Id: child.Id || child.ParameterId,
                                            Monthly_Target_Quantity__c_original: child.Monthly_Target_Quantity__c,
                                            Monthly_Target_Amount__c_original: child.Monthly_Target_Amount__c,
                                            isDataModified: false,
                                            className: child.className || ''
                                        };
                                    })
                                };
                            });
                            this.months = jsonData.months;
                            this.hasDataInTable = this.records.length > 0;
                            this.setDefaultView();
                        } else {
                            this.hasDataInTable = false;
                            this.records = [];
                        }

                        this.handleHideSpinner();
                        resolve('Ok');
                    } catch (error) {
                        console.error('Error parsing JSON:', error);
                        reject('Error parsing JSON');
                    }
                }).catch((error) => {
                    console.log('getMonthlyData error ->', error);
                    this.dispatchEvent(new ShowToastEvent({ title: 'Error', variant: 'error', message: error.message }));
                    this.handleHideSpinner();
                    reject('Error');
                }).finally(result => {
                    this.handleIsDataModified();
                    this.startPagination();
                });
            }, 0);
        });
    }

    onDataInput(event) {
        try {
            console.group('⚡ onDataInput Event');
            const fieldName = event.currentTarget.dataset.fieldname;
            const recordId = event.currentTarget.dataset.id;
            let value = event.target.value;
            let currencyType = event.currentTarget.dataset.currency;

            console.log('🏷️ Field:', fieldName);
            console.log('🆔 Record ID:', recordId);
            console.log('💰 Currency Type from dataset:', currencyType);
            console.log('📥 Raw Input Value:', value);

            // 1. Clean input value
            const originalValue = value;
            value = (value === '' || value === undefined || value === null) ?
                null :
                value.toString().trim();

            console.log('🧹 Cleaned Value:', value);

            // 2. Convert to number if not null/empty
            let numericValue = null;
            if (value !== null) {
                numericValue = parseFloat(value);
                console.log('🔢 Parsed Numeric Value:', numericValue);

                if (isNaN(numericValue)) {
                    console.warn('❌ Invalid number input');
                    this.showToast('Error', 'Please enter a valid number', 'error');
                    event.target.value = '';
                    return;
                }
            }

            // 3. Locate and prepare the record
            const index = this.data.findIndex(a => a.ParameterId === recordId);
            console.log('📊 Record Index:', index);

            if (index === -1) {
                console.warn('⚠️ Record not found in data');
                return;
            }

            this.allModifiedRecords = this.allModifiedRecords || {};

            if (!this.allModifiedRecords[recordId]) {
                console.log('🆕 Initializing new modified record');
                this.allModifiedRecords[recordId] = {
                    ...this.data[index],
                    isDataModified: false,
                    currencyType: this.data[index].division === 'International' ? 'USD' : 'INR' // Set default currency
                };
            }

            // 4. Store based on field type and set currency type
            if (fieldName === 'Target_Quantity__c') {
                console.log('🧮 Storing Quantity Value:', numericValue);
                this.allModifiedRecords[recordId].Target_Quantity_New__c = numericValue;
                // For quantity fields, preserve the existing currency type
                this.allModifiedRecords[recordId].currencyType = this.allModifiedRecords[recordId].currencyType ||
                    (this.data[index].division === 'International' ? 'USD' : 'INR');
            }
            else if (fieldName === 'Target_Amount_INR__c') {
                console.log('💵 Storing INR Amount Value:', numericValue);
                this.allModifiedRecords[recordId].Target_Amount_INR__c = numericValue;
                this.allModifiedRecords[recordId].currencyType = 'INR'; // Explicitly set currency
            }
            else if (fieldName === 'Target_Amount_USD__c') {
                console.log('💵 Storing USD Amount Value:', numericValue);
                this.allModifiedRecords[recordId].Target_Amount_USD__c = numericValue;
                this.allModifiedRecords[recordId].currencyType = 'USD'; // Explicitly set currency
            }

            // 5. Update modification status
            const isModified =
                this.allModifiedRecords[recordId].Target_Amount_INR__c !== null ||
                this.allModifiedRecords[recordId].Target_Amount_USD__c !== null ||
                this.allModifiedRecords[recordId].Target_Quantity_New__c !== null;

            this.allModifiedRecords[recordId].isDataModified = isModified;

            console.log('🔄 Modified Record State:', {
                ...this.allModifiedRecords[recordId],
                originalData: undefined,
                childData: undefined
            });

            this.isDataModified = Object.values(this.allModifiedRecords || {})
                .some(r => r.isDataModified);

            console.log('🔍 Global Modification Status:', this.isDataModified);

            // Validate immediately after input
            this.validateTotals();

            console.groupEnd();

        } catch (error) {
            console.error('🔥 Input Processing Error:', error);
            this.showToast('Error', 'Failed to process input', 'error');
        }
    }


    validateTotals() {
        let totalQuantity = 0;
        let totalAmount = 0;

        // Calculate totals from modified records
        Object.values(this.allModifiedRecords).forEach(record => {
            if (record.Target_Quantity_New__c !== null) {
                totalQuantity += parseFloat(record.Target_Quantity_New__c) || 0;
            }

            // Handle currency-specific amounts
            if (record.currencyType === 'USD' && record.Target_Amount_USD__c !== null) {
                totalAmount += parseFloat(record.Target_Amount_USD__c) || 0;
            } else if (record.Target_Amount_INR__c !== null) {
                totalAmount += parseFloat(record.Target_Amount_INR__c) || 0;
            }
        });

        // Add values from unmodified records
        this.records.forEach(record => {
            if (!this.allModifiedRecords[record.ParameterId]) {
                if (record.Target_Quantity_New__c !== null) {
                    totalQuantity += parseFloat(record.Target_Quantity_New__c) || 0;
                }

                if (record.division === 'International' && record.Target_Amount_USD__c !== null) {
                    totalAmount += parseFloat(record.Target_Amount_USD__c) || 0;
                } else if (record.Target_Amount_INR__c !== null) {
                    totalAmount += parseFloat(record.Target_Amount_INR__c) || 0;
                }
            }
        });

        // Validate against target limits
        if (!this.isEmployeeWiseTarget &&
            this.parentTabLabel !== 'Employee_Wise_Account_Target__c' &&
            totalQuantity > parseFloat(this.targetValFlag)) {

            this.showToast('Error',
                `Assigned Qty (${totalQuantity}) cannot be greater than Target Qty (${parseFloat(this.targetValFlag)})`,
                'error');
            return false;
        }

        if (totalAmount > parseFloat(this.targetAmountFlag)) {
            this.showToast('Error',
                `Amount (${totalAmount}) cannot be greater than Target Amount (${parseFloat(this.targetAmountFlag)})`,
                'error');
            return false;
        }

        return true;
    } validateTotals() {
        let totalQuantity = 0;
        let totalAmount = 0;

        // Calculate totals from ALL records (modified + unmodified)
        this.records.forEach(record => {
            const recordId = record.ParameterId;
            const isModified = this.allModifiedRecords[recordId]?.isDataModified;

            // Use modified value if available, otherwise use original value
            const quantityValue = isModified ?
                this.allModifiedRecords[recordId].Target_Quantity_New__c :
                record.Target_Quantity_New__c;

            const inrAmountValue = isModified ?
                this.allModifiedRecords[recordId].Target_Amount_INR__c :
                record.Target_Amount_INR__c;

            const usdAmountValue = isModified ?
                this.allModifiedRecords[recordId].Target_Amount_USD__c :
                record.Target_Amount_USD__c;

            const currencyType = isModified ?
                this.allModifiedRecords[recordId].currencyType :
                (record.division === 'International' ? 'USD' : 'INR');

            // Add quantity
            if (quantityValue !== null && quantityValue !== undefined) {
                totalQuantity += parseFloat(quantityValue) || 0;
            }

            // Add amount based on currency type
            if (currencyType === 'USD' && usdAmountValue !== null && usdAmountValue !== undefined) {
                totalAmount += parseFloat(usdAmountValue) || 0;
            } else if (inrAmountValue !== null && inrAmountValue !== undefined) {
                totalAmount += parseFloat(inrAmountValue) || 0;
            }
        });

        console.log('📊 Validation Totals:', {
            totalQuantity,
            totalAmount,
            targetQuantity: parseFloat(this.targetValFlag),
            targetAmount: parseFloat(this.targetAmountFlag)
        });

        // Validate quantity (only for non-employee-wise targets)
        let quantityValid = true;
        if (!this.isEmployeeWiseTarget &&
            this.parentTabLabel !== 'Employee_Wise_Account_Target__c' &&
            totalQuantity > parseFloat(this.targetValFlag)) {

            this.showToast('Error',
                `Assigned Qty (${totalQuantity.toFixed(2)}) cannot be greater than Target Qty (${parseFloat(this.targetValFlag)})`,
                'error');
            quantityValid = false;
        }

        // Validate amount
        let amountValid = true;
        if (totalAmount > parseFloat(this.targetAmountFlag)) {
            this.showToast('Error',
                `Amount (${totalAmount.toFixed(2)}) cannot be greater than Target Amount (${parseFloat(this.targetAmountFlag)})`,
                'error');
            amountValid = false;
        }

        // Update remaining values display
        this.dispatchEvent(new CustomEvent('remainingvalue', {
            detail: {
                value: parseFloat(this.targetValFlag) - (this.isEmployeeWiseTarget ? 0 : totalQuantity),
                amt: parseFloat(this.targetAmountFlag) - totalAmount
            }
        }));

        return quantityValid && amountValid;
    }

    validateTotals() {
        let totalQuantity = 0;
        let totalAmount = 0;

        // Calculate totals from ALL records (modified + unmodified)
        this.records.forEach(record => {
            const recordId = record.ParameterId;
            const isModified = this.allModifiedRecords[recordId]?.isDataModified;

            // Use modified value if available, otherwise use original value
            const quantityValue = isModified ?
                this.allModifiedRecords[recordId].Target_Quantity_New__c :
                record.Target_Quantity_New__c;

            const inrAmountValue = isModified ?
                this.allModifiedRecords[recordId].Target_Amount_INR__c :
                record.Target_Amount_INR__c;

            const usdAmountValue = isModified ?
                this.allModifiedRecords[recordId].Target_Amount_USD__c :
                record.Target_Amount_USD__c;

            const currencyType = isModified ?
                this.allModifiedRecords[recordId].currencyType :
                (record.division === 'International' ? 'USD' : 'INR');

            // Add quantity
            if (quantityValue !== null && quantityValue !== undefined) {
                totalQuantity += parseFloat(quantityValue) || 0;
            }

            // Add amount based on currency type
            if (currencyType === 'USD' && usdAmountValue !== null && usdAmountValue !== undefined) {
                totalAmount += parseFloat(usdAmountValue) || 0;
            } else if (inrAmountValue !== null && inrAmountValue !== undefined) {
                totalAmount += parseFloat(inrAmountValue) || 0;
            }
        });

        console.log('📊 Validation Totals:', {
            totalQuantity,
            totalAmount,
            targetQuantity: parseFloat(this.targetValFlag),
            targetAmount: parseFloat(this.targetAmountFlag)
        });

        // Validate quantity (only for non-employee-wise targets)
        let quantityValid = true;
        if (!this.isEmployeeWiseTarget &&
            this.parentTabLabel !== 'Employee_Wise_Account_Target__c' &&
            totalQuantity > parseFloat(this.targetValFlag)) {

            this.showToast('Error',
                `Assigned Qty (${totalQuantity.toFixed(2)}) cannot be greater than Target Qty (${parseFloat(this.targetValFlag)})`,
                'error');
            quantityValid = false;
        }

        // Validate amount
        let amountValid = true;
        if (totalAmount > parseFloat(this.targetAmountFlag)) {
            this.showToast('Error',
                `Amount (${totalAmount.toFixed(2)}) cannot be greater than Target Amount (${parseFloat(this.targetAmountFlag)})`,
                'error');
            amountValid = false;
        }

        // Update remaining values display
        this.dispatchEvent(new CustomEvent('remainingvalue', {
            detail: {
                value: parseFloat(this.targetValFlag) - (this.isEmployeeWiseTarget ? 0 : totalQuantity),
                amt: parseFloat(this.targetAmountFlag) - totalAmount
            }
        }));

        return quantityValid && amountValid;
    }

    handleIsDataModified() {
        console.log('handleIsDataModified called:>> ', this.records);
        this.newTargetValFlag = 0;
        this.newTargetAmountFlag = 0;

        // 1. Preserved Quantity Calculation
        if (!this.isEmployeeWiseTarget) {
            this.records.forEach(ele => {
                if (this.yearly) {
                    if (ele.Target_Quantity_New__c != null) {
                        this.newTargetValFlag += parseFloat(ele.Target_Quantity_New__c);
                    }
                }
                if (this.monthly) {
                    ele.childData.forEach(ele2 => {
                        if (ele2.Monthly_Target_Quantity__c != null) {
                            this.newTargetValFlag += parseFloat(ele2.Monthly_Target_Quantity__c);
                        }
                    });
                }
            });
        }

        // 2. Updated Amount Calculation (NEW CURRENCY LOGIC)
        this.records.forEach(ele => {
            if (this.yearly) {
                const amount = ele.division === 'International' ?
                    ele.Target_Amount_USD__c :
                    ele.Target_Amount_INR__c;
                if (amount != null) {
                    this.newTargetAmountFlag += parseFloat(amount);
                }
            }
            if (this.monthly) {
                ele.childData.forEach(ele2 => {
                    if (ele2.Monthly_Target_Amount__c != null) {
                        this.newTargetAmountFlag += parseFloat(ele2.Monthly_Target_Amount__c);
                    }
                });
            }
        });

        // 3. Preserved UI Updates
        const targetdatatable = this.template.querySelector('.targetdatatable');
        if (targetdatatable) {
            if (this.isDataModified) {
                targetdatatable.classList.add('slds-m-bottom_xx-large');
            } else {
                targetdatatable.classList.remove('slds-m-bottom_xx-large');
            }
        }

        // 4. Preserved Validation
        setTimeout(() => {
            if (!this.isEmployeeWiseTarget &&
                this.parentTabLabel !== 'Employee_Wise_Account_Target__c' &&
                this.newTargetValFlag > parseFloat(this.targetValFlag)) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: `Assigned Qty (${this.newTargetValFlag}) cannot be greater than Target Qty (${parseFloat(this.targetValFlag)})`
                }));
            }

            if (this.newTargetAmountFlag > parseFloat(this.targetAmountFlag)) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: `Amount (${this.newTargetAmountFlag}) cannot be greater than Target Amount (${parseFloat(this.targetAmountFlag)})`
                }));
            }

            this.dispatchEvent(new CustomEvent('remainingvalue', {
                detail: {
                    value: parseFloat(this.targetValFlag) - (this.isEmployeeWiseTarget ? 0 : this.newTargetValFlag),
                    amt: parseFloat(this.targetAmountFlag) - this.newTargetAmountFlag
                }
            }));
        }, 500);
    }

    handleReset() {
        console.log('handleReset called');
        this.isDataModified = false;
        this.allModifiedRecords = {};

        if (this.yearly) {
            this.records.forEach(item => {
                // 1. Preserved Quantity Reset
                item.Target_Quantity_New__c = item.Target_Quantity__c;

                // 2. New Currency Reset
                item.Target_Amount_INR__c = item.division !== 'International' ? item.Target_Amount__c : null;
                item.Target_Amount_USD__c = item.division === 'International' ? item.Target_Amount__c : null;

                // 3. Preserved Status Reset
                item.isDataModified = false;
                item.className = item.isDataModified ? "undo" : "";

                const id = item.ParameterId;
                const editItems = this.template.querySelectorAll('[data-id="' + id + '"]');
                if (editItems.length >= 1) {
                    editItems[0].classList.remove('undo');
                    editItems[0].classList.remove('slds-has-error');
                    editItems[1].innerHTML = '';
                }
            });
        } else if (this.monthly) {
            // 4. Preserved Monthly Reset (EXACTLY AS BEFORE)
            this.records.forEach(item => {
                item.childData.forEach(monthItem => {
                    monthItem.Monthly_Target_Amount__c_original = monthItem.Monthly_Target_Amount__c;
                    monthItem.Monthly_Target_Amount__c = monthItem.Monthly_Target_Amount__c_original;
                    monthItem.isDataModified = false;
                    monthItem.className = monthItem.isDataModified ? "undo" : "";

                    const id = monthItem.ParameterId;
                    const editItems = this.template.querySelectorAll('[data-childid="' + id + '"]');
                    if (editItems.length >= 1) {
                        editItems[0].classList.remove('undo');
                        editItems[0].classList.remove('slds-has-error');
                        editItems[1].innerHTML = '';
                    }
                });
            });
        }
    }

    normalizeNumericValue(value) {
        if (value === '' || value === undefined || value === null) {
            return null;
        }

        const numericValue = Number(value);
        return Number.isNaN(numericValue) ? null : numericValue;
    }

    hasValueChanged(originalValue, currentValue) {
        return this.normalizeNumericValue(originalValue) !== this.normalizeNumericValue(currentValue);
    }

    getMonthlyRecordContext(childId) {
        for (const parentRecord of this.records || []) {
            const childRecord = (parentRecord.childData || []).find(child => child.ParameterId === childId);
            if (childRecord) {
                return { parentRecord, childRecord };
            }
        }

        return {};
    }

    handleYearlyInput(event, numericValue) {
        const fieldName = event.currentTarget.dataset.fieldname;
        const recordId = event.currentTarget.dataset.id;
        const sourceRecord = (this.records || []).find(record => record.ParameterId === recordId);

        if (!sourceRecord || !fieldName) {
            return;
        }

        const modifiedRecord = this.allModifiedRecords[recordId] ?
            { ...this.allModifiedRecords[recordId] } :
            {
                ...sourceRecord,
                currencyType: sourceRecord.division === 'International' ? 'USD' : 'INR'
            };

        if (fieldName === 'Target_Quantity__c') {
            modifiedRecord.Target_Quantity_New__c = numericValue;
        } else if (fieldName === 'Target_Amount_INR__c') {
            modifiedRecord.Target_Amount_INR__c = numericValue;
            modifiedRecord.currencyType = 'INR';
        } else if (fieldName === 'Target_Amount_USD__c') {
            modifiedRecord.Target_Amount_USD__c = numericValue;
            modifiedRecord.currencyType = 'USD';
        }

        const originalQuantity = sourceRecord.Target_Quantity_New__c ?? sourceRecord.Target_Quantity__c;
        const isModified =
            this.hasValueChanged(originalQuantity, modifiedRecord.Target_Quantity_New__c) ||
            this.hasValueChanged(sourceRecord.Target_Amount_INR__c, modifiedRecord.Target_Amount_INR__c) ||
            this.hasValueChanged(sourceRecord.Target_Amount_USD__c, modifiedRecord.Target_Amount_USD__c);

        if (isModified) {
            modifiedRecord.isDataModified = true;
            modifiedRecord.className = 'undo';
            this.allModifiedRecords[recordId] = modifiedRecord;
        } else {
            delete this.allModifiedRecords[recordId];
        }
    }

    handleMonthlyInput(event, numericValue) {
        const childId = event.currentTarget.dataset.childid;
        const fieldType = event.currentTarget.dataset.type;
        const { parentRecord, childRecord } = this.getMonthlyRecordContext(childId);

        if (!parentRecord || !childRecord || !fieldType) {
            return;
        }

        const modifiedRecord = this.allModifiedRecords[childId] ?
            { ...this.allModifiedRecords[childId] } :
            {
                ...childRecord,
                Id: childRecord.Id || childRecord.ParameterId,
                ParameterCode: parentRecord.ParameterCode || null,
                ParameterDesc: parentRecord.ParameterDesc || null,
                division: parentRecord.division || null
            };

        if (fieldType === 'qty') {
            modifiedRecord.Monthly_Target_Quantity__c = numericValue;
        } else if (fieldType === 'amt') {
            modifiedRecord.Monthly_Target_Amount__c = numericValue;
        }

        const isModified =
            this.hasValueChanged(childRecord.Monthly_Target_Quantity__c_original, modifiedRecord.Monthly_Target_Quantity__c) ||
            this.hasValueChanged(childRecord.Monthly_Target_Amount__c_original, modifiedRecord.Monthly_Target_Amount__c);

        if (isModified) {
            modifiedRecord.isDataModified = true;
            modifiedRecord.className = 'undo';
            this.allModifiedRecords[childId] = modifiedRecord;
        } else {
            delete this.allModifiedRecords[childId];
        }
    }

    onDataInput(event) {
        try {
            let value = event.target.value;
            value = (value === '' || value === undefined || value === null) ? null : value.toString().trim();

            let numericValue = null;
            if (value !== null) {
                numericValue = parseFloat(value);
                if (Number.isNaN(numericValue)) {
                    this.showToast('Error', 'Please enter a valid number', 'error');
                    event.target.value = '';
                    return;
                }
            }

            this.allModifiedRecords = this.allModifiedRecords || {};

            if (this.monthly) {
                this.handleMonthlyInput(event, numericValue);
            } else {
                this.handleYearlyInput(event, numericValue);
            }

            this.isDataModified = Object.keys(this.allModifiedRecords).length > 0;
            this.handleIsDataModified();
            this.validateTotals();
        } catch (error) {
            console.error('Input Processing Error:', error);
            this.showToast('Error', 'Failed to process input', 'error');
        }
    }

    calculateTotals() {
        let totalQuantity = 0;
        let totalAmount = 0;

        if (this.monthly) {
            (this.records || []).forEach(record => {
                (record.childData || []).forEach(child => {
                    const modifiedChild = this.allModifiedRecords[child.ParameterId];
                    const quantityValue = modifiedChild ? modifiedChild.Monthly_Target_Quantity__c : child.Monthly_Target_Quantity__c;
                    const amountValue = modifiedChild ? modifiedChild.Monthly_Target_Amount__c : child.Monthly_Target_Amount__c;

                    if (quantityValue !== null && quantityValue !== undefined) {
                        totalQuantity += parseFloat(quantityValue) || 0;
                    }

                    if (amountValue !== null && amountValue !== undefined) {
                        totalAmount += parseFloat(amountValue) || 0;
                    }
                });
            });
        } else {
            (this.records || []).forEach(record => {
                const modifiedRecord = this.allModifiedRecords[record.ParameterId];
                const quantityValue = modifiedRecord ? modifiedRecord.Target_Quantity_New__c : record.Target_Quantity_New__c;
                const inrAmountValue = modifiedRecord ? modifiedRecord.Target_Amount_INR__c : record.Target_Amount_INR__c;
                const usdAmountValue = modifiedRecord ? modifiedRecord.Target_Amount_USD__c : record.Target_Amount_USD__c;
                const currencyType = modifiedRecord ?
                    modifiedRecord.currencyType :
                    (record.division === 'International' ? 'USD' : 'INR');

                if (quantityValue !== null && quantityValue !== undefined) {
                    totalQuantity += parseFloat(quantityValue) || 0;
                }

                if (currencyType === 'USD' && usdAmountValue !== null && usdAmountValue !== undefined) {
                    totalAmount += parseFloat(usdAmountValue) || 0;
                } else if (inrAmountValue !== null && inrAmountValue !== undefined) {
                    totalAmount += parseFloat(inrAmountValue) || 0;
                }
            });
        }

        return { totalQuantity, totalAmount };
    }

    validateTotals() {
        const { totalQuantity, totalAmount } = this.calculateTotals();
        const targetQuantity = parseFloat(this.targetValFlag);
        const targetAmount = parseFloat(this.targetAmountFlag);
        const hasTargetQuantity = Number.isFinite(targetQuantity);
        const hasTargetAmount = Number.isFinite(targetAmount);

        let quantityValid = true;
        if (hasTargetQuantity &&
            !this.isEmployeeWiseTarget &&
            this.parentTabLabel !== 'Employee_Wise_Account_Target__c' &&
            totalQuantity > targetQuantity) {
            this.showToast(
                'Error',
                `Assigned Qty (${totalQuantity.toFixed(2)}) cannot be greater than Target Qty (${targetQuantity})`,
                'error'
            );
            quantityValid = false;
        }

        let amountValid = true;
        if (hasTargetAmount && totalAmount > targetAmount) {
            this.showToast(
                'Error',
                `Amount (${totalAmount.toFixed(2)}) cannot be greater than Target Amount (${targetAmount})`,
                'error'
            );
            amountValid = false;
        }

        this.dispatchEvent(new CustomEvent('remainingvalue', {
            detail: {
                value: hasTargetQuantity ? targetQuantity - (this.isEmployeeWiseTarget ? 0 : totalQuantity) : 0,
                amt: hasTargetAmount ? targetAmount - totalAmount : 0
            }
        }));

        return quantityValid && amountValid;
    }

    handleIsDataModified() {
        const { totalQuantity, totalAmount } = this.calculateTotals();
        const targetQuantity = parseFloat(this.targetValFlag);
        const targetAmount = parseFloat(this.targetAmountFlag);
        const hasTargetQuantity = Number.isFinite(targetQuantity);
        const hasTargetAmount = Number.isFinite(targetAmount);

        this.newTargetValFlag = totalQuantity;
        this.newTargetAmountFlag = totalAmount;

        const targetdatatable = this.template.querySelector('.targetdatatable');
        if (targetdatatable) {
            if (this.isDataModified) {
                targetdatatable.classList.add('slds-m-bottom_xx-large');
            } else {
                targetdatatable.classList.remove('slds-m-bottom_xx-large');
            }
        }

        this.dispatchEvent(new CustomEvent('remainingvalue', {
            detail: {
                value: hasTargetQuantity ? targetQuantity - (this.isEmployeeWiseTarget ? 0 : totalQuantity) : 0,
                amt: hasTargetAmount ? targetAmount - totalAmount : 0
            }
        }));
    }

    handleReset() {
        this.isDataModified = false;
        this.allModifiedRecords = {};

        if (this.yearly) {
            this.records.forEach(item => {
                item.Target_Quantity_New__c = item.Target_Quantity__c;
                item.Target_Amount_INR__c = item.division !== 'International' ? item.Target_Amount__c : null;
                item.Target_Amount_USD__c = item.division === 'International' ? item.Target_Amount__c : null;
                item.isDataModified = false;
                item.className = '';

                const id = item.ParameterId;
                const editItems = this.template.querySelectorAll('[data-id="' + id + '"]');
                if (editItems.length >= 1) {
                    editItems[0].classList.remove('undo');
                    editItems[0].classList.remove('slds-has-error');
                    editItems[1].innerHTML = '';
                }
            });
        } else if (this.monthly) {
            this.records.forEach(item => {
                item.childData.forEach(monthItem => {
                    monthItem.Monthly_Target_Quantity__c = monthItem.Monthly_Target_Quantity__c_original;
                    monthItem.Monthly_Target_Amount__c = monthItem.Monthly_Target_Amount__c_original;
                    monthItem.isDataModified = false;
                    monthItem.className = '';

                    const id = monthItem.ParameterId;
                    const editItems = this.template.querySelectorAll('[data-childid="' + id + '"]');
                    if (editItems.length >= 1) {
                        editItems[0].classList.remove('undo');
                        editItems[0].classList.remove('slds-has-error');
                        editItems[1].innerHTML = '';
                    }
                });
            });
        }

        this.setDataAccordingToPagination();
        this.handleIsDataModified();
    }

    getSavePayload() {
        const modifiedRecords = Object.values(this.allModifiedRecords || {}).filter(record => record.isDataModified);

        if (this.monthly) {
            return modifiedRecords.map(record => {
                return {
                    Id: record.Id || record.ParameterId,
                    ParameterId: record.ParameterId,
                    Monthly_Target_Amount__c: record.Monthly_Target_Amount__c !== null && record.Monthly_Target_Amount__c !== undefined ?
                        Number(record.Monthly_Target_Amount__c) :
                        null,
                    Monthly_Target_Quantity__c: record.Monthly_Target_Quantity__c !== null && record.Monthly_Target_Quantity__c !== undefined ?
                        Number(record.Monthly_Target_Quantity__c) :
                        null,
                    division: record.division || null,
                    ParameterCode: record.ParameterCode || null,
                    ParameterDesc: record.ParameterDesc || null
                };
            });
        }

        return modifiedRecords.map(record => {
            const isInternational = record.currencyType === 'USD';
            const targetAmountINR = record.Target_Amount_INR__c !== null && record.Target_Amount_INR__c !== undefined ?
                Number(record.Target_Amount_INR__c) :
                null;
            const targetAmountUSD = record.Target_Amount_USD__c !== null && record.Target_Amount_USD__c !== undefined ?
                Number(record.Target_Amount_USD__c) :
                null;
            const targetQuantity = record.Target_Quantity_New__c !== null && record.Target_Quantity_New__c !== undefined ?
                Number(record.Target_Quantity_New__c) :
                null;

            return {
                Id: record.Id || null,
                ParameterId: record.ParameterId,
                Target_Amount__c: isInternational ? targetAmountUSD : targetAmountINR,
                Target_Amount_INR__c: isInternational ? null : targetAmountINR,
                Target_Amount_USD__c: isInternational ? targetAmountUSD : null,
                Target_Quantity__c: targetQuantity,
                division: record.division || 'Domestic',
                currencyType: record.currencyType || 'INR',
                ParameterCode: record.ParameterCode || null,
                ParameterDesc: record.ParameterDesc || null
            };
        });
    }

    async handleSave() {
        try {
            this.handleShowSpinner();
            console.group('💾 handleSave');

            // 1. Log initial state
            console.log('📋 Modified Records:', JSON.parse(JSON.stringify(this.allModifiedRecords || {})));

            if (!this.allModifiedRecords || Object.keys(this.allModifiedRecords).length === 0) {
                console.warn('No modified records to save');
                this.showToast('Info', 'No changes to save', 'info');
                this.handleHideSpinner();
                return;
            }

            // 2. Validate before saving
            if (!this.validateTotals()) {
                console.warn('❌ Validation failed - preventing save');
                this.handleHideSpinner();
                return;
            }

            // 3. Transform data with null checks
            const finalData = Object.values(this.allModifiedRecords)
                .filter(record => {
                    console.log(`🔍 Checking record ${record.ParameterId}:`, {
                        isModified: record.isDataModified,
                        usdAmount: record.Target_Amount_USD__c,
                        inrAmount: record.Target_Amount_INR__c,
                        qty: record.Target_Quantity_New__c
                    });
                    return record.isDataModified &&
                        (record.Target_Quantity_New__c !== null ||
                            record.Target_Amount_INR__c !== null ||
                            record.Target_Amount_USD__c !== null);
                })
                .map(record => {
                    // Determine currency based on which field was modified
                    const isInternational = record.currencyType === 'USD';
                    const targetAmountINR = record.Target_Amount_INR__c !== null ?
                        Number(record.Target_Amount_INR__c) : null;
                    const targetAmountUSD = record.Target_Amount_USD__c !== null ?
                        Number(record.Target_Amount_USD__c) : null;
                    const targetQuantity = record.Target_Quantity_New__c !== null ?
                        Number(record.Target_Quantity_New__c) : null;

                    console.log(`🔄 Transforming ${record.ParameterId}`, {
                        currencyType: record.currencyType,
                        division: record.division,
                        isInternational,
                        targetAmountINR,
                        targetAmountUSD,
                        targetQuantity
                    });

                    return {
                        Id: record.Id || null,
                        ParameterId: record.ParameterId,
                        Target_Amount__c: isInternational ? targetAmountUSD : targetAmountINR,
                        Target_Amount_INR__c: isInternational ? null : targetAmountINR,
                        Target_Amount_USD__c: isInternational ? targetAmountUSD : null,
                        Target_Quantity__c: targetQuantity,
                        division: record.division || 'Domestic',
                        currencyType: record.currencyType || 'INR'
                    };
                })
                .filter(record => {
                    const isValid = record.Target_Amount_INR__c !== null ||
                        record.Target_Amount_USD__c !== null ||
                        record.Target_Quantity__c !== null;
                    console.log(`✔️ Record ${record.ParameterId} valid:`, isValid);
                    return isValid;
                });

            console.log('📦 Final Data to Save:', JSON.parse(JSON.stringify(finalData)));

            if (finalData.length === 0) {
                console.warn('No valid records after filtering');
                this.showToast('Error',
                    'Please enter valid amounts or quantities before saving',
                    'error');
                this.handleHideSpinner();
                return;
            }

            // 4. Save operation
            const result = await saveRecords({
                data: JSON.stringify(finalData),
                companyMasterId: this.compId,
                fiscalYearId: this.fiscId,
                employeeId: this.empId,
                accId: this.accId,
                type: this.parentTabLabel,
                subType: this.childTabLabel
            });

            const parsedResult = JSON.parse(result);
            console.log('✅ Save Result:', parsedResult);

            if (parsedResult.status === 'Success') {
                // RESET THE MODIFICATION STATE - THIS HIDES THE BUTTONS
                this.allModifiedRecords = {};
                this.isDataModified = false;

                this.showToast('Success', 'Data saved successfully', 'success');
                setTimeout(() => this.getData(), 500);
            } else {
                throw new Error(parsedResult.message || 'Save operation failed');
            }
        } catch (error) {
            console.error('❌ Save Error:', error);
            this.showToast('Error', error.message || 'Failed to save data', 'error');
        } finally {
            console.groupEnd();
            this.handleHideSpinner();
        }
    }

    async handleSave() {
        try {
            this.handleShowSpinner();
            console.group('handleSave');

            if (!this.allModifiedRecords || Object.keys(this.allModifiedRecords).length === 0) {
                this.showToast('Info', 'No changes to save', 'info');
                this.handleHideSpinner();
                return;
            }

            if (!this.validateTotals()) {
                this.handleHideSpinner();
                return;
            }

            const finalData = this.getSavePayload();
            if (finalData.length === 0) {
                this.showToast('Info', 'No changes to save', 'info');
                this.handleHideSpinner();
                return;
            }

            const result = await saveRecords({
                data: JSON.stringify(finalData),
                companyMasterId: this.compId,
                fiscalYearId: this.fiscId,
                employeeId: this.empId,
                accId: this.accId,
                type: this.parentTabLabel,
                subType: this.childTabLabel
            });

            const parsedResult = JSON.parse(result);
            if (parsedResult.status === 'Success') {
                this.allModifiedRecords = {};
                this.isDataModified = false;
                this.showToast('Success', 'Data saved successfully', 'success');
                setTimeout(() => this.getData(), 500);
            } else {
                const errorMessage =
                    parsedResult.message ||
                    (parsedResult.errorList || []).find(item => item.message)?.message ||
                    'Save operation failed';
                throw new Error(errorMessage);
            }
        } catch (error) {
            console.error('Save Error:', error);
            this.showToast('Error', error.message || 'Failed to save data', 'error');
        } finally {
            console.groupEnd();
            this.handleHideSpinner();
        }
    }

    // Helper methods
    validateBeforeSave() {
        // Your existing validation logic
        return true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    setDefaultView() {
        this.filteredRecordHolder = this.records;
        this.pageSize = this.getSelectedPaging();
        this.data = [];
        if (this.pageSize < this.filteredRecordCount) {
            for (let i = 0; i < this.pageSize; i++) {
                this.data.push(this.filteredRecordHolder[i]);
            }
        }
        else {
            this.data = this.filteredRecordHolder;
        }
        console.log('CHECK::>> ', this.data);
    }

    setRecordsToDisplay() {
        let pageSize = this.getSelectedPaging();
        let lastPosition = (pageSize * this.pageNumber);
        let firstPosition = (lastPosition - pageSize);

        this.data = [];
        let finalLastPosition = lastPosition < this.filteredRecordCount ? lastPosition : this.filteredRecordCount;

        for (let i = firstPosition; i < finalLastPosition; i++) {
            let record = { ...this.filteredRecordHolder[i] };

            if (this.yearly) {
                if (this.allModifiedRecords[record.ParameterId]) {
                    record = { ...record, ...this.allModifiedRecords[record.ParameterId] };
                }
            } else if (this.monthly) {
                record.childData = record.childData.map(child => {
                    return this.allModifiedRecords[child.ParameterId] ?
                        { ...child, ...this.allModifiedRecords[child.ParameterId] } :
                        child;
                });
            }

            this.data.push(record);
        }
    }

    paginationAdd(start, end) {
        for (let index = start; index < end; index++) {
            this.paginationCode.push(index);
        }
    }

    paginationFirst() {
        this.paginationCode = [...this.paginationCode, 1, THREE_DOTS];
    }

    paginationLast() {
        this.paginationCode = [...this.paginationCode, THREE_DOTS, this.getCountOfTotalPages()];
    }

    previousPage() {
        if (!this.hasDataInTable) {
            return;
        }
        this.pageNumber--;
        if (this.pageNumber < 1) {
            this.pageNumber = 1;
        }
        this.setDataAccordingToPagination();
    }

    nextPage() {
        if (!this.hasDataInTable) {
            return;
        }
        this.pageNumber++;
        if (this.pageNumber > this.getCountOfTotalPages()) {
            this.pageNumber = this.getCountOfTotalPages();
        }
        this.setDataAccordingToPagination();
    }

    paginationWithPageNumber(event) {
        let selectedPageNumber = event.currentTarget.dataset.pageNumber;
        if (selectedPageNumber == THREE_DOTS) {
            return;
        }
        this.pageNumber = parseInt(selectedPageNumber);
        this.setDataAccordingToPagination();
    }

    setDataAccordingToPagination() {
        this.setRecordsToDisplay();
        this.startPagination();
    }

    getCountOfTotalPages() {
        return Math.ceil(((this.filteredRecordCount ? this.filteredRecordCount : (this.hasDataInTable ? this.totalNumberOfRows : 0)) / this.getSelectedPaging()));
    }

    paginationCreateOnDOM() {
        console.log('paginationCreateOnDOM called');
        let data = [PREVIOUS_BUTTON, ...this.paginationCode, NEXT_BUTTON];
        this.paginationCode = [];

        let paginationContainer = this.template.querySelector('[data-pagination]');
        paginationContainer.innerHTML = '';

        data.forEach(item => {
            let element = document.createElement("div");
            element.innerHTML = item;
            element.dataset.pageNumber = item;
            if (item == this.pageNumber) {
                element.classList.add('active-button');
            }
            if (item == PREVIOUS_BUTTON) {
                element.addEventListener("click", this.previousPage.bind(this));
            } else if (item == NEXT_BUTTON) {
                element.addEventListener("click", this.nextPage.bind(this));
            } else if (item == THREE_DOTS) {
                element.classList.add('more-button');
            } else {
                element.addEventListener("click", this.paginationWithPageNumber.bind(this));
            }
            paginationContainer.appendChild(element);
        });
    }

    startPagination() {
        let totalPages = this.getCountOfTotalPages();
        if (totalPages < PAGINATION_STEP * 2 + 6) {
            this.paginationAdd(1, totalPages + 1);
        } else if (this.pageNumber < PAGINATION_STEP * 2 + 1) {
            this.paginationAdd(1, PAGINATION_STEP * 2 + 4);
            this.paginationLast();
        } else if (this.pageNumber > totalPages - PAGINATION_STEP * 2) {
            this.paginationFirst();
            this.paginationAdd(totalPages - PAGINATION_STEP * 2 - 2, totalPages + 1);
        } else {
            this.paginationFirst();
            this.paginationAdd(this.pageNumber - PAGINATION_STEP, this.pageNumber + PAGINATION_STEP + 1);
            this.paginationLast();
        }
        this.paginationCreateOnDOM();
    }

    handlePageEntries(event) {
        this.pageNumber = 1;
        this.setDataAccordingToPagination();
    }

    dataFilter({ ParameterName, ParameterCode }, searchTerm) {
        console.log('dataFilter check');
        console.log('dataFilter ParameterName', ParameterName);
        console.log('dataFilter ParameterCode', ParameterCode);
        console.log('dataFilter searchTerm', searchTerm);

        let filteredItems = [];
        this.pageNumber = 1;
        const lowerCaseSearchTerm = searchTerm.toLowerCase();

        if (ParameterName === 'all' || ParameterCode === 'all') {
            filteredItems = this.records.filter(o =>
                Object.keys(o).some(k =>
                    o[k].toLowerCase().includes(lowerCaseSearchTerm)
                )
            );
        } else {
            filteredItems = this.records.filter(result =>
                (result[ParameterName] && result[ParameterName].toLowerCase().includes(lowerCaseSearchTerm)) ||
                (result[ParameterCode] && result[ParameterCode].toLowerCase().includes(lowerCaseSearchTerm))
            );
        }

        console.log('this.records.filter>>', this.records.filter);
        this.filteredRecordHolder = filteredItems;
        this.setDataAccordingToPagination();
    }

    handleSearching(event) {
        let searchTerm = event.target.value;
        searchTerm = searchTerm.trim().replace(/\*/g, '').toLowerCase();
        if (searchTerm == '' || searchTerm == null || searchTerm == undefined) {
            this.filteredRecordHolder = this.records;
            this.setDataAccordingToPagination();
        }
        else {
            this.pageNumber = 1;
            if (searchTerm.length) {
                this.dataFilter(this.getSearchTerm(), searchTerm);
            }
            else {
                this.filteredRecordHolder = [];
                this.setDataAccordingToPagination();
            }
        }
        this.searchThrottlingTimeout = null;
    }

    getSearchTerm() {
        return {
            ParameterName: 'ParameterName',
            ParameterCode: 'ParameterCode'
        };
    }

    getSelectedPaging() {
        let input = this.template.querySelector('[data-show-entries-input]');
        return input ? parseInt(input.value) : 10;
    }

    get hasRecords() {
        return (this.dataCollection.length ? true : false);
    }

    get filteredRecordCount() {
        return this.filteredRecordHolder.length;
    }

    get pageLengthDefaultValue() {
        return (this.pageSizeOptions.length ? this.pageSizeOptions[0].toString() : '10');
    }

    get totalNumberOfRows() {
        return (this.dataCollection ? this.dataCollection.length : 0);
    }

    get showingEntriesMessage() {
        let message = '', pages = 0, lastRecordNumber = 0, start = 0, end = 0, pageEntries = this.getSelectedPaging();
        if (this.getSearchTerm().length) {
            pages = (this.filteredRecordCount / pageEntries);
            lastRecordNumber = (this.pageNumber * pageEntries);
            end = (this.filteredRecordCount >= lastRecordNumber) ? lastRecordNumber : this.filteredRecordCount;
            start = ((pages > 1) ? ((this.filteredRecordCount == end) ? this.filteredRecordCount : ((end - pageEntries) + 1)) : (this.hasDataInTable ? 1 : 0));
            message = `Showing ${start} to ${end} of ${this.filteredRecordCount} entries (filtered from ${this.totalNumberOfRows} total entries)`;
        } else {
            pages = (this.totalNumberOfRows / pageEntries);
            lastRecordNumber = (this.pageNumber * pageEntries);
            end = ((this.totalNumberOfRows >= lastRecordNumber) ? lastRecordNumber : this.totalNumberOfRows);
            start = ((pages > 1) ? ((this.totalNumberOfRows == end) ? this.totalNumberOfRows : ((end - pageEntries) + 1)) : (this.hasDataInTable ? 1 : 0));
            message = `Showing ${start} to ${end} of ${this.totalNumberOfRows} entries`;
        }
        return message;
    }

    get pageLengthOptions() {
        return this.pageSizeOptions.map(x => {
            return { label: x.toString(), value: x.toString() };
        });
    }

    updateDisabledStates() {
        this.records = this.records.map(record => {
            return {
                ...record,
                // All fields disabled for non-System Admin
                quantityDisabled: !this.isSystemAdmin,
                inrDisabled: !this.isSystemAdmin,
                usdDisabled: !this.isSystemAdmin
            };
        });
    }
}
