
@IsTest
private class PlantTriggerTest {

    // Creates a Garden with the fields needed by these tests.
    private static Garden__c buildGarden(String gardenName, String sunExposure) {
        return new Garden__c(
            Name = gardenName,
            Sun_Exposure__c = sunExposure,
            Minimum_Plant_Count__c = 1,
            Maximum_Plant_Count__c = 100,
            Total_Plant_Count__c = 0,
            Total_Unhealty_Plant_Count__c = 0
        );
    }

    // Creates a Plant. The trigger should supply default values
    // when soil, water, and sunlight are left blank.
    private static Plant__c buildPlant(
        String plantName,
        Id gardenId,
        String plantStatus
    ) {
        return new Plant__c(
            Name = plantName,
            Garden__c = gardenId,
            Status__c = plantStatus
        );
    }

    @IsTest
    static void testDefaultValuesAndGardenSunlight() {
        Garden__c sunnyGarden = buildGarden('Sunny Garden', 'Full Sun');
        Garden__c gardenWithoutSun = buildGarden('Garden Without Sun', null);
        insert new List<Garden__c>{ sunnyGarden, gardenWithoutSun };

        Plant__c plantWithGardenSun =
            buildPlant('Rose', sunnyGarden.Id, 'Healthy');
        Plant__c plantWithoutGardenSun =
            buildPlant('Fern', gardenWithoutSun.Id, 'Healthy');
        Plant__c plantWithoutGarden =
            buildPlant('Indoor Plant', null, 'Healthy');

        Test.startTest();
        insert new List<Plant__c>{
            plantWithGardenSun,
            plantWithoutGardenSun,
            plantWithoutGarden
        };
        Test.stopTest();

        Map<Id, Plant__c> savedPlants = new Map<Id, Plant__c>([
            SELECT Soil_Type__c, Water__c, Sunlight__c, Garden__c
            FROM Plant__c
            WHERE Id IN :new Set<Id>{
                plantWithGardenSun.Id,
                plantWithoutGardenSun.Id,
                plantWithoutGarden.Id
            }
        ]);

        System.assertEquals(
            'All Purpose Potting Soil',
            savedPlants.get(plantWithGardenSun.Id).Soil_Type__c
        );
        System.assertEquals(
            'Once Weekly',
            savedPlants.get(plantWithGardenSun.Id).Water__c
        );
        System.assertEquals(
            'Full Sun',
            savedPlants.get(plantWithGardenSun.Id).Sunlight__c
        );
        System.assertEquals(
            'Partial Sun',
            savedPlants.get(plantWithoutGardenSun.Id).Sunlight__c
        );
        System.assertEquals(
            'Partial Sun',
            savedPlants.get(plantWithoutGarden.Id).Sunlight__c
        );
    }

    @IsTest
    static void testPlantCountRollupOnInsertAndDelete() {
        Garden__c garden = buildGarden('Rollup Garden', 'Partial Sun');
        insert garden;

        List<Plant__c> plants = new List<Plant__c>{
            buildPlant('Plant One', garden.Id, 'Healthy'),
            buildPlant('Plant Two', garden.Id, 'Healthy')
        };

        Test.startTest();
        insert plants;

        Garden__c afterInsert = [
            SELECT Total_Plant_Count__c
            FROM Garden__c
            WHERE Id = :garden.Id
        ];
        System.assertEquals(2, afterInsert.Total_Plant_Count__c);

        delete plants;
        Test.stopTest();

        Garden__c afterDelete = [
            SELECT Total_Plant_Count__c
            FROM Garden__c
            WHERE Id = :garden.Id
        ];
        System.assertEquals(0, afterDelete.Total_Plant_Count__c);
    }

    @IsTest
    static void testPlantCountRollupWhenMovedBetweenGardens() {
        Garden__c gardenA = buildGarden('Garden A', 'Full Sun');
        Garden__c gardenB = buildGarden('Garden B', 'Partial Sun');
        insert new List<Garden__c>{ gardenA, gardenB };

        Plant__c plant = buildPlant('Moving Plant', gardenA.Id, 'Healthy');
        insert plant;

        Test.startTest();
        plant.Garden__c = gardenB.Id;
        update plant;
        Test.stopTest();

        Map<Id, Garden__c> savedGardens = new Map<Id, Garden__c>([
            SELECT Total_Plant_Count__c
            FROM Garden__c
            WHERE Id IN :new Set<Id>{ gardenA.Id, gardenB.Id }
        ]);

        System.assertEquals(
            0,
            savedGardens.get(gardenA.Id).Total_Plant_Count__c
        );
        System.assertEquals(
            1,
            savedGardens.get(gardenB.Id).Total_Plant_Count__c
        );
    }

    @IsTest
    static void testUnhealthyPlantCounts() {
        Garden__c garden = buildGarden('Plant Health Garden', 'Partial Sun');
        insert garden;

        List<Plant__c> plants = new List<Plant__c>{
            buildPlant('Healthy Plant', garden.Id, 'Healthy'),
            buildPlant('Sick Plant', garden.Id, 'Sick'),
            buildPlant('Wilting Plant', garden.Id, 'Wilting'),
            buildPlant('Deceased Plant', garden.Id, 'Deceased')
        };

        Test.startTest();
        insert plants;

        Garden__c afterInsert = [
            SELECT Total_Unhealty_Plant_Count__c
            FROM Garden__c
            WHERE Id = :garden.Id
        ];
        System.assertEquals(3, afterInsert.Total_Unhealty_Plant_Count__c);

        Plant__c sickPlant = [
            SELECT Id, Status__c, Garden__c
            FROM Plant__c
            WHERE Name = 'Sick Plant'
            LIMIT 1
        ];

        sickPlant.Status__c = 'Healthy';
        update sickPlant;
        Test.stopTest();

        Garden__c afterRecovery = [
            SELECT Total_Unhealty_Plant_Count__c
            FROM Garden__c
            WHERE Id = :garden.Id
        ];
        System.assertEquals(2, afterRecovery.Total_Unhealty_Plant_Count__c);
    }

    @IsTest
    static void testUnhealthyPlantMovedBetweenGardens() {
        Garden__c gardenA = buildGarden('Unhealthy Garden A', 'Full Sun');
        Garden__c gardenB = buildGarden('Unhealthy Garden B', 'Partial Sun');
        insert new List<Garden__c>{ gardenA, gardenB };

        Plant__c plant = buildPlant('Sick Moving Plant', gardenA.Id, 'Sick');
        insert plant;

        Test.startTest();
        plant.Garden__c = gardenB.Id;
        update plant;
        Test.stopTest();

        Map<Id, Garden__c> savedGardens = new Map<Id, Garden__c>([
            SELECT Total_Unhealty_Plant_Count__c
            FROM Garden__c
            WHERE Id IN :new Set<Id>{ gardenA.Id, gardenB.Id }
        ]);

        System.assertEquals(
            0,
            savedGardens.get(gardenA.Id).Total_Unhealty_Plant_Count__c
        );
        System.assertEquals(
            1,
            savedGardens.get(gardenB.Id).Total_Unhealty_Plant_Count__c
        );
    }
}
