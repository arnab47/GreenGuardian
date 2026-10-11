trigger GardenTrigger on Garden__c (before insert, before update, after insert, after update) {
    TriggerInterface factory = new GardenTriggerFactory();
    factory.execute();
}