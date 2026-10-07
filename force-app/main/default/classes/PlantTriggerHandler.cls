public with sharing class PlantTriggerHandler {
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

    public static void handleRollup(List<Plant__c> plantList, Map<Id, Plant__c> oldPlantMap) {
        Set<Id> gardenIdsToUpdate = new Set<Id>();
        
        for(Plant__c plant : plantList) {
            if(plant.Garden__c != null) {
                gardenIdsToUpdate.add(plant.Garden__c);
            }
            
            if(oldPlantMap != null) {
                Plant__c oldPlant = oldPlantMap.get(plant.Id);
                if(oldPlant.Garden__c != plant.Garden__c && oldPlant.Garden__c != null) {
                    gardenIdsToUpdate.add(oldPlant.Garden__c);
                }
            }
        }
        
        if(gardenIdsToUpdate.isEmpty()) {
            return;
        }
        
        Map<Id, Garden__c> gardensToUpdateMap = new Map<Id, Garden__c>();
        for(Id gardenId : gardenIdsToUpdate) {
            gardensToUpdateMap.put(gardenId, new Garden__c(Id = gardenId, Total_Plant_Count__c = 0));
        }
        
        List<AggregateResult> groupedResults = [
            SELECT Garden__c, COUNT(Id) plantCount 
            FROM Plant__c 
            WHERE Garden__c IN :gardenIdsToUpdate 
            GROUP BY Garden__c
        ];
        
        for(AggregateResult ar : groupedResults) {
            Id gardenId = (Id) ar.get('Garden__c');
            Integer count = (Integer) ar.get('plantCount');
            
            if(gardensToUpdateMap.containsKey(gardenId)) {
                gardensToUpdateMap.get(gardenId).Total_Plant_Count__c = count;
            }
        }
        
        if(!gardensToUpdateMap.isEmpty()) {
            update gardensToUpdateMap.values();
        }
    }
}