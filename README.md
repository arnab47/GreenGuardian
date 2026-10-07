# Green Guardian — Salesforce Garden Management System

## Overview
**Green Guardian** is a Salesforce application developed to streamline operations for the San Francisco Arboretum & Botanical Gardens. It handles garden limits, manager delegation, and plant lifecycle tracking across high-volume data scenarios.

## Tech Stack & Architecture
* **Platform:** Salesforce Lightning / Camp Apex Project
* **Core sObjects:** `Garden__c`, `Plant__c`, `User`
* **Automation:** Apex Triggers (Bulkified design patterns), Record-Triggered Flows, Validation Rules
* **Key Metrics:** Dynamic garden capacity calculations and plant health indices calculated via triggered automation

## Key Capabilities
* **Bulk Data Processing:** Designed to reliably handle bulk creation and updates across hundreds of plant records without hitting governor limits.
* **Capacity Tracking:** Automated logic to restrict and monitor garden capacity thresholds.
* **Health & Lifecycle Management:** Real-time updates to sunlight, soil, water, and health status indicators.
