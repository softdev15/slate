---
title: Shipamax Freight Forwarding API Reference

toc_footers:
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>


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

## Event Webhooks

The webhooks will be triggered when there is a new validation result for a FileGroup. Currently you are required to manually provide Shipamax with the destination URL which the webhooks should call.

For webhook security we sign inbound requests to your application with an X-Shipamax-Signature HTTP header together with an X-Shipamax-Signature-Version header. See [Validating webhook signatures](#validating-webhook-signatures) for how to validate the requests.

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

The `eventName` property describes what caused the message to be sent. There are currently three events you could receive:
  
| Event Name                                   | Description                                |
| -------------------------------------------- | ------------------------------------------ |
| Validation/BillOfLadingGroup/Success         | Validation finished and succeed            |
| Validation/BillOfLadingGroup/Failure         | Validation finished with exceptions        |
| Validation/BillOfLadingGroup/NoBillsOfLading | File received but no bills of lading found |

These events are triggered when the bills of lading in a FileGroup validation pass, fail or no bill of lading is found in the file, respectively.

For more details of exception codes, check our [list of exceptions](#list-of-exceptioncode-values)

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
  -H 'X-Shipamax-Signature-Version: v1' \
  -H 'X-Shipamax-Signature: {SIGNATURE}' \
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

## Validating webhook signatures

When you receive a message on your configured webhook endpoint, you can check that the message really came from Shipamax by validating a signature that Shipamax will send with every request. You will receive a secret key as part of the onboarding process, and may receive new keys from us from time to time. This key is used to generate a cryptographic hash of the request.

Each request will have the two HTTP headers `X-Shipamax-Signature-Version` and `X-Shipamax-Signature`.

Currently all requests have a value of `v1` for the `X-Shipamax-Signature-Version` header. If in the future we change the method that you need to use to verify the signature, this version will be updated.

To verify the message, use your secret key to generate an HMAC-SHA256 hash of the body of the HTTP request, and compare this to the value in the `X-Shipamax-Signature` header. If they match, then the message came from Shipamax. If they do not match then the message may have come from a malicious third-party, and should be ignored.

For example with a secret of 12345 and a body of

```json
{"kind":"#shipamax-webhook","eventName":"Validation/BillOfLadingGroup/Failure","payload":{"exceptions":[{"code":22,"description":"Bill of Lading: Missing MBL"}],"fileGroupId":48751}}
```

The resulting hash would be: `9e6066637a3020bd2cc15ce8a6f18e9e43d63e169a6d355c882fe457d87f0130`


## Long-term support and versioning

Shipamax aims to be a partner to our customers, this means continuously improving everything including our APIs. However, this does mean that APIs can only be supported for a given timeframe. We aim to honour the expected End-Of-Life, but in case this is not possible we will work with our customers to find a solution.  
  
Version: v1  
Launch: April 2020  
Expected End-Of-Live: March 2023  


# Reference

## FileGroup Endpoint

Shipamax groups files that are associated with each other into a FileGroup. For example, you may have received a Master BL with associated House BLs and these will be contained within the same FileGroup.
​
A FileGroup is a collection of Files which may contain a BillOfLading entity. The following endpoint is available.

| Endpoint                   | Verb | Description                                                 |
| -------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroups/{id}            | GET  | Get a Bill of Lading Group based on the given ID.           |

Get a FileGroup by making a `GET` request to `https://public.shipamax-api.com/api/v2/FileGroups/{id}`

> The GET FileGroup request returns JSON structured like this:

```json
​{
  "id": integer,
  "created": "[ISO8601 timestamp]",
  "lastValidationResult": {
    "isSuccess": boolean,
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
      "uniqueId": string,
      "created": "[ISO8601 timestamp]",
      "billOfLading": [
        {
          "billOfLadingNo": string,
          "bookingNo": string,
          "exportReference": string,
          "scac": string,
          "isRated": boolean,
          "isDraft": boolean,
          "shipper": string,
          "shipperCode": string,
          "consignee": string,
          "consigneeCode": string,
          "notify": string,
          "notifyCode": string,
          "secondNotify": string,
          "secondNotifyCode": string,
          "destinationAgent": string,
          "carrier": string,
          "carrierCode": string,
          "grossWeight": string,
          "grossVolume": string,
          "vessel": string,
          "vesselIMO": string,
          "voyageNumber": string,
          "loadPort": string,
          "loadPortUnlocode": string,
          "dischargePort": string,
          "dischargePortUnlocode": string,
          "shippedOnBoardDate": date,
          "paymentTerms": PaymentTerm,
          "category": string,
          "releaseType": ReleaseType,
          "goodsDescription": string,
          "transportMode": TransportMode,
          "containerMode": ContainerMode,
          "shipmentType": ShipmentType,
          "consolType": ConsolType,
          "jobRef": string,
          "container": [
            {
              "containerNo": string,
              "numberPieces": integer,
              "pieceType": PackageType,
              "weight": string,
              "volume": string,
              "containerType": ContainerType,
              "seals": [string]
            }
          ]
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
| lastValidationResult.isSuccess          | If validation was successful this flag will be true. If not, false.                                                               |
| lastValidationResult.details            | Further detail on the type of exception                                                                                           |
| lastValidationResult.details.validator  | Shipamax has multiple validators for different workflows and integrations. This specifies from which validator issued this result |
| lastValidationResult.details.exceptions | The list of exceptions that caused validation to fail. Possible values can be seen in our [list of exceptions](#list-of-exceptioncode-values)     |
| files                                   | List of files within the FileGroup                                                                                                |
| files.filename                          | The name of the file as received within the email                                                                                 |
| files.billOfLading                      | An array of bills of lading extracted from this file, if any.                                                                     |
| files.billOfLading.billOfLadingNo       | The Bill of Lading number as extracted from the document.                                                                         |
| files.billOfLading.bookingNo            | The Booking reference as extracted from the document. This is the reference provided by Issuer to the Shipper                     |
| files.billOfLading.exportReference      | The Export Reference as extracted from the document. This is the reference given by the Shipper to the Issuer                     |
| files.billOfLading.scac                 | This is the SCAC code for the issuer of the Bill of Lading                                                                        |
| files.billOfLading.isRated              | If isRated is True, then the Bill of Lading contains pricing for the transport of the goods                                       |
| files.billOfLading.isDraft              | If isDraft is True, then this Bills of Lading is a Draft version and not Final                                                    |
| files.billOfLading.jobRef               | Importer Job Ref                                                                                                                  |
| files.billOfLading.shipper              ||
| files.billOfLading.shipperCode          ||
| files.billOfLading.consignee            ||
| files.billOfLading.consigneeCode        ||
| files.billOfLading.notify               ||
| files.billOfLading.notifyCode           ||
| files.billOfLading.secondNotify         ||
| files.billOfLading.secondNotifyCode     ||
| files.billOfLading.destinationAgent     ||
| files.billOfLading.carrier              ||
| files.billOfLading.carrierCode          ||
| files.billOfLading.grossWeight          ||
| files.billOfLading.grossVolume          ||
| files.billOfLading.vessel               ||
| files.billOfLading.vesselIMO            ||
| files.billOfLading.voyageNumber         ||
| files.billOfLading.loadPort             ||
| files.billOfLading.loadPortUnlocode     ||
| files.billOfLading.dischargePort        ||
| files.billOfLading.dischargePortUnlocode||
| files.billOfLading.shippedOnBoardDate   ||
| files.billOfLading.paymentTerms         ||
| files.billOfLading.category             ||
| files.billOfLading.releaseType          ||
| files.billOfLading.goodsDescription     ||
| files.billOfLading.transportMode        ||
| files.billOfLading.containerMode        ||
| files.billOfLading.shipmentType         ||
| files.billOfLading.container.containerNo         ||
| files.billOfLading.container.numberPieces         ||
| files.billOfLading.container.pieceType         ||
| files.billOfLading.container.weight         ||
| files.billOfLading.container.volume         ||
| files.billOfLading.container.containerType         ||
| files.billOfLading.container.seals         ||


> Example:

```json
{
  "id": 1,
  "created": "2020-05-07T15:24:47.338Z",
  "lastValidationResult": {
    "isSuccess": false,
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
          "isDraft": false,
          "shipper": "",
          "shipperCode": "",
          "consignee": "",
          "consigneeCode": "",
          "notify": "",
          "notifyCode": "",
          "secondNotify": "",
          "secondNotifyCode": "",
          "destinationAgent": "",
          "carrier": "",
          "carrierCode": "",
          "grossWeight": "",
          "grossVolume": "",
          "vessel": "",
          "vesselIMO": "",
          "voyageNumber": "",
          "loadPort": "",
          "loadPortUnlocode": "",
          "dischargePort": "",
          "dischargePortUnlocode": "",
          "shippedOnBoardDate": "2020-05-07T15:24:47.338Z",
          "paymentTerms": "",
          "category": "",
          "releaseType": "",
          "goodsDescription": "",
          "transportMode": "",
          "containerMode": "",
          "shipmentType": "",
          "jobRef": "",
          "container": [
            {
              "containerNo": "ABCD0123456",
              "numberPieces": 10,
              "pieceType": "CTN",
              "weight": "",
              "volume": "",
              "containerType": "40GP",
              "seals": [
                "AB1234567"
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

> Example curl to perform request:

```javascript
curl -X GET \
  https://public.shipamax-api.com/api/v2/FileGroups/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN}"
```

## Validation Endpoint

For a full workflow Shipamax enables you to provide Validation results via API.

The following endpoint is currently available:

| Endpoint                         | Verb  | Description                                                                       |
| -------------------------------- | ----- | --------------------------------------------------------------------------------- |
| /FileGroups/{id}/validationResult | POST  | Submit a new validationResult making it the lastValidationesult of the FileGroup  |

Send a new validation result via `POST` request to `https://public.shipamax-api.com/api/v2/FileGroups/{id}/validationResult`

> The POST validationResult request requires a body JSON structured like this:

```json
{
  "isSuccess": boolean,
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
| isSuccess                               | Definition whether the validation is successful or not            |
| details.validator                       | Optional name of the application that produced this result, e.g. "CompanyABCValidator"   |
| details.exceptions.code                 | Exception code, see the [list of exceptions](#list-of-exceptioncode-values)                |
| details.exceptions.description          | Optional field, used in case of custom exception which code is -1 |

> Example of body to be POSTED:

```json
{
  "isSuccess": false,
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

## Get file Endpoint

You can retrieve all files processed by Shipamax. For example you can retrieve a bill of lading which was send to Shipamax as an attachment to an email. Files can be retrieved via their unique ID. The response of the endpoint is a byte stream.

https://public.shipamax-api.com/api/v2/Files/{id}

## Lists of codes for fields

Several fields listed in the sections above should usually only contain specific values from a known list. For example, where the type of the `releaseType` field of a billOfLading is given as `ReleaseType`, it means that the expected set of values comes from the [list of ReleaseType values](#list-of-releasetype-values).

These values are show in the following lists.

### List of ExceptionCode values

Exception codes other than -1 have a specific meaning within the Shipamax system, as listed in the table below. When creating a validation result you should use an existing code where there is an appropriate one available, or -1 if there is not. You can use any description you like for any code, but the default descriptions for each code that Shipamax generates are listed in the table.


| Exception code  | Description                                                                               |
| --------------- | ----------------------------------------------------------------------------------------- |
| 1               | Supplier Invoice: Missing Invoice Number                                                  |
| 2               | Supplier Invoice: Missing Invoice Date                                                    |
| 3               | Supplier Invoice: Missing Issuer                                                          |
| 4               | Supplier Invoice: Missing Invoice Total                                                   |
| 5               | Supplier Invoice: Missing Invoice Currency                                                |
| 6               | Supplier Invoice: No Job references                                                       |
| 7               | CargoWise: Invalid Addressee                                                              |
| 8               | CargoWise: Duplicate Invoice Number                                                       |
| 9               | CargoWise: Failed to match a set of accruals to the Invoice Total                         |
| 10              | CargoWise: Currencies didn't match                                                        |
| 11              | CargoWise: VAT didn't match                                                               |
| 12              | CargoWise: Failed to post to Cargowise                                                    |
| 13              | CargoWise: More than one possible set of accruals for the Invoice Total                   |
| 14              | CargoWise: Missing CargoWise code for issuer                                              |
| 15              | CargoWise: One or more costs is apportioned to a consol                                   |
| 16              | Demo: Document passed validation                                                          |
| 17              | Supplier Invoice: Invoice date is in the future                                           |
| 18              | CargoWise: Shipment not found                                                             |
| 19              | CargoWise: Error on Cargowise HTTP request                                                |
| 20              | The validation process itself failed                                                      |
| 21              | CargoWise: Invoice Number already exists                                                  |
| 22              | Bill of Lading: Missing MBL                                                               |
| 23              | Bill of Lading: Multiple MBLs                                                             |
| 24              | Bill of Lading: Incorrect Consignee for Consol Type                                       |
| 25              | Bill of Lading: Missing HBLs                                                              |
| 26              | CargoWise: Manual approval required to post                                               |
| 27              | Unable to Match to Job                                                                    |
| 28              | Multiple possible Jobs                                                                    |
| 29              | Bill Of lading: Missing job references                                                    |
| 30              | Bill Of lading: Missing SCAC                                                              |
| 31              | Supplied job reference does not exist in CargoWise                                        |
| 32              | Bill of Lading: MBL missing Consignee                                                     |
| 33              | CargoWise: Documents exceeds maximum file size limit of 10MB                              |
| 34              | Supplier Invoice: Sub totals don’t add up to invoice total                                |
| 35              | CargoWise: More than one possible set of accruals for highlighted sub total               |
| 36              | CargoWise: Failed to match a set of accruals for highlighted sub total                    |
| 37              | Supplier Invoice: Job not in any clusters                                                 |
| 38              | Bill of lading: Missing consignor/consignee                                               |
| 39              | Bill of lading: Missing origin                                                            |
| 40              | Bill Of lading: Missing destination                                                       |
| 41              | Bill of lading: Missing container mode                                                    |
| 42              | Bill of lading: Missing release type                                                      |
| 43              | Bill of lading: Missing packing mode                                                      |
| 44              | CargoWise: No accruals found for this creditor in this currency                           |
| 45              | Error in pre-validator (please contact support)                                           |
| 46              | Error in CargoWise validator (please contact support)                                     |
| 47              | Commercial invoice: Mixed invoice/bill groups not supported                               |
| 48              | Commercial invoice: Invoice number missing                                                |
| 49              | Commercial invoice: Gross total missing                                                   |
| 50              | CargoWise: Failed to find a matching Job Ref for highlighted BL or Container Number       |
| 51              | CargoWise: No accruals found for this creditor in this currency on highlighted sub total  |
| -1              | Custom exception                                                                          |

### List of PaymentTerm values

| PaymentTerm | Description |
| ----------- | ----------- |
| CCX         | Collect     |
| PPD         | Prepaid     |

### List of ReleaseType values

| ReleaseType | Description                              |
| ----------- | ---------------------------------------- |
| BRR         | Letter of Credit (Bank Release)          |
| BSD         | Sight Draft (Bank Release)               |
| BTD         | Time Draft (Bank Release)                |
| CSH         | Company/Cashier Cheque                   |
| CAD         | Cash Against Documents                   |
| EBL         | Express Bill of Lading                   |
| LOI         | Letter of Indemnity                      |
| NON         | Not Negotiable unless consigned to Order |
| OBO         | Original Bill - Surrendered at Origin    |
| OBR         | Original Bill Required at Destination    |
| SWB         | Sea Waybill                              |
| TLX         | Telex Release                            |

### List of ContainerType values

| ContainerType | Description                      |
| ------------- | -------------------------------- |
| 20NOR         | Twenty foot non-operating reefer |
| 40FR          | Forty foot flatrack              |
| 20FR          | Twenty foot flatrack             |
| 40HC          | Forty foot high cube             |
| 20GP          | Twenty foot general purpose      |
| 40NOR         | Forty foot non-operating reefer  |
| 40PL          | Forty foot platform              |
| 40GP          | Forty foot general purpose       |
| 20RE          | Twenty foot reefer               |
| 20PL          | Twenty foot platform             |
| 40RE          | Forty foot reefer                |
| 20OT          | Twenty foot open top             |
| 45HC          | Forty Five foot high cube        |
| 40OT          | Forty foot open top              |
| 40REHC        | Forty foot high cube reefer      |
| 20HC          | Twenty foot high cube            |

### List of ConsolType values

| ConsolType | Description |
| ---------- | ----------- |
| AGT        | Agent       |
| DRT        | Direct      |
| CLD        | Co-Load     |
| CHT        | Charter     |
| COU        | Courier     |
| OTH        | Other       |

### List of TransportMode values

| TransportMode | Description  |
| ------------- | ------------ |
| AIR           | Air Freight  |
| SEA           | Sea Freight  |
| ROA           | Road Freight |
| RAI           | Rail Freight |

### List of PackageType values

| PackageType | Description        |
| ----------- | ------------------ |
| BAG         | Bag                |
| BBG         | Bulk Bag           |
| BBK         | Break Bulk         |
| BLC         | Bale, Compressed   |
| BLU         | Bale, Uncompressed |
| BND         | Bundle             |
| BOT         | Bottle             |
| BOX         | Box                |
| BSK         | Basket             |
| CAS         | Case               |
| COI         | Coil               |
| CRD         | Cradle             |
| CRT         | Crate              |
| CTN         | Carton             |
| CYL         | Cylinder           |
| DOZ         | Dozen              |
| DRM         | Drum               |
| ENV         | Envelope           |
| GRS         | Gross              |
| KEG         | Keg                |
| MIX         | Mix                |
| PAI         | Pail               |
| PCE         | Piece              |
| PKG         | Package            |
| PLT         | Pallet             |
| REL         | Reel               |
| RLL         | Roll               |
| SHT         | Sheet              |
| SKD         | Skid               |
| SPL         | Spool              |
| TOT         | Tote               |
| TUB         | Tube               |
| UNT         | Unit               |

### List of ContainerMode values
| PackageType | Description              |
| ----------- | ------------------------ |
| FCL         | Full Container Load      |
| LCL         | Less than Container Load |
| GRP         | Groupage                 |
