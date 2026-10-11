public with sharing class GardenTriggerFactory implements TriggerInterface {
    public void execute() {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                GardenTriggerHandler.setManagerStartDate(Trigger.new);
                GardenTriggerHandler.calculateCapacity(Trigger.new, null);
                GardenTriggerHandler.calculateHealthIndex(null, Trigger.new);
                GardenTriggerHandler.setGardenStatus(Trigger.new, null);
            } when BEFORE_UPDATE {
                GardenTriggerHandler.setManagerStartDate(Trigger.old, Trigger.new);
                GardenTriggerHandler.calculateCapacity(Trigger.new, Trigger.old);
                GardenTriggerHandler.calculateHealthIndex(Trigger.old, Trigger.new);
                GardenTriggerHandler.setGardenStatus(Trigger.new, (Map<Id, Garden__c>) Trigger.oldMap);
            } when AFTER_INSERT {
                GardenTriggerHandler.createManagerTaskOnInsert(Trigger.new);
            }  when AFTER_UPDATE {
                GardenTriggerHandler.transferManagerTaskOnCreateOrUpdateOrDelete(Trigger.old, Trigger.new);
            } when else {
                // No action for other trigger events.
            }
        }
    }
}