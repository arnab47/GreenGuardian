public with sharing class GardenTriggerHandler {
    public static void createManagerTaskOnInsert(List<Garden__c> gardenList) {
        List<Task> taskListToInsert = new List<Task>();
        for(Garden__c garden : gardenList) {
            if(garden.Manager__c != null) {
                Task taskToInsert = new Task();
                taskToInsert.WhatId = garden.Id;
                taskToInsert.OwnerId = garden.Manager__c;
                taskToInsert.Subject = 'Acquire Plants';
                taskListToInsert.add(taskToInsert);
            }
        }
        if(!taskListToInsert.isEmpty()) {
            insert taskListToInsert;
        }
    }

    public static void transferManagerTaskOnCreateOrUpdateOrDelete(List<Garden__c> gardenOldValues, List<Garden__c> gardenNewValues) {
        List<Task> taskListToCreate = new List<Task>();
        List<Task> taskListToUpdate = new List<Task>();

        List<Id> changedGardenIds = new List<Id>();
        List<Id> departingManagerIds = new List<Id>();

        List<Id> deletedGardenIds = new List<Id>();
        Set<String> gardenManagerPairsToDelete = new Set<String>();

        for(Integer i = 0; i < gardenNewValues.size(); i++) {
            Garden__c oldGarden = gardenOldValues.get(i);
            Garden__c newGarden = gardenNewValues.get(i);

            if(oldGarden.Manager__c == null && newGarden.Manager__c != null) {
                Task taskToInsert = new Task();
                taskToInsert.WhatId = newGarden.Id;
                taskToInsert.OwnerId = newGarden.Manager__c;
                taskToInsert.Subject = 'Acquire Plants';
                taskListToCreate.add(taskToInsert);
            }

            if(oldGarden.Manager__c != null && newGarden.Manager__c != null && oldGarden.Manager__c != newGarden.Manager__c) {
                changedGardenIds.add(newGarden.Id);
                departingManagerIds.add(oldGarden.Manager__c);
            }

            if(oldGarden.Manager__c != null && newGarden.Manager__c == null) {
                deletedGardenIds.add(newGarden.Id);
                gardenManagerPairsToDelete.add(newGarden.Id + '-' + oldGarden.Manager__c);
            }
        }
        if(!changedGardenIds.isEmpty()) {
            List<Task> tasksToReassign = [SELECT Id, WhatId, OwnerId, Subject FROM Task WHERE WhatId IN :changedGardenIds AND OwnerId IN :departingManagerIds AND Subject = 'Acquire Plants' AND Status != 'Completed'];
            for(Task taskItem: tasksToReassign) {
                for(Integer i = 0; i < gardenNewValues.size(); i++) {
                    Garden__c currentGarden = gardenNewValues.get(i);
                    if(taskItem.WhatId == currentGarden.Id) {
                        taskItem.OwnerId = currentGarden.Manager__c;
                        taskListToUpdate.add(taskItem);
                        break;
                    }
                }
            }
        }

        if(!deletedGardenIds.isEmpty()) {
            List<Task> openTasksToCheck = [SELECT Id, WhatId, OwnerId FROM Task WHERE WhatId IN :deletedGardenIds AND Subject = 'Acquire Plants' AND Status != 'Completed'];
            List<Task> tasksToDelete = new List<Task>();
            for(Task taskItem : openTasksToCheck) {
                String trackingKey = taskItem.WhatId + '-' + taskItem.OwnerId;
                if(gardenManagerPairsToDelete.contains(trackingKey)) {
                    tasksToDelete.add(taskItem);
                }
            }
            if(!tasksToDelete.isEmpty()) {
                delete tasksToDelete;
            }
        }

        if(!taskListToCreate.isEmpty()) {
            insert taskListToCreate;
        }
        
        if(!taskListToUpdate.isEmpty()) {
            update taskListToUpdate;
        }
    }

    public static void setManagerStartDate(List<Garden__c> newGardenList) {
        for(Garden__c garden: newGardenList) {
            if(garden.Manager__c != null) {
                garden.Manager_Start_Date__c = Date.today();
            }
        }
    }

    public static void setManagerStartDate(List<Garden__c> oldGardenList, List<Garden__c> newGardenList) {
        for(Integer i = 0; i < newGardenList.size(); i++) {
            if(oldGardenList.get(i).Manager__c != null && newGardenList.get(i).Manager__c == null) {
                newGardenList.get(i).Manager_Start_Date__c = null;
            }
            if(oldGardenList.get(i).Manager__c == null && newGardenList.get(i).Manager__c != null) {
                newGardenList.get(i).Manager_Start_Date__c = Date.today();
            }
        }
    }
}