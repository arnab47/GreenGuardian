trigger GardenTrigger on Garden__c (before insert, before update, after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
        GardenTriggerHandler.createManagerTaskOnInsert(Trigger.New);
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        GardenTriggerHandler.transferManagerTaskOnCreateOrUpdateOrDelete(Trigger.Old, Trigger.New);
    }
    if(Trigger.isBefore && Trigger.isInsert) {
        GardenTriggerHandler.setManagerStartDate(Trigger.New);
    }
    if(Trigger.isBefore &&  Trigger.isUpdate) {
        GardenTriggerHandler.setManagerStartDate(Trigger.Old, Trigger.New);
    }
}