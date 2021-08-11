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

| Endpoint                    | Verb | Description                                                 |
| --------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroups/{id}            | GET  | Get a Bill of Lading Group based on the given ID.           |

Get a FileGroup by making a `GET` request to `https://public.shipamax-api.com/api/v2/FileGroups/{id}`

URL Parameter Definitions

| Parameter                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| include                                 | List of inner objects to include in the returned FileGroup        |

List of possible objects to use in the include parameter

| --------------------------------------- |
| files                                   |
| lastValidationResult                    |
| files/billOfLading                      |
| files/billOfLading/importerReference    |
| files/billOfLading/notify               |
| files/billOfLading/container            |
| files/billOfLading/container/seals      |
| files/billOfLading/packline             |


> The GET FileGroup when requested with all its inner objects returns JSON structured like this:

```json
​{
  "id": integer,
  "created": "[ISO8601 timestamp]",
  "placeholderJobRef": string,
  "placeholderBillNumber": string,
  "status": integer,
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
      "created": "[ISO8601 timestamp]",
      "fileType": integer,
      "billOfLading": [
        {
          "id": integer,
          "billOfLadingNo": string,
          "bookingNo": string,
          "exportReference": string,
          "scac": string,
          "isRated": boolean,
          "isDraft": boolean,
          "shipper": string,
          "shipperOrgId": integer,
          "shipperOrgNameId": integer,
          "shipperOrgAddressId": integer,
          "consignee": string,
          "consigneeOrgId": integer,
          "consigneeOrgNameId": integer,
          "consigneeOrgAddressId": integer,
          "carrier": string,
          "carrierOrgId": integer,
          "carrierOrgNameId": integer,
          "carrierOrgAddressId": integer,
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
          "notify": [
            {
              "id": integer,
              "notifyParty": String
            }
          ],
          "importerReference:": [
            { 
              "id": integer,
              "importerReference": String,
            }
          ],
          "container": [
            {
              "id": integer,
              "containerNo": string,
              "containerType": ContainerType,
              "seals": [
                {
                  "id": integer,
                  "sealNo": string
                }
              ]
            }
          ],
          "packLine": [
            {
              "id": integer,
              "hsCode": string,
              "containerNo": string,
              "goodsDescription": string,
              "isGoodsSegment": boolean,
              "marksAndNumbers": string,
              "numberPieces": string,
              "pieceType": string,
              "weight": float,
              "volume": float,
              "weightUnit": string,
              "volumeUnit": string
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
| placeholderJobRef                       | In case this group does not have a Master Bill associated with, this placeholder can be used to store the Job Reference           |
| placeholderBillNumber                   | In case this group does not have a Master Bill associated with, this placeholder can be used to store the Bill Number             |
| status                                  | Status of the group in the shipamax flow. Possible values can be seen in our [list of group status](#list-of-group-status)        |
| lastValidationResult                    | The result of the most recent validation                                                                                          |
| lastValidationResult.isSuccess          | If validation was successful this flag will be true. If not, false.                                                               |
| lastValidationResult.details            | Further detail on the type of exception                                                                                           |
| lastValidationResult.details.validator  | Shipamax has multiple validators for different workflows and integrations. This specifies from which validator issued this result |
| lastValidationResult.details.exceptions | The list of exceptions that caused validation to fail. Possible values can be seen in our [list of exceptions](#list-of-exceptioncode-values)     |
| files                                   | List of files within the FileGroup                                                                                                |
| files.filename                          | The name of the file as received within the email                                                                                 |
| files.fileType                          | The type of the file as received within the email. Possible values can be seen in our [list of file types](#list-of-filetype-values)   |
| files.billOfLading                      | An array of bills of lading extracted from this file, if any.                                                                     |
| files.billOfLading.billOfLadingNo       | The Bill of Lading number as extracted from the document.                                                                         |
| files.billOfLading.bookingNo            | The Booking reference as extracted from the document. This is the reference provided by Issuer to the Shipper                     |
| files.billOfLading.exportReference      | The Export Reference as extracted from the document. This is the reference given by the Shipper to the Issuer                     |
| files.billOfLading.scac                 | This is the SCAC code for the issuer of the Bill of Lading                                                                        |
| files.billOfLading.isRated              | If isRated is True, then the Bill of Lading contains pricing for the transport of the goods                                       |
| files.billOfLading.isDraft              | If isDraft is True, then this Bills of Lading is a Draft version and not Final                                                    |
| files.billOfLading.importerReference    | Importer Job Ref List                                                                                                             |
| files.billOfLading.notify               | Notify List                                                                                                                       |
| files.billOfLading.shipper              ||
| files.billOfLading.consignee            ||
| files.billOfLading.carrier              ||
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
| files.billOfLading.container.containerType         ||
| files.billOfLading.container.seals         ||
| files.billOfLading.packLine.hsCode   ||
| files.billOfLading.packLine.containerNo   ||
| files.billOfLading.packLine.goodsDescription   ||
| files.billOfLading.packLine.isGoodsSegment   ||
| files.billOfLading.packLine.marksAndNumbers   ||
| files.billOfLading.packLine.numberPieces   ||
| files.billOfLading.packLine.pieceType   ||
| files.billOfLading.packLine.weight   ||
| files.billOfLading.packLine.volume   ||
| files.billOfLading.packLine.weightUnit   ||
| files.billOfLading.packLine.volumeUnit   ||

> Example of request without include parameter:
> /FileGroups/1

```json
{
  "id": 1,
  "created": "2020-05-07T15:24:47.338Z",
  "placeholderJobRef": "S00100101",
  "placeholderBillNumber": "",
  "status": 1
}
```

> Example of request with lastValidationResult and files included:
> /FileGroups/2?include=lastValidationResult,files

```json
{
  "id": 2,
  "created": "2020-05-07T15:24:47.338Z",
  "placeholderJobRef": "",
  "placeholderBillNumber": "",
  "status": 1,
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
      "fileType": 6,
    },
  ]
}
```

> Example of request with all inner objects included:
> /FileGroups/1?include=lastValidationResult,files/billOfLading/importerReference,files/billOfLading/notify,files/billOfLading/container/seals,files/billOfLading/packline

```json
{
  "id": 1,
  "created": "2020-05-07T15:24:47.338Z",
  "placeholderJobRef": "S00100101",
  "placeholderBillNumber": "",
  "status": 1,
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
      "fileType": 6,
      "billOfLading": [
        {
          "id": 111,
          "billOfLadingNo": "BOLGRP2",
          "bookingNo": "121",
          "exportReference": "REF",
          "scac": "scac",
          "isRated": true,
          "isDraft": false,
          "shipper": "ORG123",
          "shipperOrgId": 11111,
          "shipperOrgNameId": 22222,
          "shipperOrgAddressId": 121212,
          "consignee": "ORG321",
          "consigneeOrgId": 12344,
          "consigneeOrgNameId": null,
          "consigneeOrgAddressId": null,
          "carrier": "",
          "carrierOrgId": null,
          "carrierOrgNameId": null,
          "carrierOrgAddressId": null,
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
          "notify": [
            {
              "id": 211,
              "notifyParty": ""
            }
          ],
          "importerReference:": [
            { 
              "id": 322,
              "importerReference": "C0000001",
            }
          ],
          "container": [
            {
              "id": 323,
              "containerNo": "ABCD0123456",
              "containerType": "40GP",
              "seals": [
                {
                  "id": 120932,
                  "sealNo": "AB1234567"
                }
              ]
            }
          ],
          "packLine": [
            {
              "id": 1,
              "hsCode": "",
              "containerNo": "CONTAINER123",
              "goodsDescription": "",
              "isGoodsSegment": true,
              "marksAndNumbers": "",
              "numberPieces": "2",
              "pieceType": "CAS",
              "weight": 100,
              "volume": 100,
              "weightUnit": "kgs",
              "volumeUnit": "cbm"
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

## File Endpoint

### GET Original File

You can retrieve all files processed by Shipamax. For example you can retrieve a bill of lading which was send to Shipamax as an attachment to an email. Files can be retrieved via their unique ID. The response of the endpoint is a byte stream.

| Endpoint                      | Verb   | Description                                                 |
| ----------------------------- | ------ | ----------------------------------------------------------- |
| /Files/{id}/original          | GET    | Get original binary file                                    |


### POST Files/upload

You are able to upload files directly to Shipamax. The endpoint takes files as `form-data` with a key of `req`, as well as three URL parameters `customId`, `mailbox`, and `fileType` (optional). The endpoint will respond with a `JSON` object
containing information of all files successfully processed into the system.

The files will be processed as though they were attachments of a single email sent to the given Shipamax mailbox address. The mailbox settings determine whether all of the files are considered part of one group, and what kinds of files will be validated.

If the mailbox given does not exist, an error will be returned and the files will not be processed, as it would not be possible to determine settings for processing and validation.

https://public.shipamax-api.com/api/v2/Files/upload

URL Parameter Definitions

| Parameter                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| customId                                | Your unique identifier of the files, could be a uuid4 string.     |
| mailbox                                 | The mailbox address e.g. xxx@yyy.com                              |
| fileType                                | The fileType of the file(s) you are posting. **If you specify a file type with multiple files, they will all process as that type** |


> Example curl to upload files:
```shell
curl -X POST 
  -H 'Authorization: ${BEARER_TOKEN}'
  -F 'req=${FILE_LOCATION}'
  -F 'req=${FILE_LOCATION_2}'
  'https://public.shipamax-api.com/api/v2/Files/upload?customId=${CUSTOM_ID}\&mailbox=${MAILBOX}'
```

> The POST /upload endpoint responds with JSON like this:
```json
{
  "customId": "CUSTOM_ID",
  "filename": "FILE_NAME",
  "groupId": 00000,
  "id": 000000,
}
```

## Cargowise Reference Endpoint

### POST CargowiseReference/send

You are able to send Cargowise reference data (XML) directly to Shipamax. The endpoint takes the content-type as 'text/xml', and the request body as raw data. The endpoint will respond with a `text/xml`.

The Cargowise reference request will then be saved to the database as text or string('utf-8) and added to a queue to be processed later as a first come first serve basis, hence the API endpoint will mostly always return success status.
If the request is empty an error will be returned.

| Endpoint                      | Verb   | Description                                                 |
| ----------------------------- | ------ | ----------------------------------------------------------- |
| /CargowiseReferences/send     | POST   | Send Cargowise reference data                               |

Send Cargowise reference data (xml) by making a `POST` request to
`https://public.shipamax-api.com/api/v2/CargowiseReferences/send`

This endpoint can be used to send Organization/Container Number/Product Code reference data.
How to send each of these format has been explained in this document below.

**Organization data:**

You can send Organization updates either as `<UniversalInterchange>` or `<Native>` request.
XML tag `<OrgHeader>` wraps up all the organization related details such as Organization code, name, address etc..

**Following are the important tags we expect in the request:**

**OrgHeader-**
  *Code*,
  *FullName*,
  *IsActive*,
  *IsConsignee*,
  *IsConsignor*,
  *IsForwarder*,
  *IsShippingProvider*,
  *IsCompetitor*,
  *IsControllingCustomer*,
  *IsGlobalAccount*,
  *IsNationalAccount*,
  *IsPackDepot*,
  *IsPersonalEffectsAccount*,
  *IsTempAccount*,
  *IsTransportClient*,
  *IsWarehouseClient*

**OrgCompanyData-**
  *IsCreditor*,
  *IsDebtor*

**OrgAddress-**
  *CompanyNameOverride*,
  *Address1*,
  *Address2*,
  *City*,
  *PostCode*,
  *State*,
  *Phone*,
  *Mobile*,
  *Fax*,
  *Email*

**RelatedPortCode-**
  *Code*

> Example xml format when sending organization data as `<UniversalInterchange>` request:

```xml
<?xml version="1.0" encoding="utf-8"?>
<UniversalInterchange xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
  <Header>
    <SenderID>TESTSENDER</SenderID>
    <RecipientID>SHIPAMAX-ORG</RecipientID>
  </Header>
  <Body>
    <Native xmlns="http://www.cargowise.com/Schemas/Native/2011/11" version="2.0">
      <Header>
        <OwnerCode>TESTCODE</OwnerCode>
        <EnableCodeMapping>true</EnableCodeMapping>
        <nv:DataContext xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" xmlns:nv="http://www.cargowise.com/Schemas/Native/2011/11">
          <DataSourceCollection>
            <DataSource>
              <Type>Organization</Type>
              <Key>TESTCODEA</Key>
            </DataSource>
          </DataSourceCollection>
          <Company>
            <Code>MEL</Code>
            <Country>
              <Code>AU</Code>
              <Name>Australia</Name>
            </Country>
            <Name>Shipamax ltd test company</Name>
          </Company>
        </nv:DataContext>
      </Header>
      <Body>
        <Organization version="2.0">
          <OrgHeader Action="MERGE">
            <Code>TESTCODEA</Code>
            <FullName>TEST CODE HOME CO.,LTD</FullName>
            <IsForwarder>false</IsForwarder>
            <IsShippingProvider>false</IsShippingProvider>
            <IsAirWholesaler>false</IsAirWholesaler>
            <IsSeaWholesaler>false</IsSeaWholesaler>
            <IsRailProvider>false</IsRailProvider>
            <IsLineHaulProvider>false</IsLineHaulProvider>
            <IsMiscFreightServices>false</IsMiscFreightServices>
            <IsAirCTO>false</IsAirCTO>
            <IsAirLine>false</IsAirLine>
            <IsBroker>false</IsBroker>
            <IsLocalTransport>false</IsLocalTransport>
            <IsPackDepot>false</IsPackDepot>
            <IsSeaCTO>false</IsSeaCTO>
            <IsShippingLine>false</IsShippingLine>
            <IsUnpackDepot>false</IsUnpackDepot>
            <IsRailHead>false</IsRailHead>
            <IsRoadFreightDepot>false</IsRoadFreightDepot>
            <IsShippingConsortium>false</IsShippingConsortium>
            <IsFumigationContractor>false</IsFumigationContractor>
            <IsGlobalAccount>false</IsGlobalAccount>
            <IsNationalAccount>false</IsNationalAccount>
            <IsSalesLead>false</IsSalesLead>
            <IsCompetitor>false</IsCompetitor>
            <IsTempAccount>false</IsTempAccount>
            <IsPersonalEffectsAccount>false</IsPersonalEffectsAccount>
            <IsActive>true</IsActive>
            <IsConsignee>false</IsConsignee>
            <IsConsignor>true</IsConsignor>
            <IsTransportClient>false</IsTransportClient>
            <IsWarehouseClient>false</IsWarehouseClient>
            <IsContainerYard>false</IsContainerYard>
            <IsDistributionCentre>false</IsDistributionCentre>
            <IsControllingCustomer>false</IsControllingCustomer>
            <IsControllingAgent>false</IsControllingAgent>
            <OrgAddressCollection>
              <OrgAddress Action="MERGE">
                <Code>A ZONE-0933,F15, THE COMP</Code>
                <CompanyNameOverride></CompanyNameOverride>
                <Address1>TEST ADDRESS1</Address1>
                <Address2>TEST ADDRESS2</Address2>
                <City>TESTCITY</City>
                <State></State>
                <PostCode></PostCode>
                <Phone></Phone>
                <Fax></Fax>
                <Mobile></Mobile>
                <IsActive>true</IsActive>
                <Email></Email>
                <RelatedPortCode TableName="RefUNLOCO">
                  <Code>CNFZH</Code>
                  <PK>a47bc3d1-cf72-4ad9-a538-e3c4poklhnk</PK>
                </RelatedPortCode>
                <CountryCode TableName="RefCountry">
                  <Code>CN</Code>
                  <PK>21eaa7e3-9009-4e17-9d96-f72d36iloko</PK>
                </CountryCode>
              </OrgAddress>
            </OrgAddressCollection>
            <OrgCompanyDataCollection>
              <OrgCompanyData Action="MERGE">
                <PK>142dc66e-e946-4ffa-95a5-4c5ikikiplo</PK>
                <IsDebtor>false</IsDebtor>
                <IsCreditor>false</IsCreditor>
              </OrgCompanyData>
            </OrgCompanyDataCollection>
            <ShippingLine TableName="RefShippingLine" />
          </OrgHeader>
        </Organization>
      </Body>
    </Native>
  </Body>
</UniversalInterchange>
```

> Example xml format when sending organisation data as a `<Native>` request:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Native   version="2.0" xmlns="http://www.cargowise.com/Schemas/Native/2011/11">
  <Header />
  <Body>
    <Organization version="2.0">
      <OrgHeader Action="MERGE">
        <PK>3d83ccfc-f909-4504-a89e-7def197b73b8</PK>
        <Code>EXAMPLECODE</Code>
        <FullName>EXAMPLEFULLNAME</FullName>
        <IsForwarder>false</IsForwarder>
        <IsShippingProvider>true</IsShippingProvider>
        <IsConsignee>true</IsConsignee>
        <IsConsignor>true</IsConsignor>
        <OrgAddressCollection>
          <OrgAddress Action="MERGE">
            <PK>d8583f8c-1408-4c05-8498-efb171e3ce63</PK>
            <CompanyNameOverride>EXAMPLE COMPANY ECNO</CompanyNameOverride>
            <Address1>EXAMPLE ADDRESS A</Address1>
            <Address2>EXAMPLE ADDRESS B</Address2>
            <City>MIDDLESEX</City>
            <State>HNS</State>
            <PostCode>TW6 3JS</PostCode>
            <Phone></Phone>
            <Fax />
            <Mobile />
            <IsActive>true</IsActive>
            <Email>exampleemail@test.com</Email>
            <RelatedPortCode TableName="ExampleUNLOCO">
              <Code />
            </RelatedPortCode>
            <CountryCode TableName="ExampleCountry">
              <Code>GB</Code>
            </CountryCode>
          </OrgAddress>
        </OrgAddressCollection>
        <OrgCompanyDataCollection>
          <OrgCompanyData Action="MERGE">
            <APCategory />
            <APPaymentTermDays>0</APPaymentTermDays>
            <APPaymentTerms>COD</APPaymentTerms>
            <ARConsolidatedAccountingCategory />
            <IsDebtor>false</IsDebtor>
            <IsCreditor>true</IsCreditor>
            <APCreditorGroup TableName="OrgCreditorGroup">
              <Code>AIR</Code>
            </APCreditorGroup>
            <ControllingBranch TableName="GlbBranch">
              <Code>LHR</Code>
            </ControllingBranch>
            <GlbCompany>
              <Code>LHR</Code>
            </GlbCompany>
            <APDefltCurrency TableName="RefCurrency">
              <Code>GBP</Code>
            </APDefltCurrency>
          </OrgCompanyData>
        </OrgCompanyDataCollection>
      </OrgHeader>
    </Organization>
  </Body>
</Native>
```

**Container reference data:**

This is a `<UniversalInterchange>` request.
XML tag `<UniversalShipment>` wraps up all the container reference data,
You can specify multiple containers by repeating the `<Container>` XML tag.
Similarly, multiple shipments can be specified by repeating `<SubShipment>` XML tag.

**Following are the important tags we expect in the request:**

**DataSource-**
  *Key*

**Container-**
  *ContainerNumber*

**TransportLeg-**
  *EstimatedArrival*

> Example xml format when sending Container reference data:

```xml
<?xml version="1.0" encoding="utf-8"?>
<UniversalInterchange xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
  <Header>
    <SenderID>SEIMANHAM</SenderID>
    <RecipientID>SEIHAMHAM</RecipientID>
  </Header>
  <Body>
    <UniversalShipment xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
      <Shipment>
        <DataContext>
          <DataSourceCollection>
            <DataSource>
              <Type>ForwardingConsol</Type>
              <Key>C20SMAN00023684</Key>
            </DataSource>
          </DataSourceCollection>
        </DataContext>
        <ContainerCount>3</ContainerCount>
        <ContainerMode>
          <Code>FCL</Code>
          <Description>Full Container Load</Description>
        </ContainerMode>
        <ContainerCollection Content="Complete">
          <Container>
            <ContainerCount>1</ContainerCount>
            <ContainerNumber>HLBU2734800</ContainerNumber>
          </Container>
        </ContainerCollection>
        <SubShipmentCollection>
          <SubShipment>
            <DataContext>
              <DataSourceCollection>
                <DataSource>
                  <Type>ForwardingShipment</Type>
                  <Key>S20SMAN0026986</Key>
                </DataSource>
                <DataSource>
                  <Type>CustomsDeclaration</Type>
                  <Key>S20SMAN0026986</Key>
                </DataSource>
              </DataSourceCollection>
            </DataContext>
            <ContainerCount>1</ContainerCount>
            <ContainerMode>
              <Code>FCL</Code>
              <Description>Full Container Load</Description>
            </ContainerMode>
            <ContainerCollection>
              <Container>
                <ContainerCount>1</ContainerCount>
                <ContainerNumber>HLBU2734800</ContainerNumber>
              </Container>
            </ContainerCollection>
          </SubShipment>
        </SubShipmentCollection>
        <TransportLegCollection Content="Complete">
          <TransportLeg>
            <EstimatedArrival>2021-02-16T15:00:00</EstimatedArrival>
          </TransportLeg>
        </TransportLegCollection>
      </Shipment>
    </UniversalShipment>
  </Body>
</UniversalInterchange>
```

**Product code data:**

This is a `<XmlInterchange>` request.
XML tag `<Products>` wraps up all the product code related data.

**Following are the important tags we expect in the request:**

**Product-**
  *ProductCode*,
  *ProductDescription*,
  *StockUnit*

**RelatedOrganisation-**
  *OwnerCode*,
  *RelationshipType*

> Example xml format when sending product code data:

```xml
<?xml version="1.0" encoding="utf-8"?>
<XmlInterchange xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Version="1" xmlns="http://www.edi.com.au/EnterpriseService/">
  <InterchangeInfo>
    <Date>2021-02-22T16:23:54.063+11:00</Date>
    <XmlType>Verbose</XmlType>
    <Target />
  </InterchangeInfo>
  <Payload>
    <Products>
      <Product>
        <ProductCode>TESTCODE</ProductCode>
        <ProductDescription>DESCRIPTION</ProductDescription>
        <StockUnit>UNT</StockUnit>
        <RelatedOrganisations>
          <RelatedOrganisation>
            <Organisation EDICode="OWNERCODE" OwnerCode="OWNERCODE">
              <OrganisationDetails>
                <Name>OWNER NAME</Name>
                <Location Country="Australia" City="Melbourne">LOC</Location>
                <Addresses>
                  <Address AddressType="MAIN">
                    <AddressLine1>OWNER</AddressLine1>
                    <AddressCode>OWNER</AddressCode>
                    <CityOrSuburb>MELBOURNE</CityOrSuburb>
                    <StateOrProvince>VIC</StateOrProvince>
                    <PostCode>1000</PostCode>
                    <TelephoneNumbers>
                      <TelephoneNumber NumberType="Business">+6</TelephoneNumber>
                      <TelephoneNumber NumberType="Fax">+6</TelephoneNumber>
                    </TelephoneNumbers>
                    <Email>email@email.com</Email>
                    <Language>EN</Language>
                    <Location>AUMEL</Location>
                    <Sequence>1</Sequence>
                    <AddressCapabilities>
                      <AddressCapability AddressType="MAIN" />
                      <AddressCapability IsMainAddress="true" AddressType="APM" />
                      <AddressCapability IsMainAddress="true" AddressType="ARM" />
                      <AddressCapability IsMainAddress="true" AddressType="OFC" />
                      <AddressCapability IsMainAddress="true" AddressType="PST" />
                    </AddressCapabilities>
                  </Address>
                </Addresses>
              </OrganisationDetails>
            </Organisation>
            <RelationshipType>OWN</RelationshipType>
            <RFAttributeConfirm>NON</RFAttributeConfirm>
          </RelatedOrganisation>
          <RelatedOrganisation>
            <Organisation EDICode="SUPPLIERCODE" OwnerCode="SUPPLIERCODE">
              <OrganisationDetails>
                <Name>SUPPLIER NAME</Name>
                <Location Country="Japan" City="Osaka">LOC</Location>
                <Addresses>
                  <Address AddressType="MAIN">
                    <AddressLine1>SUPPLIER</AddressLine1>
                    <AddressCode>SUPPLIER</AddressCode>
                    <CityOrSuburb>TOKYO</CityOrSuburb>
                    <StateOrProvince>00</StateOrProvince>
                    <PostCode>100-0000</PostCode>
                    <Language>EN</Language>
                    <Location>JPOSA</Location>
                    <Sequence>1</Sequence>
                    <AddressCapabilities>
                      <AddressCapability AddressType="MAIN" />
                      <AddressCapability IsMainAddress="true" AddressType="OFC" />
                    </AddressCapabilities>
                  </Address>
                </Addresses>
              </OrganisationDetails>
            </Organisation>
            <RelationshipType>SUP</RelationshipType>
            <RFAttributeConfirm>NON</RFAttributeConfirm>
          </RelatedOrganisation>
        </RelatedOrganisations>
        <DimensionDetails />
        <ClientDefinedDetails />
        <BasicStockControl />
      </Product>
    </Products>
  </Payload>
</XmlInterchange>
```

Cragowise Reference endpoint can also accept SOAP message which is a Cargowise default i.e, Request that starts with tag <s: Envelope>, Or 
you can also take the message encoded within the SOAP message and post it as a request to the Cargowise reference endpoint.

> Example xml format when sending SOAP message:

```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <s:Header>
    <h:SendStreamRequestTrackingID xmlns:h="http://CargoWise.com/eHub/2010/06">8c5e5518-b1b4-4c4e-8c23-14970e00ea0e</h:SendStreamRequestTrackingID>
    <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <u:Timestamp u:Id="_0">
        <u:Created>2021-02-17T02:01:43.892Z</u:Created>
        <u:Expires>2021-02-17T02:06:43.892Z</u:Expires>
      </u:Timestamp>
      <o:UsernameToken u:Id="uuid-d93a127c-7214-4dee-859c-c65971b01e12-19">
        <o:Username>ACPBNEBNE</o:Username>
        <o:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">139621</o:Password>
      </o:UsernameToken>
    </o:Security>
  </s:Header>
  <s:Body>
    <SendStreamRequest xmlns="http://CargoWise.com/eHub/2010/06">
      <Payload>
        <Message ApplicationCode="NDM" ClientID="ShipaMax" TrackingID="ef098bf8-c27f-469e-8d5f-9eb89842ac18" SchemaName="http://www.cargowise.com/Schemas/Native" SchemaType="Xml" EmailSubject="" FileName="">
                    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
        </Message>
      </Payload>
    </SendStreamRequest>
  </s:Body>
</s:Envelope>
```

> The POST /send endpoint responds with data as 'text/xml' like this

```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
        <s:Header>
          <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
            <u:Timestamp u:Id="_0">
              <u:Created>currentDate</u:Created>
              <u:Expires>ExpirationDate</u:Expires>
            </u:Timestamp>
          </o:Security>
        </s:Header>
        <s:Body/>
      </s:Envelope>
```

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

### List of FileType values
| Code         | Description
| ------------ | ------------------------------ |
| 0            | Miscellaneous                  |
| 1            | Bill of Lading                 |
| 2            | Arrival Notice                 |
| 3            | Delivery Order                 |
| 4            | Payables Invoice               |
| 5            | Commercial Invoice             |
| 6            | Master Bill of Lading          |
| 7            | House Bill of Lading           |
| 8            | Packing List                   |
| 9            | Packing Declaration            |
| 10           | Certificate of Origin          |
| 1000         | Multiple documents in one file |

### List of Group status
| Code         | Description
| ------------ | ------------------ |
| 1            | Unposted           |
| 2            | Discarded          |
| 3            | Posted             |
| 4            | Out Of Sync        |
| 5            | Done               |
