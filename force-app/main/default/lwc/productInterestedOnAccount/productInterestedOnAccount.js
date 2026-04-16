import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import saveProductInterested from '@salesforce/apex/addProductIntrestedAccount.saveProductInterested';
import deleteProductInterested from '@salesforce/apex/addProductIntrestedAccount.deleteProductInterested';
import getPicklistValues from '@salesforce/apex/addProductIntrestedAccount.getPicklistValues';
import getExistingProducts from '@salesforce/apex/addProductIntrestedAccount.getExistingProducts';
import getProdInterest from '@salesforce/apex/addProductIntrestedAccount.getProdInterest';
import getaccountCurrency from '@salesforce/apex/addProductIntrestedAccount.getaccountCurrency';
import fetchCI from '@salesforce/apex/MarketingForm.fetchCI';
import getUnits from '@salesforce/apex/addProductIntrestedAccount.getUnits';

export default class ProductInterestedOnAccount extends NavigationMixin(LightningElement) {

    @api recordId;
    @track packagingOptions = [];
    @track uomOptions = [];
    @track currencyfilter;

    @track currencyCode = '';
    options = [];
    unitOptions = [];

    @track where = '';
    @track Exist = [];


    @wire(getaccountCurrency, { accountId: '$recordId' })
    wiredCurrency({ error, data }) {
        if (data) {
            this.currencyfilter = "Id IN (SELECT Product2Id FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode = '" + data + "')";
        } else if (error) {
            console.error('Error fetching account currency', error);
        }
    }

    // Fetch existing products for the current lead
    getExisting() {
        console.log('recordid', this.recordId);
        getExistingProducts({ Id: this.recordId }).then(result => {
            console.log('search--<>>>---', JSON.stringify(result));
            if (result.length > 0) {
                this.Exist = result;
            } else {
                this.Exist = [];
            }
            this.where = `'Id NOT IN : '${this.Exist}'`;
        });
    }

    get textProductLabelStyle() {
        return this.addAnswer.some(answer => answer.New_Product__c)
            ? ''
            : 'display: none';
    }

    fetchCIForProduct(productId, index) {
        fetchCI({ productId: productId })
            .then((result) => {
                if (this.addAnswer[index]) {
                    this.addAnswer[index].ciNo = result;  // Update the CI field in the addAnswer array
                }
                console.log('CI number fetched for product:', result);
            })
            .catch((error) => {
                console.error('Error fetching CI_no__c:', error);
            });
    }

    // Handle lookup selection for product
    lookupRecord(event) {
        const selectedRecord = event.detail.selectedRecord;
        const index = event.target.dataset.index;
        console.log('event.detail.-->', index);

        if (!selectedRecord) {
            console.log("No record selected");
            return;
        }

        const selectedCampaign = event.detail;
        const pbe = selectedCampaign.selectedRecord;
        console.log('pbe', pbe);

        if (this.addAnswer && this.addAnswer[index]) {
            this.addAnswer[index] = {
                ...this.addAnswer[index],
                prodId: pbe.Id,
                prodName: pbe.Name,
                prodCode: pbe.ProductCode,
                ciNo: pbe.CI_no__c,  // Add CI_no__c here
                prodFamily: pbe.Family,
                New_Product__c: false // Ensure checkbox is unchecked when selecting existing product
            };  // This ensures the view updates
            console.log('Updated Field:', index, this.addAnswer[index]);
        } else {
            console.error('Invalid index or fields array');
        }
        this.fetchCIForProduct(selectedRecord.Id, index);
    }


    @track tempIndex = 0;
    @track addAnswer = [];


    handleUnitChange(event) {
        const index = event.target.dataset.index;
        const selectedUnitId = event.detail.value;
        this.addAnswer[index].Sample_Sent_to_Unit__c = selectedUnitId;
    }


    connectedCallback() {
        this.getProd();
        this.getExisting();
        console.log('recordId--->', this.recordId);

        getPicklistValues()
            .then(result => {
                this.packagingOptions = result.packaging;
                this.uomOptions = result.uom;

            })
            .catch(error => {
                console.error('Error loading picklists:', error);
            });


        getUnits()
            .then(result => {
                this.unitOptions = result.map(unit => ({
                    label: unit.Name,
                    value: unit.Id
                }));
            })
            .catch(error => {
                console.error('Error fetching units:', error);
            });

    }

