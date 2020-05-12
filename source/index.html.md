---
title: Shipamax Freight Forwarding API Reference	

toc_footers:	
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>	
  - <a href='https://github.com/softdev15/slate'><img src="./images/github.png"/>Contribute to these Docs</a>	


search: true	
---	

# Getting started	

The Shipmax Freight Forwarding API allows developers to create applications that automatically extra data from various documents received by their businesses.	

If you would like to use this API and are not already a Shipamax Freight Forwarding customer, please contact our [support team](mailto:support@shipamax.com).	


# Requirements

1. You will need to get an access token from Shipamax. If you don't have one, please contact our [support team](mailto:support@shipamax.com).	
2. You will need to share your webhook endpoint with Shipamax.  

# Email and webhook workflow
Set up email forwarding to your Shipamax account. When emails arrive, they will be parsed and at the end a validation process will be triggered. This validation process will call the customer webhook endpoint and provide an ID, for example a fileGroupId. With this ID you can query the parsing results.  
After receiving the parsing results and processing them in your workflow it is crucial to call the Shipamax exception endpoint. This allows Shipamax to provide a workflow for handling the exception in its Exception Manager and to improve the machine learning.


# API basics

The API is [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_Web_services), and messages are encoded as JSON documents

### Endpoint

The base URI for all API endpoints is `https://public.shipamax-api.com/api/v2/`.

### Content type

Unless specified otherwise, requests with a body attached should be sent with a `Content-Type: application/json` HTTP header.

# Authorization

All API methods require you to be authenticated. Once you have your access token, which will be given to you by the Shipamax Team, you can send it along with any API requests you make in a header. If your access token was `abc123token`, you would send it as the HTTP header `Authorization: Bearer abc123token`.

# Reference

## Event Webhooks
​
The webhooks will be triggered when a document successfully parses the first validation. The destination URL which webhooks should call currently need to be provided by the customer to Shipamax, for example by email to the [support team](mailto:support@shipamax.com).
​
> The webhook endpoint will send a request to the provided endpoint via POST with the following body:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "[EVENT-NAME]",
  "payload": {
    "fileGroupId": integer,
    "exceptions": [
        {
            "code": ExceptionCode,
            "description": string
        }
    ]
   }
}
```
  
Details of body definition:  
​  
Event names:  
- Validation/BillOfLadingGroup/Failure  
- Validation/BillOfLadingGroup/Success  
​
For more details of exception codes, check our [list of exceptions](#list-of-exceptions)

> Example of body sent via webhook:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "Validation/BillOfLadingGroup/Failure",
  "payload": {
     "fileGroupId": 1,
     "exceptions": [
         { 
             "code": 1, 
             "description": "Bill of Lading: More than one MBL in group" 
         }
     ]
   } 
}
```

> Example curl to simulate webhook:

```javascript
curl -X POST \
  {CUSTOMER-WEBHOOK-URL} \
  -d '{
  "kind": "#shipamax-webhook",
  "eventName": "Validation/BillOfLadingGroup/Failure",
  "payload": {
     "fileGroupId": 1,
     "exceptions": [
         { 
             "code": 1, 
             "description": "Bill of Lading: More than one MBL in group" 
         }
     ]
   } 
  }'
```

## FileGroup

Shipamax groups files that are associated with each other into a FileGroup. For example, you may have received a Master BL with associated House BLs and these will be contained within the same FileGroup.   
​  
A FileGroup is a collection of Files which may contain a BillOfLading entity. The following endpoint is currently available

| Endpoint                   | Verb | Description                                                 |
| -------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroup/{id}            | GET  | Get a Bill of Lading Group based on the given ID.           |

Get a group by making a `GET` request to `https://public.shipamax-api.com/api/v2/FileGroup/{id}`

> The GET FileGroup request returns JSON structured like this:

```json
​{
    "id": integer,
    "created": "[ISO8601 timestamp]",
    "lastValidationResult": {
        "valid": boolean,
        "details": {
            "validator": "CargoWiseValidator",
            "exceptions": [
                {
                    "code": integer,
                    "description": string
                }
            ]
        },
        "created": "[ISO8601 timestamp]",
    },
    "files": [
        {
            "id": integer,
            "filename": string,
            "created": "[ISO8601 timestamp]",
            "billOfLading": [
                {
                    "billOfLadingNo": string,
                    "bookingNo": string,
                    "exportReference": string,
                    "scac": string,
                    "isRated": boolean,
                    "isDraft": boolean
                }
            ]
        }
    ]
}
```

Definition of the object attributes

