trigger PlantTrigger on Plant__c (before insert, after insert, after update, after delete, after undelete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            PlantTriggerHandler.assignDefaultValues(Trigger.New);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PlantTriggerHandler.handleRollup(Trigger.New, null);
        }
        if (Trigger.isUpdate) {
            PlantTriggerHandler.handleRollup(Trigger.New, Trigger.OldMap);
        }
        if (Trigger.isDelete) {
            PlantTriggerHandler.handleRollup(Trigger.Old, null);
        }
        if (Trigger.isUndelete) {
            PlantTriggerHandler.handleRollup(Trigger.New, null);
        }
    }
}
