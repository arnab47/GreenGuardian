public with sharing class GardenTriggerHandler {
    public static void assignDefaultValues(List<Plant__c> plantList) {
        Set<Id> gardenIds = new Set<Id>();
        for(Plant__c plant: plantList) {
            if(plant.Garden__c != null) {
                gardenIds.add(plant.Garden__c);
            }
        }

        Map<Id, Garden__c> parentGardensMap = new Map<Id, Garden__c>();
        if(!gardenIds.isEmpty()) {
            parentGardensMap = new Map<Id, Garden__c>([
                SELECT Id, Sun_Exposure__c FROM Garden__C WHERE Id in: gardenIds
            ]);
        }

        for(Plant__c plant: plantList) {
            if(String.isBlank(plant.Soil_Type__c)) {
                plant.Soil_Type__c = 'All Purpose Potting Soil';
            }
            if(String.isBlank(plant.Water__c)) {
                plant.Water__c = 'Once Weekly';
            }
            if(String.isBlank(plant.Sunlight__c)) {
                if(plant.Garden__c != null && parentGardensMap.containsKey(plant.Garden__c)) {
                    Garden__C parentGarden = parentGardensMap.get(plant.Garden__c);
                    if(String.isNotBlank(parentGarden.Sun_Exposure__c)) {
                        plant.Sunlight__c = parentGarden.Sun_Exposure__c;
                    } else {
                        plant.Sunlight__c = 'Partial Sun';
                    }
                } else {
                    plant.Sunlight__c = 'Partial Sun';
                }
            }
        }
    }
}