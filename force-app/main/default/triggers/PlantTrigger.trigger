trigger PlantTrigger on Plant__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        PlantTriggerHandler.assignDefaultValues(Trigger.New);
    }
}