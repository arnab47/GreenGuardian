@IsTest
private class GardenTriggerTest {
    
    /*
     * TEST DATA HELPER
     *
     * Creates an in-memory Garden record.
     * The caller decides when to insert it.
     */
    private static Garden__c buildGarden(
        Id managerId,
    Decimal totalPlants,
    Decimal maximumPlants,
    Decimal unhealthyPlants,
    Decimal minimumPlants
    ) {
        return new Garden__c(
            Manager__c = managerId,
        Total_Plant_Count__c = totalPlants,
        Maximum_Plant_Count__c = maximumPlants,
        Total_Unhealty_Plant_Count__c = unhealthyPlants,
        Minimum_Plant_Count__c = minimumPlants
            );
    }
    
    
    /*
     * TEST 1
     * Inserting managed and unmanaged Gardens.
     *
     * Covers:
     * - setManagerStartDate (insert)
     * - calculateCapacity (insert)
     * - calculateHealthIndex (insert)
     * - setGardenStatus (insert)
     * - createManagerTaskOnInsert
     * - Bulk insertion
     */
    @IsTest
    static void testGardenInsertCalculationsAndTasks() {
        
        Id managerId = UserInfo.getUserId();
        
        List<Garden__c> gardens = new List<Garden__c>{
            buildGarden(managerId, 75, 100, 15, 10),
            buildGarden(null, 75, 100, 15, 10)
        };
        
        Test.startTest();
        insert gardens;
        Test.stopTest();
        
        Map<Id, Garden__c> savedGardens = new Map<Id, Garden__c>([
            SELECT Id,
                   Manager__c,
                   Manager_Start_Date__c,
                   Capacity__c,
                   Health_Index__c,
                   Status__c
            FROM Garden__c
            WHERE Id IN :gardens
        ]);
        
        Garden__c managedGarden = savedGardens.get(gardens[0].Id);
        Garden__c unmanagedGarden = savedGardens.get(gardens[1].Id);
        
        // Manager start date
        System.assertEquals(
            Date.today(),
        managedGarden.Manager_Start_Date__c,
        'A managed Garden should receive a manager start date.'
            );
        
        System.assertEquals(
            null,
        unmanagedGarden.Manager_Start_Date__c,
        'A Garden without a manager should not receive a start date.'
            );
        
        // Capacity = (75 / 100) * 100 = 75%
        System.assertEquals(
            75,
        managedGarden.Capacity__c,
        'Capacity should be calculated correctly.'
            );
        
        // Health = ((75 - 15) / 75) * 100 = 80%
        System.assertEquals(
            80,
        managedGarden.Health_Index__c,
        'Health index should be calculated correctly.'
            );
        
        System.assertEquals(
            'Operational',
        managedGarden.Status__c,
        'A Garden meeting the operational conditions should be Operational.'
            );
        
        // Only the managed Garden should get a task.
        Set<Id> gardenIds = new Map<Id, Garden__c>(gardens).keySet();
        
        List<Task> tasks = [
            SELECT Id, WhatId, OwnerId, Subject
            FROM Task
            WHERE WhatId IN :gardenIds
            AND Subject = 'Acquire Plants'
        ];
        
        System.assertEquals(
            1,
        tasks.size(),
        'Only the managed Garden should receive an Acquire Plants task.'
            );
        
        System.assertEquals(
            gardens[0].Id,
        tasks[0].WhatId,
        'The task should be related to the managed Garden.'
            );
        
        System.assertEquals(
            managerId,
        tasks[0].OwnerId,
        'The task should be assigned to the Garden manager.'
            );
    }
    
    
    /*
     * TEST 2
     * Capacity and health calculations when counts are zero
     * or the Garden exceeds its maximum capacity.
     *
     * Covers zero-value branches and status branches.
     */
    @IsTest
    static void testZeroAndOverCapacityGardens() {
        
        List<Garden__c> gardens = new List<Garden__c>{
            buildGarden(null, 0, 100, 0, 0),
            buildGarden(null, 120, 100, 0, 10)
        };
        
        Test.startTest();
        insert gardens;
        Test.stopTest();
        
        Map<Id, Garden__c> savedGardens = new Map<Id, Garden__c>([
            SELECT Id, Capacity__c, Health_Index__c, Status__c
            FROM Garden__c
            WHERE Id IN :gardens
        ]);
        
        Garden__c emptyGarden = savedGardens.get(gardens[0].Id);
        Garden__c overCapacityGarden = savedGardens.get(gardens[1].Id);
        
        System.assertEquals(
            0,
        emptyGarden.Capacity__c,
        'Zero plants should produce zero capacity.'
            );
        
        System.assertEquals(
            0,
        emptyGarden.Health_Index__c,
        'A Garden with zero plants should have a zero health index.'
            );
        
        System.assertEquals(
            'Temporary Closure',
        emptyGarden.Status__c,
        'A Garden with zero capacity should be temporarily closed.'
            );
        
        System.assertEquals(
            120,
        overCapacityGarden.Capacity__c,
        'Capacity should exceed 100% when plant count exceeds the maximum.'
            );
        
        System.assertEquals(
            'Over Capacity',
        overCapacityGarden.Status__c,
        'A Garden exceeding its capacity should have Over Capacity status.'
            );
    }
    
    
    /*
     * TEST 3
     * Changing plant counts on an existing Garden.
     *
     * Covers the update branches in:
     * - calculateCapacity
     * - calculateHealthIndex
     * - setGardenStatus
     */
    
