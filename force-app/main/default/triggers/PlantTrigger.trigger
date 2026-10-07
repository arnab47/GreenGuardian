trigger PlantTrigger on Plant__c (before insert, after insert, after update, after delete, after undelete) {
    if(Trigger.isBefore && Trigger.isInsert) {
        PlantTriggerHandler.assignDefaultValues(Trigger.New);
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            PlantTriggerHandler.handleRollup(Trigger.new, null);
        }
        if(Trigger.isUpdate) {
            PlantTriggerHandler.handleRollup(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isDelete) {
            PlantTriggerHandler.handleRollup(Trigger.old, null);
        }
        if(Trigger.isUndelete) {
            PlantTriggerHandler.handleRollup(Trigger.new, null);
        }
    }
}
