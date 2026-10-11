public with sharing class PlantTriggerFactory implements TriggerInterface{
    public void execute () {
        switch on Trigger.operationType {
            when  BEFORE_INSERT {
                PlantTriggerHandler.assignDefaultValues(Trigger.New);
            } when  AFTER_INSERT {
                PlantTriggerHandler.handleRollup(Trigger.New, null);
                PlantTriggerHandler.countUnhealthyPlantsForGarden(Trigger.New, null);
            } when  AFTER_UPDATE {
                PlantTriggerHandler.handleRollup(Trigger.New, (Map<Id, Plant__c>) Trigger.OldMap);
                PlantTriggerHandler.countUnhealthyPlantsForGarden(Trigger.New, (Map<Id, Plant__c>) Trigger.oldMap);
            } when  AFTER_DELETE {
                PlantTriggerHandler.handleRollup(Trigger.Old, null);
                PlantTriggerHandler.countUnhealthyPlantsForGarden(null, (Map<Id, Plant__c>) Trigger.oldMap);
            } when  AFTER_UNDELETE {
                PlantTriggerHandler.handleRollup(Trigger.New, null);
                PlantTriggerHandler.countUnhealthyPlantsForGarden(Trigger.New, null);
            } when else {
                // No action for other trigger events.
            }
        }
    }
}