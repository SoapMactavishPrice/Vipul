import { LightningElement, api, track } from 'lwc';
import getUnitsForSampleWarehouse
    from '@salesforce/apex/SampleOutRequest.getUnitsForSampleWarehouse';

export default class UnitLookup extends LightningElement {
    @api placeholder = 'Search Unit...';

    @track searchKey = '';
    @track results = [];
    @track selectedUnit;
    @track showDropdown = false;

    // SAME AS PRODUCT LOOKUP
    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.showDropdown ? 'slds-is-open' : ''
            }`;
    }

    handleFocus() {
        this.showDropdown = true;
        this.loadUnits('');
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.loadUnits(this.searchKey);
    }

    loadUnits(searchKey) {
        getUnitsForSampleWarehouse({ searchKey })
            .then(data => {
                this.results = data;
                this.showDropdown = true;
            })
            .catch(err => {
                console.error(err);
            });
    }

    handleSelect(event) {
        const unitId = event.currentTarget.dataset.id;
        const unitName = event.currentTarget.dataset.name;

        this.selectedUnit = { Id: unitId, Name: unitName };
        this.showDropdown = false;

        this.dispatchEvent(
            new CustomEvent('unitselect', {
                detail: { unitId, unitName },
                bubbles: true
            })
        );
    }

    handleRemove() {
        this.selectedUnit = null;
        this.searchKey = '';
        this.results = [];
        this.showDropdown = false;

        this.dispatchEvent(
            new CustomEvent('unitclear', { bubbles: true })
        );
    }
}