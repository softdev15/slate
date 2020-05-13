---
title: Shipamax Freight Forwarding API Reference

toc_footers:
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>
  - <a href='https://github.com/softdev15/slate'><img src="./images/github.png"/>Contribute to these Docs</a>


search: true
---

# Getting started

The Shipmax Freight Forwarding API allows developers to create applications that automatically extract data from various logistics documents received by their business.

Currently the API supports data extraction from Master and House Bills of Lading. Accounts Payable Invoices and Commercial Invoices will be added in the future.

If you would like to use this API and are not already a Shipamax Freight Forwarding customer, please contact our [support team](mailto:support@shipamax.com).


## Requirements

1. You will need an access token to authenticate your requests.
2. You will need to share your webhook endpoint with Shipamax in order to receive notifications of new results.
3. You will need a Shipamax email address to forward documents to for parsing.

To arrange any of the above, please contact your Shipamax Customer Success Manager or our [support team](mailto:support@shipamax.com).

## Workflow
To start the process, send the emails that you want to be processed to your custom Shipamax email address. You can send these emails manually, or forward them automatically from an external mailbox.

When Shipamax receives an email at this address, we begin by looking at all of the attachments. Each attachment becomes a File, and all of the Files in an email are initially part of one FileGroup. Our system first determines what kind of document is in each file, and sends supported document types to be parsed.

Once parsing has been completed for all Files in the FileGroup, the FileGroup will be validated against a set of rules to determine whether there are any exceptions. On completion of validation, the customer webhook endpoint will be called and provided with the FileGroup ID and the validation result. This ID can then be used to query for the parsing results.

After receiving the parsing results and processing them in your workflow, you should call the Shipamax validation endpoint to update Shipamax on whether you have successfully processed results or whether there is an exception. This allows Shipamax to provide a workflow for handling the exception in its Exception Manager and to improve the machine learning behind the data extraction.

The Shipamax Exception Manager App enables users to view FileGroups with exceptions and manually make necessary additions or corrections to the data. Once complete they can resubmit the FileGroup for validation which will subsequently trigger another webhook notification.

## API basics

The API is [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_Web_services), and messages are encoded as JSON documents

### Endpoint

The base URI for all API endpoints is `https://public.shipamax-api.com/api/v2/`.

### Content type

Unless specified otherwise, requests with a body attached should be sent with a `Content-Type: application/json` HTTP header.

## Authorization

All API methods require you to be authenticated. This is done using an access token which will be given to you by the Shipamax team.

This access token should be sent in the header of all API requests you make. If your access token was `abc123token`, you would send it as the HTTP header `Authorization: Bearer abc123token`.

# Reference

## Event Webhooks

The webhooks will be triggered when there is a new validation result for a FileGroup. Currently you are required to manually provide Shipamax with the destination URL which the webhooks should call.

> The webhook endpoint will send a request to the provided endpoint via POST with a body in the following format:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": string,
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

The `eventName` property describes what caused the message to be sent. There are currently two events you could receive:
  ​
- `Validation/BillOfLadingGroup/Failure`
- `Validation/BillOfLadingGroup/Success`

