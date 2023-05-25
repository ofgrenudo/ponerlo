## 5/25/2023

- Added Inno Setup Configuration Script for easy deployments!
- excluding exes
- Need to write IExpress documentation
- Pulling the asset tag from a file now instead of registry.

## 5/23/2023

To resolve the IE issues, my plan is to just package this as a self exporting EXE and then place a registry key in the HKLM RunOnce method, to have it run the first logon and upload information to the inventory system.

I also remvoed dependency on the Task Sequence Variable so this can run all from the registry... Although im sure that it is broken for anyone other than the company right now.

## 5/17/2023

Hmmm, It doesnt work in the Task Sequence due to a erorr with Internet Explorer Services not Registering... I have to find a work around.

## 5/15/2023

Get-CategoryID, New-CategoryID, Get-ManufactureID, and New-ManufactureID all are working now. They erorr out the first time you call on a model or category or make that isnt new but since, each function gets called like 3 times it works. This is definetly a weak point in the application but for now it works. 

Time to test it.

## 5/13/2023

Currently I need to create, Get-CategoryID, New-CategoryID, Get-ManufactureID, New-ManufactureID.

The category and manufcature must be pre existing to submit a new model. Hopefully, we wont use the New-ManufactureID feature too often, but just incase. We will want to create both New-Manufacture* and New-Category* features.

https://snipe-it.readme.io/reference/manufacturers
https://snipe-it.readme.io/reference/categories-1