    // Fetch products interested for the current lead
    getProd() {
        getProdInterest({ Id: this.recordId, existingProductIds: this.Exist }).then(result => {
            console.log('result--<>>>---', JSON.stringify(result));

            if (result.length > 0) {
                result.forEach((ele, index) => {
                    let temp = {
                        index: index,
                        Id: this.recordId,
                        inId: ele.Id,
                        lineName: ele.Name,
                        prodId: ele.Vipul_Product_Name__c,
                        prodCode: ele.Product_Code__c,
                        CIN: ele.Color_Index__c,
                        price: ele.Price__c,
                        volume: ele.Quantity__c,
                        quality: ele.Quality__c,
                        uom: ele.UOM__c,
                        //  Add_In_Opty: ele.Add_in_Opportunity__c,
                        //Add_In_Opty: ele.Add_in_Opportunity__c !== undefined ? ele.Add_in_Opportunity__c : true,
                        createSample: ele.Create_Sample_Out__c,
                        prodFamily: ele.Product_Family__c,
                        isEdit: true,
                        packaging: ele.Packaging__c,
                        prodName: ele.Vipul_Product_Name__r ? ele.Vipul_Product_Name__r.Name : 'No Product',
                        New_Product__c: ele.New_Product__c,
                        New_Product_Name__c: ele.New_Product_Name__c,
                        New_Product_Description__c: ele.New_Product_Description__c,
                        New_Product_CI_No__c: ele.New_Product_CI_No__c
                    };
                    this.addAnswer.push(temp);
                    this.tempIndex = this.addAnswer.length - 1;
                });
            } else {
                this.addAnswer = [];
                this.tempIndex = 0;
            }

            if (this.addAnswer.length == 0) {
                const newAnswer = {
                    index: 0,
                    Id: this.recordId,
                    inId: '',
                    lineName: '',
                    prodId: '',
                    prodCode: '',
                    price: 0,
                    volume: '',
                    quality: '',
                    uom: 'Kgs/Month',
                    //Add_In_Opty: true,
                    createSample: false,
                    prodFamily: '',
                    isEdit: false,
                    prodName: '',
                    packaging: '',
                    New_Product__c: false,
                    New_Product_Name__c: '',
                    New_Product_Description__c: '',
                    New_Product_CI_No__c: ''
                };
                this.addAnswer.push(newAnswer);
            }
        });
    }

