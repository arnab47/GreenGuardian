trigger PlantTrigger on Plant__c (before insert, after insert, after update, after delete, after undelete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            PlantTriggerHandler.assignDefaultValues(Trigger.New);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PlantTriggerHandler.handleRollup(Trigger.New, null);
            PlantTriggerHandler.countUnhealthyPlantsForGarden(Trigger.New, null);
        }
        if (Trigger.isUpdate) {
            PlantTriggerHandler.handleRollup(Trigger.New, Trigger.OldMap);
            PlantTriggerHandler.countUnhealthyPlantsForGarden(Trigger.New, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            PlantTriggerHandler.handleRollup(Trigger.Old, null);
            PlantTriggerHandler.countUnhealthyPlantsForGarden(null, Trigger.oldMap);
        }
        if (Trigger.isUndelete) {
            PlantTriggerHandler.handleRollup(Trigger.New, null);
            PlantTriggerHandler.countUnhealthyPlantsForGarden(Trigger.New, null);
        }
    }
}
