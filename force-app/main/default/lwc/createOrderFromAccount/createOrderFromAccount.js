import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import Order_OBJECT from '@salesforce/schema/Order';
import Order_Type from '@salesforce/schema/Order.Order_Type__c';
import Inco_Terms from '@salesforce/schema/Order.Inco_Terms__c';
import Payment_Terms from '@salesforce/schema/Order.Payment_Terms__c';
import CurrencyIsoCode from '@salesforce/schema/Order.CurrencyIsoCode';
import Status from '@salesforce/schema/Order.Status';
import Order_Source from '@salesforce/schema/Order.Order_Source__c';
import COMMISSION_TYPE_FIELD from '@salesforce/schema/OrderItem.Commission_Type__c';
import getOrders from '@salesforce/apex/OrderController.getOrders';
import getOrderDetails from '@salesforce/apex/OrderController.getOrderDetails';
import createOrUpdateOrder from '@salesforce/apex/OrderController.createOrUpdateOrder';
import getUserInfoWithOrderType from '@salesforce/apex/OrderController.getUserInfoWithOrderType';
import fetchListPrice from '@salesforce/apex/MarketingForm.fetchListPrice';
import findRecentPrices from '@salesforce/apex/AddOppLineItem.findRecentPrices';
import getQualityForProduct from '@salesforce/apex/AddOppLineItem.getQualityForProduct';
import getOrderPicklistValues from '@salesforce/apex/OrderController.getOrderPicklistValues';
import USER_DIVISION_FIELD from '@salesforce/schema/User.User_Division__c';
import getCheckListsByAccount from '@salesforce/apex/OrderController.getCheckListsByAccount';



const ACCOUNT_FIELDS = [
    'Account.Id',
    'Account.Country__c',
    'Account.Buyer_s_Ref_PO__c',
    'Account.Buyer_s_PO_Date__c',
    'Account.INCO_Terms__c',
    'Account.Payment_Terms__c',
    'Account.CurrencyIsoCode'
];

export default class CreateOrderFromAccount extends NavigationMixin(LightningElement) {

    @api recordId;

    @track isLoading = false;
    @track selectedMode = '';
    @track selectedOrderId = '';
    @track showModeSelection = true;
    @track showForm = false;
    @track showQuoteSelection = false;
    @track isLeadTypeEnabled = false;
    @track userDivision = '';
    @track userProfileName = '';
    @track orderTypeOptions = [];
    @track isOrderTypeEnabled = false;
    @track currencyfilter;
    @track isOpenFileView = false;
    @track lastFivePrices = [];
    @track currentProductIndex = 0;
    @track checkListOptions = [];
    @track selectedCheckListId = ''; // For UI binding



    @track orderFields = {
        AccountId: '',
        Country__c: '',
        PoNumber: '',
        PoDate: '',
        Order_Type__c: '',
        Inco_Terms__c: '',
        Payment_Terms__c: '',
        CurrencyIsoCode: '',
        Status: 'Draft',
        Order_Source__c: '',
        EffectiveDate: '',
        Check_List__c: ''
    };


    @track userDivision = '';
    //@track isOrderTypeDisabled = true; // Default to disabled until we know user's role
    @track isOrderTypeEnabled = false;
    @track userProfileName = '';

    // Wire to get current user's division
    @wire(getRecord, {
        recordId: '$userId',
        fields: [USER_DIVISION_FIELD]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.userDivision = data.fields.User_Division__c.value;
            console.log('User division loaded:', this.userDivision);
            this.setOrderTypeBasedOnDivision();
        } else if (error) {
            console.error('Error fetching user division:', error);
            this.showToast('Error', 'Failed to load user information', 'error');
        }
    }

    // @wire(getUserInfoWithOrderType)
    // wiredOrderType({ data, error }) {
    //     if (data) {
    //         console.log('Order type data loaded:', JSON.stringify(data));
    //         this.orderTypeOptions = data.filteredPicklist;
    //         this.optionsCommissionType = data.commissionTypeOptions;
    //         this.userProfileName = data.userInfo.ProfileName;

    //         // Handle System Admin case
    //         if (this.userProfileName === 'System Administrator') {
    //             console.log('User is System Administrator');
    //             this.isOrderTypeEnabled = true;
    //             this.isOrderTypeDisabled = false;
    //         }
    //         // Handle non-admin users
    //         else {
    //             console.log('User is not System Administrator');
    //             this.isOrderTypeEnabled = false;
    //             this.setOrderTypeBasedOnDivision();
    //         }
    //     } else if (error) {
    //         console.error('Error fetching Order Type info:', error);
    //         this.showToast('Error', 'Failed to load order type options', 'error');
    //     }
    // }

