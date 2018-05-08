@odd
Feature: This is test5 feature file
Scenario: Search using Zip code
Given I am on the "home" page
And I maximize the window
When I fill in "Location" with "22033"
And I move focus away from "Location"
And I click the "Search" button