These events are triggered when the bills of lading in a FileGroup fail and pass validation, respectively.
​
For more details of exception codes, check our [list of exceptions](#list-of-exceptions)

> Example of body sent via webhook:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "Validation/BillOfLadingGroup/Failure",
  "payload": {
     "fileGroupId": 13704,
     "exceptions": [
        {
          "code": 23,
          "description": "Bill of Lading: Multiple MBLs"
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
     "fileGroupId": 13704,
     "exceptions": [
        {
          "code": 23,
          "description": "Bill of Lading: Multiple MBLs"
        }
     ]
   }
  }'
```

## FileGroup Endpoint

Shipamax groups files that are associated with each other into a FileGroup. For example, you may have received a Master BL with associated House BLs and these will be contained within the same FileGroup.
​
A FileGroup is a collection of Files which may contain a BillOfLading entity. The following endpoint is available.

| Endpoint                   | Verb | Description                                                 |
| -------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroup/{id}            | GET  | Get a Bill of Lading Group based on the given ID.           |

Get a FileGroup by making a `GET` request to `https://public.shipamax-api.com/api/v2/FileGroup/{id}`

> The GET FileGroup request returns JSON structured like this:

```json
​{
  "id": integer,
  "created": "[ISO8601 timestamp]",
  "lastValidationResult": {
    "isValid": boolean,
    "details": {
      "validator": string,
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

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| lastValidationResult                    | The result of the most recent validation                                                                                          |
| lastValidationResult.isValid            | If validation was successful this flag will be true. If not, false.                                                               |
| lastValidationResult.details            | Further detail on the type of exception                                                                                           |
| lastValidationResult.details.validator  | Shipamax has multiple validators for different workflows and integrations. This specifies from which validator issued this result |
| lastValidationResult.details.exceptions | The list of exceptions that caused validation to fail. Possible values can be seen in our [list of exceptions](#list-of-exceptions)     |
| files                                   | List of files within the FileGroup                                                                                                |
| files.filename                          | The name of the file as received within the email                                                                                 |
| files.billOfLading                      | An array of bills of lading extracted from this file, if any.                                                                     |
| files.billOfLading.billOfLadingNo       | The Bill of Lading number as extracted from the document.                                                                         |
| files.billOfLading.bookingNo            | The Booking reference as extracted from the document. This is the reference provided by Issuer to the Shipper                     |
| files.billOfLading.exportReference      | The Export Reference as extracted from the document. This is the reference given by the Shipper to the Issuer                     |
| files.billOfLading.scac                 | This is the SCAC code for the issuer of the Bill of Lading                                                                        |
| files.billOfLading.isRated              | If isRated is True, then the Bill of Lading contains pricing for the transport of the goods                                       |
| files.billOfLading.isDraft              | If isDraft is True, then this Bills of Lading is a Draft version and not Final                                                    |



> Example:

```json
{
  "id": 1,
  "created": "2020-05-07T15:24:47.338Z",
  "lastValidationResult": {
    "isValid": false,
    "details": {
      "validator": "BillOfLadingValidator",
      "exceptions": [
        {
          "code": 22,
          "description": "Bill of Lading: Missing MBL"
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

## Validation Endpoint

For a full workflow Shipamax enables you to provide Validation results via API.

The following endpoint is currently available:

| Endpoint                         | Verb  | Description                                                                       |
| -------------------------------- | ----- | --------------------------------------------------------------------------------- |
| /FileGroup/{id}/validationResult | POST  | Submit a new validationResult making it the lastValidationesult of the FileGroup  |

Send a new validation result via `POST` request to `https://public.shipamax-api.com/api/v2/FileGroup/{id}/validationResult`

> The POST validationResult request requires a body JSON structured like this:

```json
{
  "isValid": boolean,
  "details":  {
    "validator": string,
    "exceptions": [
      {
        "code": integer,
        "description": string (optional)
      }
    ]
  }
}
```
Definition of the object attributes

| Attribute                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| isValid                                 | Definition whether the validation is successful or not            |
| details.validator                       | Optional name of the application that produced this result, e.g. "CompanyABCValidator"   |
| details.exceptions.code                 | Exception code, see the [list of exceptions](#list-of-exceptions)                |
| details.exceptions.description          | Optional field, used in case of custom exception which code is -1 |

> Example of body to be POSTED:

```json
{
  "isValid": false,
  "details":  {
    "validator": "CompanyABCValidator",
    "exceptions": [
      {
        "code": -1,
        "description": "Custom message for Invalid value"
      }
    ]
  }
}
```

## List of Exceptions

Exception codes other than -1 have a specific meaning within the Shipamax system, as listed in the table below. When creating a validation result you should use an existing code where there is an appropriate one available, or -1 if there is not. You can use any description you like for any code, but the default descriptions for each code that Shipamax generates are listed in the table.


| Exception code  | Description                                                |
| --------------- | ---------------------------------------------------------- |
| 1               | Supplier Invoice: Missing Invoice Number                   |
| 2               | Supplier Invoice: Missing Invoice Date                     |
| 3               | Supplier Invoice: Missing Issuer                           |
| 4               | Supplier Invoice: Missing Invoice Total                    |
| 5               | Supplier Invoice: Missing Invoice Currency                 |
| 6               | Supplier Invoice: No Job references                        |
| 7               | CargoWise: Invalid Addressee                               |
| 8               | CargoWise: Duplicate Invoice Number                        |
| 9               | CargoWise: Total didn't match accruals                     |
| 10              | CargoWise: Currencies didn't match                         |
| 11              | CargoWise: VAT didn't match                                |
| 12              | CargoWise: Failed to post to Cargowise                     |
| 13              | CargoWise: More than 1 accrual combination                 |
| 14              | CargoWise: Missing CargoWise code for issuer               |
| 15              | CargoWise: One or more costs is apportioned to a consol    |
| 16              | Demo: Document passed validation                           |
| 17              | Supplier Invoice: Invoice date is in the future            |
| 18              | CargoWise: Shipment not found                              |
| 19              | CargoWise: Error on Cargowise HTTP request                 |
| 20              | The validation process itself failed                       |
| 21              | CargoWise: Invoice Number already exists                   |
| 22              | Bill of Lading: Missing MBL                                |
| 23              | Bill of Lading: Multiple MBLs                              |
| 24              | Bill of Lading: MBL likely mis-classified                  |
| 25              | Bill of Lading: Missing HBLs                               |
| 26              | CargoWise: Manual approval required to post                |
| 27              | Unable to Match to Job                                     |
| 28              | Multiple possible Jobs                                     |
| -1              | Custom exception                                           |
