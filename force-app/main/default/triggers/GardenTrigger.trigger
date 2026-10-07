trigger GardenTrigger on Garden__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            GardenTriggerHandler.setManagerStartDate(Trigger.New);
            GardenTriggerHandler.calculateCapacity(Trigger.New, null);
        }
        if (Trigger.isUpdate) {
            GardenTriggerHandler.setManagerStartDate(Trigger.Old, Trigger.New);
            GardenTriggerHandler.calculateCapacity(Trigger.New, Trigger.Old);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            GardenTriggerHandler.createManagerTaskOnInsert(Trigger.New);
        }
        if (Trigger.isUpdate) {
            GardenTriggerHandler.transferManagerTaskOnCreateOrUpdateOrDelete(Trigger.Old, Trigger.New);
        }
    }
}