    // @track orderLineItems = [{
    //     id: 'row_0',
    //     index: 0,
    //     prodId: '',
    //     Product2Id: '',
    //     ListPrice: '',
    //     Quantity: '',
    //     UnitPrice: '',
    //     quality: '',
    //     CommissionType: '',
    //     commissionval: '',
    //     commissionper: '',
    //     totalprice: '',
    //     freightval: '',
    //     finalprice: '',
    //     totalpricefinal: '',
    //     isDisabled: false,
    //     isvaldisabled: false,
    //     isperdisabled: false,
    //     isFreightDisabled: false
    // }];

    @track orderLineItems = [{
        id: 'row_0',
        index: 0,
        prodId: '',
        Product2Id: '',
        ListPrice: '',
        Quantity: '',
        UnitPrice: '',
        Quality__c: '', // Changed from 'quality' to match API name
        Commission_Type__c: '', // Changed from 'CommissionType'
        Commission_Value__c: '', // Changed from 'commissionval'
        Commission_Percentage__c: '', // Changed from 'commissionper'
        Total_Price__c: '', // Changed from 'totalprice'
        freightval: '', // Changed from 'freightval'
        Discount__c: '',
        Final_Price__c: '', // Changed from 'finalprice'
        Total_Price_Final__c: '', // Changed from 'totalpricefinal'
        isDisabled: false,
        isvaldisabled: false,
        isperdisabled: false,
        isFreightDisabled: false
    }];

    @track orderOptions = [];
    @track optionsCommissionType = [];
    @track optionsPackagingType = [];
    @track optionsPackagingTypeValues = [];
    @track accountData = {};
    rowIdCounter = 1;

    @track userDivision;
    //@track isOrderTypeDisabled = true; // Default to disabled until we know user's role
    @track isOrderTypeEnabled = false;
    @track userProfileName = '';

    // Wire to get current user's division
    @wire(getRecord, {
        recordId: '$userId',
        fields: [USER_DIVISION_FIELD]
    })
    wiredUser({ error, data }) {
        if (data) {
            this.userDivision = data.fields.User_Division__c.value;
            console.log('User division loaded:', this.userDivision);
            this.setOrderTypeBasedOnDivision();
        } else if (error) {
            console.error('Error fetching user division:', error);
            this.showToast('Error', 'Failed to load user information', 'error');
        }
    }

    // @wire(getUserInfoWithOrderType)
    // wiredOrderType({ data, error }) {
    //     if (data) {
    //         console.log('Order type data loaded:', JSON.stringify(data));
    //         this.orderTypeOptions = data.filteredPicklist;
    //         this.optionsCommissionType = data.commissionTypeOptions;
    //         this.userProfileName = data.userInfo.ProfileName;
      //          this.optionsPackagingType = data.packagingTypeOptions;

    //         // Handle System Admin case
    //         if (this.userProfileName === 'System Administrator') {
    //             console.log('User is System Administrator');
    //             this.isOrderTypeEnabled = true;
    //             this.isOrderTypeDisabled = false;
    //         }
    //         // Handle non-admin users
    //         else {
    //             console.log('User is not System Administrator');
    //             this.isOrderTypeEnabled = false;
    //             this.setOrderTypeBasedOnDivision();
    //         }
    //     } else if (error) {
    //         console.error('Error fetching Order Type info:', error);
    //         this.showToast('Error', 'Failed to load order type options', 'error');
    //     }
    // }

    setOrderTypeBasedOnDivision() {
        if (this.userDivision && this.orderTypeOptions) {
            console.log('Setting order type based on division:', this.userDivision);

            // Find matching order type option (case insensitive)
            const matchingOption = this.orderTypeOptions.find(
                option => option.value.toLowerCase() === this.userDivision.toLowerCase()
            );

            if (matchingOption) {
                console.log('Found matching order type:', matchingOption.value);
                this.orderFields.Order_Type__c = matchingOption.value;
                this.isOrderTypeDisabled = true; // Lock the field for non-admins
            } else {
                console.warn('No matching order type found for division:', this.userDivision);
                // If no match, allow selection but show warning
                this.isOrderTypeDisabled = false;
                this.showToast('Warning',
                    `No matching order type found for your division (${this.userDivision})`,
                    'warning');
            }
        }
    }


