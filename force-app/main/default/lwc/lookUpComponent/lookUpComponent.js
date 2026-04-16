import { LightningElement, track, api } from "lwc";
import findRecords from "@salesforce/apex/lookupComponentController.findRecords";
import fetchDefaultRecord from "@salesforce/apex/lookupComponentController.fetchDefaultRecord";

    // Debounce function - will pass the latest value
    function debounce(func, delay = 300) {
        let timeout;
        return function (...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), delay);
        };
    }

export default class LookUpComponent extends LightningElement {
    @track recordsList;
    @track searchKey = "";
    @track message;
    @track displayFieldsList = [];

    @api selectedValue;
    @api selectedData = {};
    @api selectedRecordId;
    @api objectApiName;
    @api fieldName;
    @api returnFields;
    @api displayFields;
    @api queryFields = null;
    @api filter = '';
    @api sortColumn = '';
    @api maxResults = '';
    @api iconName;
    @api industryId;
    @api deptId;
    @api showIcon = false;
    @api lookupLabel;
    @api recdataid;
    @api defaultRecordId = '';
    @api disabled = false;
    @api searchWithMiddle = false;
    @api index;
    @api family = '';

    searchCounter = 0;
    debouncedSearch;

    

    connectedCallback() {
        // Bind debounce to include searchKey param
        this.debouncedSearch = debounce((value) => {
            this.getLookupResult(value);
        }, 300);

        if (this.displayFields) {
            this.displayFieldsList = this.displayFields.split(',');
        }

        if (this.defaultRecordId) {
            fetchDefaultRecord({
                recordId: this.defaultRecordId,
                sObjectApiName: this.objectApiName,
                returnFields: this.returnFields
            }).then(result => {
                if (result) {
                    this.selectedRecordId = result.Id;
                    this.selectedValue = result.Name;
                    this.selectedData = { ...result };
                    this.searchKey = "";
                    this.onSeletedRecordUpdate();
                }
            }).catch(error => {
                this.error = error;
            });
        } else {
            this.removeRecordOnLookup();
        }
    }

    handleKeyChange(event) {
        this.searchKey = event.target.value;
        this.debouncedSearch(this.searchKey); // pass value directly
    }

    handleIconClick() {
        this.searchKey = '';
        console.log('handleIconClick' + this.searchKey);
        this.debouncedSearch();
        console.log('de' +  this.debouncedSearch());
    }

    onLeave() {
        // Clear the list after a short delay to allow selection clicks
        setTimeout(() => {
            this.searchKey = "";
            console.log('searchKey' +this.searchKey);
            console.log('on search');
            this.recordsList = null;
        }, 300);
    }

    onRecordSelection(event) {
        this.selectedRecordId = event.target.dataset.key;
        this.selectedValue = event.target.dataset.name;
        console.log('Inside onRecordSelection');
        this.selectedData = this.recordsList.find(item => item.Id === this.selectedRecordId);
        this.searchKey = "";
        this.onSeletedRecordUpdate();
    }

    getLookupResult(latestSearchKey) {
        const currentSearch = ++this.searchCounter;

        findRecords({
            indusId: this.industryId,
            deptId: this.deptId,
            searchKey: latestSearchKey,
            objectName: this.objectApiName,
            recdataid: this.recdataid,
            returnFields: this.returnFields,
            queryFields: this.queryFields,
            displayFields: this.displayFields,
            filter: this.filter,
            sortColumn: this.sortColumn,
            maxResults: this.maxResults,
            searchWithMiddle: this.searchWithMiddle === 'true',
            family: this.family
        })
        .then(result => {
            if (currentSearch !== this.searchCounter) return;

            if (result.length === 0) {
                this.recordsList = [];
                this.message = "No Records Found";
            } else {
                const fields = this.displayFields ? this.displayFields.split(',').map(f => f.trim()) : [];
                this.recordsList = result.map(rec => ({
                    ...rec,
                    c__col1: rec[fields[0]],
                    c__col2: rec[fields[1]],
                    c__col3: rec[fields[2]],
                    c__col4: rec[fields[3]],
                    c__col5: rec[fields[4]],
                }));
                this.message = "";
            }
            this.error = undefined;
        })
        .catch(error => {
            if (currentSearch !== this.searchCounter) return;
            this.error = error;
            this.recordsList = undefined;
        });
    }

    onSeletedRecordUpdate() {
        const event = new CustomEvent("recordselection", {
            detail: {
                selectedRecordId: this.selectedRecordId,
                selectedValue: this.selectedValue,
                selectedRecord: this.selectedData,
                index: this.index
            }
        });
        this.dispatchEvent(event);
    }

    @api
    removeRecordOnLookup() {
        this.searchKey = "";
        this.selectedValue = null;
        this.selectedRecordId = null;
        this.selectedData = null;
        this.recordsList = null;
        this.onSeletedRecordUpdate();
    }
}