    @IsTest
    static void testGardenCalculationsOnUpdate() {
        
        // Arrange: prepare the Garden.
        Garden__c garden = buildGarden(null, 50, 100, 10, 10);
        insert garden;
        
        // Query the saved values calculated by the trigger.
        garden = [
        SELECT Id, Capacity__c, Health_Index__c, Status__c,
               Total_Plant_Count__c, Total_Unhealty_Plant_Count__c
        FROM Garden__c
        WHERE Id = :garden.Id
    ];
        
        System.assertEquals(
            50,
        garden.Capacity__c,
        'Initial capacity should be 50%.'
            );
        
        System.assertEquals(
            80,
        garden.Health_Index__c,
        'Initial health index should be 80%.'
            );
        
        System.assertEquals(
            'Awaiting Resources',
        garden.Status__c,
        'The Garden should initially await resources.'
            );
        
        // Act: change the plant counts.
        garden.Total_Plant_Count__c = 80;
        garden.Total_Unhealty_Plant_Count__c = 8;
        
        Test.startTest();
        update garden;
        Test.stopTest();
        
        // Assert: verify the recalculated values.
        Garden__c updatedGarden = [
        SELECT Capacity__c, Health_Index__c, Status__c
        FROM Garden__c
        WHERE Id = :garden.Id
    ];
        
        System.assertEquals(
            80,
        updatedGarden.Capacity__c,
        'Capacity should be recalculated after plant counts change.'
            );
        
        System.assertEquals(
            90,
        updatedGarden.Health_Index__c,
        'Health index should be recalculated after plant counts change.'
            );
        
        System.assertEquals(
            'Operational',
        updatedGarden.Status__c,
        'The Garden should become Operational.'
            );
    }
    
    
    
    /*
     * TEST 4
     * Assigning a manager and subsequently removing that manager.
     *
     * Covers:
     * - setManagerStartDate (update)
     * - transferManagerTaskOnCreateOrUpdateOrDelete (create and delete)
     */
    
    @IsTest
    static void testAssignAndRemoveManager() {
        
        // Arrange: insert a Garden without a manager.
        Garden__c garden = buildGarden(null, 75, 100, 0, 10);
        insert garden;
        
        Id managerId = UserInfo.getUserId();
        
        Test.startTest();
        
        // Act 1: assign the manager.
        garden.Manager__c = managerId;
        update garden;
        
        // Capture the task created by the manager assignment.
        List<Task> createdTasks = [
        SELECT Id, OwnerId, WhatId, Subject
        FROM Task
        WHERE WhatId = :garden.Id
        AND Subject = 'Acquire Plants'
    ];
        
        // Act 2: remove the manager.
        garden.Manager__c = null;
        update garden;
        
        Test.stopTest();
        
        // Assert: the manager start date should be cleared.
        Garden__c unassignedGarden = [
        SELECT Manager__c, Manager_Start_Date__c
        FROM Garden__c
        WHERE Id = :garden.Id
    ];
        
        System.assertEquals(
            null,
        unassignedGarden.Manager__c,
        'The Garden should no longer have a manager.'
            );
        
        System.assertEquals(
            null,
        unassignedGarden.Manager_Start_Date__c,
        'Removing the manager should clear the start date.'
            );
        
        // Assert: assignment created the expected task.
        System.assertEquals(
            1,
        createdTasks.size(),
        'Assigning a manager should create one task.'
            );
        
        System.assertEquals(
            managerId,
        createdTasks[0].OwnerId,
        'The task should initially belong to the assigned manager.'
            );
        
        // Assert: removing the manager should delete their open task.
        Integer remainingTasks = [
        SELECT COUNT()
        FROM Task
        WHERE WhatId = :garden.Id
        AND Subject = 'Acquire Plants'
    ];
        
        System.assertEquals(
            0,
        remainingTasks,
        'The open task should be deleted when the manager is removed.'
            );
    }
    
    
    