    // Get metadata for default Record Type Id
    @wire(getObjectInfo, { objectApiName: Order_OBJECT })
    objectInfo;

    // Individual picklist wires using recordTypeId from objectInfo
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: Inco_Terms
    })
    incoTermsPicklist;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: Payment_Terms
    })
    paymentTermsPicklist;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: CurrencyIsoCode
    })
    currencyPicklist;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: Status
    })
    statusPicklist;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: Order_Source
    })
    orderSourcePicklist;

    @wire(getOrderPicklistValues)
    wiredPicklist({ error, data }) {
        if (data) {

            this.optionsCommissionType = data.filter(item => item.field === 'Commission_Type__c').map(item => ({
                label: item.label,
                value: item.value
            }));
            this.optionsPackagingType = data
                .filter(item => item.field === 'Packaging__c')
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
            this.optionsPackagingTypeValues = data
                .filter(item => item.field === 'Packing_Type__c')
                .map(item => ({
                    label: item.label,
                    value: item.value
                }));
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }


    get isCommissionValueDisabled() {
        const answer = this.addAnswer[this.index];
        return answer && answer.CommissionType === 'Percentage';
    }

    get isCommissionPercentageDisabled() {
        const answer = this.addAnswer[this.index];
        return answer && answer.CommissionType === 'Value';
    }

    get picklistOptions() {
        return {
            Order_Type__c: this.orderTypeOptions ?? [],
            Inco_Terms__c: this.incoTermsPicklist?.data?.values ?? [],
            Payment_Terms__c: this.paymentTermsPicklist?.data?.values ?? [],
            CurrencyIsoCode: this.currencyPicklist?.data?.values ?? [],
            Status: this.statusPicklist?.data?.values ?? [],
            Order_Source__c: this.orderSourcePicklist?.data?.values ?? []
        };
    }

    get modeOptions() {
        return [
            { label: 'New Order', value: 'new' },
            { label: 'Existing Order', value: 'existing' }
        ];
    }

    @wire(getUserInfoWithOrderType)
    wiredOrderType({ data, error }) {
        if (data) {
            this.orderTypeOptions = data.filteredPicklist;
            this.optionsCommissionType = data.commissionTypeOptions;
            this.optionsPackagingType = data.packagingTypeOptions;
            this.optionsPackagingTypeValues = data.optionsPackagingTypeValuesOption;

            const currentUserProfile = data.userInfo.ProfileName;
            const specialProfileName = 'System Administrator';

            this.isOrderTypeEnabled = (currentUserProfile === specialProfileName);
            this.userDivision = data.userInfo.UserDivision;

            if (this.orderTypeOptions.length > 0) {
                const defaultOrderType = this.orderTypeOptions.find(option => option.value === 'Domestic');
                if (defaultOrderType) {
                    this.orderFields.Order_Type__c = 'Domestic';
                } else {
                    const fallbackOrderType = this.orderTypeOptions.find(option => option.value === 'International');
                    if (fallbackOrderType) {
                        this.orderFields.Order_Type__c = 'International';
                    }
                }
            }
        } else if (error) {
            console.error('Error fetching Order Type info:', error);
        }
    }

    get isOrderTypeDisabled() {
        return !this.isOrderTypeEnabled;
    }

    handleOrderTypeChange(event) {
        const field = event.target.dataset.id;
        this.orderFields[field] = event.detail.value;
    }

    get showCheckList() {
        return this.orderFields.Order_Type__c !== 'Domestic';
    }


    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    accountInfo({ error, data }) {
        if (data) {
            this.accountData = data;
            // Set these values but don't override if we're loading an existing order
            if (!this.selectedOrderId) {
                this.orderFields = {
                    ...this.orderFields,
                    AccountId: data.fields.Id.value,
                    Country__c: data.fields.Country__c.value || '',
                    PoNumber: data.fields.Buyer_s_Ref_PO__c.value || '',
                    PoDate: data.fields.Buyer_s_PO_Date__c.value || '',
                    Inco_Terms__c: data.fields.INCO_Terms__c.value || '',
                    Payment_Terms__c: data.fields.Payment_Terms__c.value || '',
                    CurrencyIsoCode: data.fields.CurrencyIsoCode?.value || ''
                };
                this.currencyfilter = `Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '${this.orderFields.CurrencyIsoCode}')`;
            }

            // ✅ Call loadCheckList here to populate the checklist on first load
            this.loadCheckList(data.fields.Id.value);

            const today = new Date();
            this.orderFields.EffectiveDate = today.toISOString().split('T')[0];
        } else if (error) {
            this.showToast('Error', 'Failed to fetch Account fields.', 'error');
        }
    }

    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;

        if (!selectedRecord) {
            console.log("No record selected");
            if (this.orderLineItems && this.orderLineItems[index]) {
                this.orderLineItems[index].quality = null;
                this.orderLineItems = [...this.orderLineItems];
            }
            return;
        }

        const product = selectedRecord;

        if (this.orderLineItems && this.orderLineItems[index]) {
            this.orderLineItems[index] = {
                ...this.orderLineItems[index],
                prodId: product.Id,
                prodName: product.Name,
                Product2Id: product.Id,
                quality: ''
            };

            this.fetchProductListPrice(product.Id, index);
            this.fetchProductQuality(product.Id, index);
        }

        console.log('Updated Field:', index, this.orderLineItems[index]);
    }

    fetchProductQuality(productId, index) {
        getQualityForProduct({
            accountId: this.orderFields.AccountId,
            productId: productId
        }).then(result => {
            console.log('Received quality:', result);
            if (result) {
                this.orderLineItems[index].quality = result;
                this.orderLineItems = [...this.orderLineItems];
                console.log('Quality updated in UI:', this.orderLineItems[index]);
            }
        }).catch(error => {
            console.error('Error fetching quality:', error);
        });
    }

    fetchProductListPrice(productId, index) {

        fetchListPrice({
            productId: productId,
            currencyCode: this.orderFields.CurrencyIsoCode
        })
        .then(result => {

            const listPrice = result ? result : 0;

            this.orderLineItems[index].ListPrice = listPrice;

            this.orderLineItems[index].isDisabled = (listPrice === 0);
            this.orderLineItems[index].isvaldisabled = (listPrice === 0);
            this.orderLineItems[index].isperdisabled = (listPrice === 0);

            this.setFreightEditability(index, listPrice);

            this.orderLineItems = [...this.orderLineItems];
        })
        .catch(error => {
            console.error("Error fetching List Price:", error);
        });
    }

    setFreightEditability(index, listPrice) {

        const item = this.orderLineItems[index];

        const validIncoTerms = ['CFR','CIF','CPT','CIP','DAP','DDP'];

        let freightEditable = false;

        if(listPrice > 0 &&
        this.orderFields.Inco_Terms__c &&
        validIncoTerms.includes(this.orderFields.Inco_Terms__c))
        {
            freightEditable = true;
        }

        this.orderLineItems[index].isFreightDisabled = !freightEditable;

        if(!freightEditable){
            this.orderLineItems[index].freightval = '';
        }

        this.orderLineItems = [...this.orderLineItems];
    }

    handleScoreChange(event) {
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;
        let value = event.detail.value;

        this.orderLineItems[index][label] = value;

        if (label === 'CommissionType') {
            console.log('Handling CommissionType Change');

            if (this.orderLineItems[index].CommissionType === 'Value') {
                this.orderLineItems[index].isvaldisabled = false;
                this.orderLineItems[index].isperdisabled = true;
                this.orderLineItems[index].commissionper = 0;
            } else if (this.orderLineItems[index].CommissionType === 'Percent') {
                this.orderLineItems[index].isvaldisabled = true;
                this.orderLineItems[index].isperdisabled = false;
                this.orderLineItems[index].commissionval = 0;
            }
        }

        if (label === 'UnitPrice') {
            console.log('Handling Price Change for index:', index);
            if (!value || value === '0') {
                this.orderLineItems[index].isDisabled = true;
                this.orderLineItems[index].isvaldisabled = true;
                this.orderLineItems[index].isperdisabled = true;
                this.orderLineItems[index].commissionval = 0;
                this.orderLineItems[index].commissionper = 0;
                this.orderLineItems[index].isFreightDisabled = true;
                this.orderLineItems[index].freightval = '';
                console.log('Price is empty or 0, disabling Freight');
            } else {
                this.orderLineItems[index].isDisabled = false;
                if (this.orderLineItems[index].CommissionType === 'Value') {
                    this.orderLineItems[index].isvaldisabled = false;
                }
                if (this.orderLineItems[index].CommissionType === 'Percent') {
                    this.orderLineItems[index].isperdisabled = false;
                }

                if (this.orderFields.Inco_Terms__c && ['CFR', 'CIF', 'CPT', 'CIP', 'DAP', 'DDP'].includes(this.orderFields.Inco_Terms__c)) {
                    this.orderLineItems[index].isFreightDisabled = false;
                    console.log('Freight enabled due to valid Incoterms:', this.orderFields.Inco_Terms__c);
                } else {
                    this.orderLineItems[index].isFreightDisabled = true;
                    console.log('Freight disabled due to invalid Incoterms:', this.orderFields.Inco_Terms__c);
                }
            }
        }

        this.orderLineItems[index]['totalprice'] = this.calculatePrice(JSON.stringify(this.orderLineItems[index]));
        console.log('Total Price:', this.orderLineItems[index]['totalprice']);

        this.orderLineItems[index]['finalprice'] = this.calculateFinalPrice(index);
        console.log('Final Price:', this.orderLineItems[index]['finalprice']);

        this.orderLineItems[index]['totalpricefinal'] = this.calculateFinalPrice1(index);
        console.log('Total Price Final:', this.orderLineItems[index]['totalpricefinal']);

        console.log('Updated Item for Index:', index, this.orderLineItems[index]);
        this.orderLineItems = [...this.orderLineItems];
    }

    calculatePrice(data) {
        let temp = JSON.parse(data);
        let totalPrice = Number(temp.UnitPrice);

        if (isNaN(totalPrice) || totalPrice <= 0) {
            console.error('Invalid price');
            return totalPrice;
        }

        if (temp.CommissionType === 'Value') {
            const commissionValue = Number(temp.commissionval);
            if (isNaN(commissionValue) || commissionValue < 0) {
                console.error('Invalid commission value');
            } else {
                totalPrice += commissionValue;
            }
        } else if (temp.CommissionType === 'Percent') {
            const commissionPercent = Number(temp.commissionper);
            if (isNaN(commissionPercent) || commissionPercent <= 0) {
                console.error('Invalid commission percentage');
            } else {
                let commissionAmount = (commissionPercent / 100) * totalPrice;
                totalPrice += commissionAmount;
            }
        }

        console.log('totalPrice ->', totalPrice);
        return totalPrice;
    }

    calculateFinalPrice(index) {
        const item = this.orderLineItems[index];
        const totalprice = parseFloat(item.totalprice) || 0;
        const freightval = parseFloat(item.freightval) || 0;
        let finalprice = totalprice + freightval;
        return finalprice.toFixed(2);
    }

    calculateFinalPrice1(index) {
        const item = this.orderLineItems[index];
        const finalprice = parseFloat(item.finalprice) || 0;
        const volume = parseFloat(item.Quantity) || 0;
        let totalpricefinal = finalprice * volume;
        return totalpricefinal.toFixed(2);
    }

    handleShowPricesClick(event) {
        const clickedIndex = event.currentTarget.dataset.index;
        console.log('Clicked index:', clickedIndex);

        if (this.orderFields.AccountId && this.orderLineItems[clickedIndex]) {
            this.isLoading = true;
            this.isOpenFileView = true;
            this.currentProductIndex = clickedIndex;
            const clickedProduct = this.orderLineItems[clickedIndex];
            this.fetchLastFivePrices(this.orderFields.AccountId, clickedProduct.prodId);
        }
    }

    fetchLastFivePrices(accountId, productId) {
        findRecentPrices({ accountId: accountId, productId: productId })
            .then(result => {
                this.isOpenFileView = true;
                this.lastFivePrices = result;
                console.log('Last 5 Prices for Product ID:', productId);
                console.log('Fetched Last 5 Prices:', this.lastFivePrices);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching prices for Product ID:', productId, error);
                this.isLoading = false;
            });
    }

    handleClose() {
        this.isOpenFileView = false;
    }

    validateData() {
        let validate = true;
        for (let item of this.orderLineItems) {
            if (!item.prodId || item.prodId === '') {
                this.showToast('Error', 'Please Select Product', 'error');
                validate = false;
                break;
            } else if (!item.Quantity || item.Quantity === '' || item.Quantity === '0') {
                this.showToast('Error', `Please Fill Quantity for Product ${item.prodName}`, 'error');
                validate = false;
                break;
            } else if (!item.UnitPrice || item.UnitPrice === '' || item.UnitPrice === '0') {
                this.showToast('Error', `Please Fill Sales Price for Product ${item.prodName}`, 'error');
                validate = false;
                break;
            }
        }
        return validate;
    }

    handleModeChange(event) {
        this.selectedMode = event.detail.value;

        // Reset form state whenever mode changes
        this.resetFormState();

        if (this.selectedMode === 'new') {
            this.showModeSelection = false;
            this.showQuoteSelection = false;
            this.showForm = true;
        } else if (this.selectedMode === 'existing') {
            this.showModeSelection = false;
            this.showQuoteSelection = true;
            this.showForm = false;
            this.loadOrders();
        }
    }

    connectedCallback() {
        // Initialize with empty form state
        this.resetFormState();
    }

    resetFormState() {
        this.orderFields = {
            AccountId: this.recordId, // Keep the account reference
            Country__c: this.accountData?.fields?.Country__c?.value || '',
            PoNumber: this.accountData?.fields?.Buyer_s_Ref_PO__c?.value || '',
            PoDate: this.accountData?.fields?.Buyer_s_PO_Date__c?.value || '',
            Order_Type__c: this.userDivision,
            Inco_Terms__c: this.accountData?.fields?.INCO_Terms__c?.value || '',
            Payment_Terms__c: this.accountData?.fields?.Payment_Terms__c?.value || '',
            CurrencyIsoCode: this.accountData?.fields?.CurrencyIsoCode?.value || '',
            Status: 'Draft',
            Order_Source__c: '',
            EffectiveDate: new Date().toISOString().split('T')[0]
        };

        this.orderLineItems = [{
            id: 'row_0',
            index: 0,
            prodId: '',
            Product2Id: '',
            ListPrice: '',
            Quantity: '',
            UnitPrice: '',
            Quality__c: '',
            Commission_Type__c: '',
            Commission_Value__c: '',
            Commission_Percentage__c: '',
            Total_Price__c: '',
            freightval: '',
            Discount__c: '',
            Final_Price__c: '',
            Total_Price_Final__c: '',
            isDisabled: false,
            isvaldisabled: false,
            isperdisabled: false,
            isFreightDisabled: false
        }];

        this.selectedOrderId = '';
        this.rowIdCounter = 1;
    }

    loadOrders() {
        this.isLoading = true;
        getOrders({ accountId: this.recordId })
            .then(result => {
                if (result) {
                    this.orderOptions = result.map(order => ({
                        // Ensure we're using the correct field names
                        label: order.Status ? `${order.Status} (${order.OrderNumber})` : `Order ${order.OrderNumber}`,
                        value: order.Id
                    }));
                    console.log('Order options:', this.orderOptions); // Debugging
                } else {
                    this.orderOptions = [];
                }
            })
            .catch(error => {
                console.error('Error loading orders:', error);
                this.orderOptions = [];
                this.showToast('Error', 'Failed to load orders', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleQuoteSelection(event) {
        this.selectedOrderId = event.detail.value;
        this.fetchOrderDetails();
    }

    fetchOrderDetails() {
        this.isLoading = true;
        getOrderDetails({ orderId: this.selectedOrderId })
            .then(result => {
                // First, update the order fields
                this.orderFields = {
                    ...this.orderFields,
                    ...result.order,
                    // Don't override currency - use what's in the order
                    CurrencyIsoCode: result.order.CurrencyIsoCode
                };

                // Update currency filter based on order's currency
                this.currencyfilter = `Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '${result.order.CurrencyIsoCode}')`;

                // Transform order items
                this.orderLineItems = result.orderItems.map((item, index) => ({
                    id: 'row_' + index,
                    index: index,
                    prodId: item.Product2Id,
                    Product2Id: item.Product2Id,
                    ListPrice: item.ListPrice,
                    Quantity: item.Quantity,
                    UnitPrice: item.UnitPrice,
                    Quality__c: item.Quality__c || '',
                    Commission_Type__c: item.Commission_Type__c || '',
                    Commission_Value__c: item.Commission_Value__c || '',
                    Commission_Percentage__c: item.Commission_Percentage__c || '',
                    Total_Price__c: item.Total_Price__c || '',
                    freightval: item.freightval || '',
                    Discount__c: item.Discount__c || '',
                    Final_Price__c: item.Final_Price__c || '',
                    Total_Price_Final__c: item.Total_Price_Final__c || '',
                    isDisabled: (item.ListPrice === 0),
                    isvaldisabled: (item.Commission_Type__c !== 'Value'),
                    isperdisabled: (item.Commission_Type__c !== 'Percent'),
                    isFreightDisabled: !['CFR', 'CIF', 'CPT', 'CIP', 'DAP', 'DDP'].includes(this.orderFields.Inco_Terms__c)
                }));

                this.showQuoteSelection = false;
                this.showForm = true;
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Failed to load order details', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleHeaderChange(event) {
        const field = event.target.dataset.id;
        const value = event.detail.value;

        this.orderFields = {
            ...this.orderFields,
            [field]: value
        };

        if (field === 'CurrencyIsoCode') {
            this.currencyfilter = `Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '${value}')`;

            this.orderLineItems = [{
                id: 'row_0',
                index: 0,
                prodId: ''
                // Other fields as needed
            }];
        }

        if (field === 'Inco_Terms__c') {
            this.orderLineItems.forEach((item, index) => {
                this.setFreightEditability(index, item.ListPrice);
            });
        }

        if (field === 'AccountId' && value) {
            this.loadCheckList(value);
        }
    }


    loadCheckList(accountId) {
    getCheckListsByAccount({ accountId })
        .then(data => {
            console.log('Checklist data:', data); // 👈 See what's returned
            if (data && data.length > 0) {
                const latestChecklistId = data[0].Id;
                this.selectedCheckListId = latestChecklistId;
                this.orderFields = {
                    ...this.orderFields,
                    Check_List__c: latestChecklistId
                };
            } else {
                console.log('No checklist found'); // 👈 Debug
                console.log('Order Type:', this.orderFields.Order_Type__c); // ✅ Add this
                this.selectedCheckListId = '';
                this.orderFields = {
                    ...this.orderFields,
                    Check_List__c: ''
                };

            }
        })
        .catch(error => {
            console.error('Error fetching checklist:', error);
            this.selectedCheckListId = '';
            this.orderFields = {
                ...this.orderFields,
                Check_List__c: ''
            };

            if (this.orderFields.Order_Type__c === 'International') {
                this.showToast('Error', 'Failed to load checklists', 'error');
            }
        });
}


    handleCheckListChange(event) {
    this.selectedCheckListId = event.detail.value;
    this.orderFields = {
        ...this.orderFields,
        Check_List__c: this.selectedCheckListId
    };
}


    handleCommissionTypeChange(event) {
        const index = event.target.dataset.index;
        const CommissionTypeValue = event.detail.value;
        this.addAnswer[index].CommissionType = CommissionTypeValue;
    }

    addQuoteLineItem(event) {
        const newItem = {
            id: 'row_' + this.rowIdCounter++,
            index: this.orderLineItems.length,
            prodId: '',
            Product2Id: '',
            ListPrice: '',
            Quantity: '',
            UnitPrice: '',
            quality: '',
            CommissionType: '',
            commissionval: '',
            commissionper: '',
            totalprice: '',
            freightval: '',
            discountval: '',
            finalprice: '',
            totalpricefinal: '',
            isDisabled: false,
            isvaldisabled: false,
            isperdisabled: false,
            isFreightDisabled: !['CFR', 'CIF', 'CPT', 'CIP', 'DAP', 'DDP'].includes(this.orderFields.Inco_Terms__c)
        };

        this.orderLineItems = [...this.orderLineItems, newItem];
    }

    removeQuoteLineItem(event) {
        const index = event.target.dataset.index;
        if (this.orderLineItems.length > 1) {
            this.orderLineItems.splice(index, 1);
            this.orderLineItems = [...this.orderLineItems];
        }
    }

    handleBack() {
        this.resetFormState();
        this.showForm = false;
        this.showQuoteSelection = false;
        this.showModeSelection = true;
        this.selectedMode = '';
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }

    handleSave() {
        // Always sync selectedCheckListId to orderFields before saving
        this.orderFields.Check_List__c = this.selectedCheckListId;

        if (!this.validateData()) {
            return;
        }

        this.isLoading = true;

        createOrUpdateOrder({
            accountId: this.recordId,
            orderFields: JSON.stringify(this.orderFields),
            orderLineItems: JSON.stringify(this.orderLineItems)
        })
        .then((result) => {
            this.showToast('Success', 'Order saved successfully', 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result,
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}