    // Handle checkbox change for New Product
    handleCheckboxChange(event) {
        const index = event.target.dataset.index;
        const isChecked = event.target.checked;

        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product__c: isChecked,
            // Set Add_In_Opty to false when New_Product__c is true, otherwise default to true
            //Add_In_Opty: true,
            createSample: false,
            // Clear product fields when switching to new product
            prodId: isChecked ? '' : this.addAnswer[index].prodId,
            prodName: isChecked ? '' : this.addAnswer[index].prodName,
            prodCode: isChecked ? '' : this.addAnswer[index].prodCode,
            // Clear new product fields when switching to existing product
            New_Product_Name__c: isChecked ? this.addAnswer[index].New_Product_Name__c : '',
            New_Product_Description__c: isChecked ? this.addAnswer[index].New_Product_Description__c : '',
            New_Product_CI_No__c: isChecked ? this.addAnswer[index].New_Product_CI_No__c : ''
        };
        // Force UI update
        this.addAnswer = [...this.addAnswer];
    }

    // Handle text input change for New Product Name
    handleTextInputChange(event) {
        const index = event.target.dataset.index;
        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product_Name__c: event.target.value
        };
    }

    handleCIInputChange(event) {
        const index = event.target.dataset.index;
        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product_CI_No__c: event.target.value
        };
    }

    handleDescriptionChange(event) {
        const index = event.target.dataset.index;
        this.addAnswer[index] = {
            ...this.addAnswer[index],
            New_Product_Description__c: event.target.value
        };
    }



    // Add a new product entry
    addAnswerItem() {
        let validate = this.validateData();
        console.log('validate--> Item', validate);

        if (validate) {
            this.tempIndex = this.tempIndex + 1;
            const newAnswer = {
                index: this.tempIndex,
                Id: this.recordId,
                inId: '',
                lineName: '',
                prodId: '',
                prodCode: '',
                price: '',
                volume: '',
                quality: '',
                uom: 'Kgs/Month',
                //Add_In_Opty: true,
                createSample: false,
                prodFamily: '',
                isEdit: false,
                prodName: '',
                CIN: '',
                New_Product__c: false,
                New_Product_Name__c: '',
                New_Product_Description__c: '',
                New_Product_CI_No__c: ''
            };
            this.addAnswer.push(newAnswer);
            console.log('addAnswer after adding item:', this.addAnswer);
        } else {
            console.log('Validation failed');
        }
    }

    handlePackagingChange(event) {
        let index = event.target.dataset.index;
        this.addAnswer[index].packaging = event.target.value; // ✅ Only update packaging
    }

    handleUOMChange(event) {
        let index = event.target.dataset.index;
        this.addAnswer[index].uom = event.target.value; // ✅ Only update UOM
    }


    // Remove a product entry
    removeAnswer(event) {
        let indexToRemove = event.target.dataset.index;
        let isEditOrNot = event.target.dataset.edit;
        let id = event.target.dataset.inid;
        console.log('OUTPUT : ', isEditOrNot, indexToRemove);

        if (isEditOrNot == "true") {
            deleteProductInterested({ Id: id }).then(result => {
                this.showSuccess('Success', result, 'Success');
                this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
                this.arrangeIndex();
                this.tempIndex = this.addAnswer.length - 1;
            });
        } else if (this.addAnswer.length > 1) {
            this.addAnswer = this.addAnswer.filter(answer => answer.index != parseInt(indexToRemove, 10));
            this.arrangeIndex();
            this.tempIndex = this.addAnswer.length - 1;
        }
    }

    // Adjust the index of each item in the array
    arrangeIndex() {
        this.addAnswer = this.addAnswer.map((answer, newIndex) => {
            return { ...answer, index: newIndex };
        });
    }

    // Show a toast notification
    showSuccess(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Handle changes to input fields
    handleScoreChange(event) {
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;
        this.addAnswer[index][label] = event.target.value;

        if (label == 'prodFamily') {
            this.addAnswer[index] = { ...this.addAnswer[index], prodId: '', prodName: '', prodCode: '', ciNo: '' };
        }
        //  this.fetchCIForProduct(selectedRecord.Id, index);
    }

    // Handle changes to checkboxes
    handleSelectChange(event) {
        let label = event.target.dataset.label;
        let index = event.target.dataset.index;
        this.addAnswer[index][label] = event.target.checked;
    }

    // Validate the data before saving
    validateData() {
        let validate = true;
        for (let element of this.addAnswer) {

            if (element.New_Product__c) {
                // Validate new product fields
                if (!element.New_Product_Name__c || element.New_Product_Name__c.trim() === '') {
                    this.showSuccess('Error', 'Please enter Product Name for new product', 'Error');
                    validate = false;
                    break;
                } 
                // else if (element.volume == '' || element.volume == undefined || element.volume == 0) {
                //     this.showSuccess('Error', `Please Fill Quantity in kgs for Product ${element.New_Product_Name__c}`, 'Error');
                //     validate = false;
                //     break;
                // } 
                else if (!element.New_Product__c &&
                    (element.price === '' ||
                        element.price === undefined ||
                        element.price === null ||
                        isNaN(element.price) ||
                        Number(element.price) <= 0)) {
                    this.showToast('Error', 'Price is required for standard products', 'error');
                    validate = false;
                    break;
                }
            } else {

                if (element.prodName === '' || element.prodName === undefined || element.prodName === 0) {
                    this.showSuccess('Error', `Please Select Product`, 'Error');
                    validate = false;
                    break;
                }
            }
        }
        return validate;
    }

    // Save the products interested
    save() {
        let validate = this.validateData();
        if (validate) {
            saveProductInterested({ Id: this.recordId, JS: JSON.stringify(this.addAnswer) }).then(result => {
                if (result.message == 'success') {
                    this.showSuccess('success', 'Record Created Successfully !!!', 'Success');
                    this.handleCancel();

                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    this.showSuccess('Error', result.message, 'error');
                }
            });
        }
    }

    // Cancel the action and navigate back to the record page
    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

}