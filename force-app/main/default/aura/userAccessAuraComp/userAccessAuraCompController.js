({
    myAction : function(component, event, helper) {
        console.log("Inside Aura myAction method."); // Diagnostic log
        
        const lwcComponent = component.find('userAccessManagement');
  if (lwcComponent) {
            console.log("Found LWC component. Attempting to call LWCFunction."); // Diagnostic log
            lwcComponent.LWCFunction();
        } else {
            console.log("Did not find LWC component."); // Diagnostic log
        }
    
        //const recordId = component.get('v.recordId');
     //   console.log("Aura recordId:", recordId);   
    }
})