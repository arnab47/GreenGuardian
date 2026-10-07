trigger GardenTrigger on Plant__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        GardenTriggerHandler.assignDefaultValues(Trigger.New);
    }
}