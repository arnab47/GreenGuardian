trigger GardenTrigger on Garden__c (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
        GardenTriggerHandler.createManagerTaskOnInsert(Trigger.New);
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        GardenTriggerHandler.transferManagerTaskOnCreateOrUpdateOrDelete(Trigger.Old, Trigger.New);
    }
}