trigger PlantTrigger on Plant__c (before insert, after insert, after update, after delete, after undelete) {
    TriggerInterface factory = new PlantTriggerFactory();
    factory.execute();
}