({
    // Initialization method
    init: function (component, event, helper) {
        var pageReference = component.get("v.pageReference");

        // If pageReference is available, get the recordId and sObjectName from URL
        if (pageReference) {
            var recordId = pageReference.state.c__recordId;
            var sObjectName = pageReference.state.c__sObjectName;

            // Set the values of refRecordId and sObjectName
            component.set("v.refRecordId", recordId);
            component.set("v.sObjectName", sObjectName);
        }

        // If recordId isn't found via URL, fallback to recordId provided by force:hasRecordId
        if (!component.get("v.refRecordId")) {
            component.set("v.refRecordId", component.get("v.recordId"));
        }

        console.log('Initialized with RecordId: ' + component.get("v.refRecordId"));
    },

    // Reinitialize the component when pageReference changes
    reInit: function (component, event, helper) {
        console.log('Page reference changed, reinitializing...');
        $A.get('e.force:refreshView').fire(); // Force refresh view event
    }
})



// ({
 
//     init : function(component, event, helper) {
 
//         var pageReference = component.get("v.pageReference");var a = component.get("v.recordId");
 
//         component.set("v.refRecordId", pageReference.state.c__recordId);
 
//         component.set("v.sObjectName", pageReference.state.c__sObjectName);
        
 
//     },
 
//     reInit : function(component, event, helper) {
 
//         console.log('This is fire');
 
//         $A.get('e.force:refreshView').fire();
 
//     }
 
// })