| Attribute                               |  Description                                                    |
| --------------------------------------- | --------------------------------------------------------------- |
| lastValidationResult                    | Last validation's result of the current object                  |
| lastValidationResult.valid              |            |
| lastValidationResult.details            |            |
| lastValidationResult.details.validator  |            |
| lastValidationResult.details.exceptions |            |
| files                                   | List of files                                                   |
| files.filename                          |            |
| files.billOfLading                      |            |
| files.billOfLading.billOfLadingNo       |            |
| files.billOfLading.bookingNo            |            |
| files.billOfLading.exportReference      |            |
| files.billOfLading.scac                 |            |
| files.billOfLading.isRated              |            |
| files.billOfLading.isDraft              |            |



> Example:

```json
​{
    "id": 1,
    "created": "2020-05-07T15:24:47.338Z",
    "lastValidationResult": {
        "valid": false,
        "details": {
            "validator": "CargoWiseValidator",
            "exceptions": [
                {
                    "code": 9,
                    "description": "CargoWise: Total didn't match accruals"
                }
            ]
        },
        "created": "2020-05-07T15:24:47.509Z",
    },
    "files": [
        {
            "id": 442,
            "filename": "file.pdf",
            "created": "2020-05-07T15:24:47.338Z",
            "billOfLading": [
                {
                    "billOfLadingNo": "BOLGRP2",
                    "bookingNo": "121",
                    "exportReference": "REF",
                    "scac": "scac",
                    "isRated": true,
                    "isDraft": false
                }
            ]
        }
    ]
}
```


> Example curl to perform request:

```javascript
curl -X GET \
  https://public.shipamax-api.com/api/v2/FileGroup/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN}"
```

## Submit Exceptions

For a full workflow Shipamax requires the customer to provide Exception information via API.

Get a group by making a `POST` request to `https://public.shipamax-api.com/api/v2/Exception/{BL-Group-id}`


## List of Exceptions

Our validation system works with the following list of exceptions


| Exception code  | Name                               | Description                                                |
| --------------- | ---------------------------------- | ---------------------------------------------------------- |
| 1               | SupplierInvoiceNumberMissing       | Supplier Invoice: Missing Invoice Number                   |
| 2               | SupplierInvoiceDateMissing         | Supplier Invoice: Missing Invoice Date                     |
| 3               | SupplierInvoiceIssuerMissing       | Supplier Invoice: Missing Issuer                           |
| 4               | SupplierInvoiceTotalMissing        | Supplier Invoice: Missing Invoice Total                    |
| 5               | SupplierInvoiceCurrencyMissing     | Supplier Invoice: Missing Invoice Currency                 |
| 6               | SupplierInvoiceNoJobRefs           | Supplier Invoice: No Job references                        |
| 7               | CargoWiseInvalidAddressee          | CargoWise: Invalid Addressee                               |
| 8               | CargoWiseDuplicateInvoiceNumber    | CargoWise: Duplicate Invoice Number                        |
| 9               | CargoWiseTotalMismatch             | CargoWise: Total didn't match accruals                     |
| 10              | CargoWiseCurrencyMismatch          | CargoWise: Currencies didn't match                         |
| 11              | CargoWiseVATMismatch               | CargoWise: VAT didn't match                                |
| 12              | CargoWisePostFailed                | CargoWise: Failed to post to Cargowise                     |
| 13              | CargoWiseAmbiguousCosts            | CargoWise: More than 1 accrual combination                 |
| 14              | CargoWiseMissingIssuerCode         | CargoWise: Missing CargoWise code for issuer               |
| 15              | CargoWiseApportionedToConsol       | CargoWise: One or more costs is apportioned to a consol    |
| 16              | DemoSuccess                        | Demo: Document passed validation                           |
| 17              | SupplierInvoiceFutureDate          | Supplier Invoice: Invoice date is in the future            |
| 18              | CargoWiseShipmentNotFound          | CargoWise: Shipment not found                              |
| 19              | CargoWiseRequestError              | CargoWise: Error on Cargowise HTTP request                 |
| 20              | ValidatorError                     | The validation process itself failed                       |
| 21              | CargoWiseInvoiceAlreadyExists      | CargoWise: Invoice Number already exists                   |
| 22              | BillOfLadingMissingMBL             | Bill of Lading: Missing MBL                                |
| 23              | BillOfLadingMultipleMBLs           | Bill of Lading: Multiple MBLs                              |
| 24              | BillOfLadingMBLLikelyMisClassified | Bill of Lading: MBL likely mis-classified                  |
| 25              | BillOfLadingMissingHBLs            | Bill of Lading: Missing HBLs                               |
| 26              | ManualApprovalRequired             | CargoWise: Manual approval required to post                |
| -1              | Custom                             | This message can be customized                             |