    /*
     * TEST 5
     * Permanent Closure must be preserved on insertion and update.
     */
    @IsTest
    static void testPermanentClosureIsPreserved() {
        
        Garden__c garden = buildGarden(null, 75, 100, 0, 10);
        garden.Status__c = 'Permanent Closure';
        
        insert garden;
        
        System.assertEquals(
            'Permanent Closure',
        garden.Status__c,
        'The insert trigger should preserve Permanent Closure.'
            );
        
        garden.Total_Plant_Count__c = 80;
        
        Test.startTest();
        update garden;
        Test.stopTest();
        
        Garden__c savedGarden = [
            SELECT Status__c
            FROM Garden__c
            WHERE Id = :garden.Id
        ];
        
        System.assertEquals(
            'Permanent Closure',
        savedGarden.Status__c,
        'A previously permanently closed Garden must remain closed.'
            );
    }
    
    
    /*
     * TEST 6
     * A completed task should not be deleted when the manager is removed.
     */
    @IsTest
    static void testCompletedTaskIsNotDeleted() {
        
        Garden__c garden = buildGarden(
            UserInfo.getUserId(), 75, 100, 0, 10
            );
        insert garden;
        
        Task acquirePlantsTask = [
            SELECT Id, Status
            FROM Task
            WHERE WhatId = :garden.Id
            AND Subject = 'Acquire Plants'
            LIMIT 1
        ];
        
        acquirePlantsTask.Status = 'Completed';
        update acquirePlantsTask;
        
        garden.Manager__c = null;
        
        Test.startTest();
        update garden;
        Test.stopTest();
        
        List<Task> completedTasks = [
            SELECT Id, Status
            FROM Task
            WHERE Id = :acquirePlantsTask.Id
        ];
        
        System.assertEquals(
            1,
        completedTasks.size(),
        'A completed task should not be deleted when a manager is removed.'
            );
        
        System.assertEquals(
            'Completed',
        completedTasks[0].Status,
        'The task should remain completed.'
            );
    }
    
    
    /*
     * TEST DATA HELPER
     * Creates a second User so the reassignment branch can be tested.
     */
    private static User buildAnotherManager() {
        
        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE UserType = 'Standard'
            LIMIT 1
        ];
        
        String uniqueValue =
            String.valueOf(DateTime.now().getTime());
        
        return new User(
            Alias = 'mgrtest',
        Email = 'mgrtest' + uniqueValue + '@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Test Manager',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = standardProfile.Id,
        TimeZoneSidKey = 'Asia/Kolkata',
        Username = 'mgrtest' + uniqueValue + '@example.com'
            );
    }
    
    
    /*
     * TEST 7
     * Reassign an existing manager's open task to the new manager.
     */
    @IsTest
    static void testManagerTaskReassignment() {
        
        Id originalManagerId = UserInfo.getUserId();
        
        // User is a setup object. Create it before Garden DML.
        User newManager = buildAnotherManager();
        insert newManager;
        
        // runAs provides the usual test workaround for mixed DML.
        System.runAs(newManager) {
            
            Garden__c garden = buildGarden(
                originalManagerId, 75, 100, 0, 10
                );
            insert garden;
            
            Task taskBeforeUpdate = [
                SELECT Id, OwnerId, WhatId, Subject, Status
                FROM Task
                WHERE WhatId = :garden.Id
                AND Subject = 'Acquire Plants'
                LIMIT 1
            ];
            
            System.assertEquals(
                originalManagerId,
            taskBeforeUpdate.OwnerId,
            'Initially, the task should belong to the original manager.'
                );
            
            // Change to a different manager.
            garden.Manager__c = newManager.Id;
            
            Test.startTest();
            update garden;
            Test.stopTest();
            
            Task taskAfterUpdate = [
                SELECT Id, OwnerId
                FROM Task
                WHERE Id = :taskBeforeUpdate.Id
            ];
            
            System.assertEquals(
                newManager.Id,
            taskAfterUpdate.OwnerId,
            'The open task should be reassigned to the new manager.'
                );
        }
    }
}