---
title: Shipamax Freight Forwarding API Reference

toc_footers:
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>


search: true
---

# Getting started


The Shipmax API enables developers to integrate Shipamax's data extraction and process automation modules into their systems. 

Currently the API supports:

- Data extraction from:
  + Commercial Invoices
  + Ocean Bills of Lading 
  + Accounts Payable Invoices
- Process automation for:
  + Accounts Payables Reconciliation
  + Job building (Shipments, Consols, Brokerage)
  + Declaration building 

If you would like to use this API and are not already a Shipamax customer, please contact our [support team](mailto:support@shipamax.com).


## Requirements

1. You will need an access token to authenticate your requests.
2. You will need to share your webhook endpoint with Shipamax in order to receive notifications of new results.
3. You will need the Shipamax team to have configured a mailbox for your use case. This is how Shipamax configures what happens when you send documents into the system and as such is required whether you provide docs via API or email. 

Please contact your Shipamax Customer Success Manager to arrange the above or our [support team](mailto:support@shipamax.com).

## Workflow
When you send in Files, Shipamax will process them according to a predefined workflow for your use case. 

In general, the system will use webhooks to notify you when the Files have reached certain milestones and then the API is available for you to query the results. 

Ask your CSM for use case specific guides on integrating with Shipamax. 


## API basics

The API is [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_Web_services), and messages are encoded as JSON documents

### Endpoint

The base URI for all API endpoints is `https://public.shipamax-api.com/api/v2/`.

### Content type

Unless specified otherwise, requests with a body attached should be sent with a `Content-Type: application/json` HTTP header.

## Authorization

All API methods require you to be authenticated. This is done using an access token which will be given to you by the Shipamax team.

This access token should be sent in the header of all API requests you make. If your access token was `abc123token`, you would send it as the HTTP header `Authorization: Bearer abc123token`.

## Long-term support and versioning

Shipamax aims to be a partner to our customers, this means continuously improving everything including our APIs. However, this does mean that APIs can only be supported for a given timeframe. We aim to honour the expected End-Of-Life, but in case this is not possible we will work with our customers to find a solution.  
  
Version: v1  
Launch: April 2020  
Expected End-Of-Live: March 2023  

# Webhooks 
## Event Webhooks

The webhooks will be triggered when Files reach certain milestones. Currently you are required to manually provide Shipamax with the destination URL which the webhooks should call.

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
| ClusteringComplete                          | Clustering completed                       |
| ParsingComplete                             | Parsing completed                          |


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

# Reference

## FileGroups Endpoint

Shipamax groups files that are associated with each other into a FileGroup. For example, you may have received a Master BL with associated House BLs and these will be contained within the same FileGroup.
​
A FileGroup is a collection of Files which may contain a BillOfLading entity. The following endpoint is available.

| Endpoint                    | Verb | Description                                                 |
| --------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroups/{file_group_id}            | GET  | Get File group details using the group's ID                 |

Get a FileGroup by making a `GET` request to `https://public.shipamax-api.com/api/v2/FileGroups/{file_group_id}`

### URL Parameter Definitions

| Parameter                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| include                                 | List of inner objects to include in the returned FileGroup        |

### Available objects 
The following objects can be used as parameters in the *include* query

| Value                                   |  Description                                                       |
| --------------------------------------- | ------------------------------------------------------------------ |
| files                                   | List of all files in the group                                     |
| lastValidationResult                    | The results of the last validation performed on the group          |
| files/billOfLading                      | Details of the group's Bill of Ladings                             |
| files/billOfLading/importerReference    | The list of external references associated with the Bill of Lading |
| files/billOfLading/notify               | Details of the Notify party on the Bill of Lading                  |
| files/billOfLading/container            | List of containers associated with the Bill of Lading              |
| files/billOfLading/container/seals      | List of seals for each container                                   |
| files/billOfLading/packline             | List of packing lines associated with the Bill of Lading           |
| files/commercialInvoice                 | Details of the group's Commercial Invoices                         |
| files/commercialInvoice/lineItem        | List of line items associated with the Commercial Invoice          |



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
          "shipperCode": string,
          "shipperOrgId": integer,
          "shipperOrgNameId": integer,
          "shipperOrgName": string,
          "shipperOrgAddressId": integer,
          "shipperOrgAddress": string,
          "consignee": string,
          "consigneeCode": string,
          "consigneeOrgId": integer,
          "consigneeOrgNameId": integer,
          "consigneeOrgName": string,
          "consigneeOrgAddressId": integer,
          "consigneeOrgAddress": string,
          "carrier": string,
          "carrierCode": string,
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
          "origin": string,
          "originUnlocode": string,
          "destination": string,
          "destinationUnlocode": string,
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
              "notifyParty": String,
              "notifyPartyCode": String,
              "notifyPartyOrgId": integer,
              "notifyPartyOrgNameId":integer,
              "notifyPartyOrgName":string,
              "notifyPartyOrgAddressId": integer,
              "notifyPartyOrgAddress": string
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
              "numberPieces": integer,
              "pieceType": string,
              "weight": float,
              "volume": float,
              "weightUnit": string,
              "volumeUnit": string
            }
          ]
        }
      ],
      "commercialInvoice": [
                {
                    "supplier": string,
                    "supplierCode": string,
                    "supplierOrgId": integer,
                    "supplierOrgNameId": integer,
                    "supplierOrgName": string,
                    "supplierOrgAddressId": integer,
                    "supplierOrgAddress": string,
                    "importer": string,
                    "importerCode": string,
                    "importerOrgId": integer,
                    "importerOrgNameId": integer,
                    "importerOrgName": string,
                    "importerOrgAddressId": integer,
                    "importerOrgAddress": string,
                    "invoiceNumber": string,
                    "invoiceDate": string,
                    "invoiceGrossTotal": float,
                    "netTotal": float,
                    "currency": string,
                    "incoTerm": string,
                    "id": integer,
                    "lineItem": [
                        {
                            "description": string,
                            "quantity": integer,
                            "unitPrice": float,
                            "lineTotal": float,
                            "unitType": string,
                            "productCode": string,
                            "origin": string,
                            "productCodeMatch": boolean,
                            "HsCode": string,
                            "id": integer,
                            "orderIndex": integer,
                            "descriptionCell": string,
                        }
                    ]
                }
            ]
    }
  ]
}
```

### *FileGroup* root attributes
| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| placeholderJobRef                       | A reference ID in an external system you would like to associate the Group with (manually added)                                  |
| placeholderBillNumber                   | An existing MBL ID you would like to associate this Group with (manually added)                                                   |
| status                                  | Status of the group in the shipamax flow. Possible values can be seen in our [list of group status](#list-of-group-status)        |

### *ValidationResults* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| lastValidationResult                    | The result of the most recent validation                                                                                          |
| lastValidationResult.isSuccess          | If validation was successful this flag will be true. If not, false.                                                               |
| lastValidationResult.details            | Further detail on the type of exception                                                                                           |
| lastValidationResult.details.validator  | Shipamax has multiple validators for different workflows and integrations. This specifies from which validator issued this result |
| lastValidationResult.details.exceptions | The list of exceptions that caused validation to fail. Possible values can be seen in our [list of exceptions](#list-of-exceptioncode-values)     |

### *Files* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files                                   | List of files within the FileGroup                                                                                                |
| files.filename                          | The name of the file as received within the email                                                                                 |
| files.fileType                          | The type of the file as received within the email. Possible values can be seen in our [list of file types](#list-of-filetype-values)   |

### *Files/billOfLading* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files.billOfLading                      | An array of bills of lading extracted from this file, if any.                                                                     |
| files.billOfLading.billOfLadingNo       | The Bill of Lading number as extracted from the document.                                                                         |
| files.billOfLading.bookingNo            | The Booking reference extracted from the bill of lading. This is the reference provided by Issuer to the Shipper (also known as Carrier Reference).   |
| files.billOfLading.exportReference      | The Export Reference as extracted from the document. This is the reference given by the Shipper to the Issuer                     |
| files.billOfLading.scac                 | This is the SCAC code for the issuer of the Bill of Lading                                                                        |
| files.billOfLading.isRated              | If isRated is True, then the Bill of Lading contains pricing for the transport of the goods                                       |
| files.billOfLading.isDraft              | If isDraft is True, then this Bills of Lading is a Draft version and not Final                                                    |
| files.billOfLading.importerReference    | Importer Job Ref List                                                                                                             |
| files.billOfLading.shipper              | The raw data extracted for the Shipper field from the bill of lading file                                                         |
| files.billOfLading.shipperCode          | The code for the selected Shipper (as it appears in the Exception Manager UI, taken from your Organization data)                                                       |
| files.billOfLading.shipperOrgId         | The internal ID of the selected Shipper                                                         |
| files.billOfLading.shipperOrgNameId     | The internal ID of the selected name of the Shipper                                                        |
| files.billOfLading.shipperOrgAddressId  | The internal ID of the selected address of the Shipper                                                            |
| files.billOfLading.shipperOrgName       | The selected name of the Shipper                                                        |
| files.billOfLading.shipperOrgAddress    | The selected address of the Shipper                                                            |
| files.billOfLading.consignee            | The raw data extracted for the Consignee field from the bill of lading file                                                                                                                                     |
| files.billOfLading.consigneeCode          | The code for the selected Consignee (as it appears in the Exception Manager UI, taken from your Organization data)                                                       |
| files.billOfLading.consigneeOrgId         | The internal ID of the selected Consignee                                                         |
| files.billOfLading.consigneeOrgNameId     | The internal ID of the selected name of the Consignee                                                        |
| files.billOfLading.consigneeOrgAddressId  | The internal ID of the selected Address of the Consignee                                                            |
| files.billOfLading.consigneeOrgName     | The selected name of the Consignee                                                        |
| files.billOfLading.consigneeOrgAddress  | The selected Address of the Consignee                                                            |
| files.billOfLading.carrier              | The raw data extracted for the Carrier field from the bill of lading file                                                                                                                                     |
| files.billOfLading.carrierCode          | The code for the selected Carrier (as it appears in the Exception Manager UI, taken from your Organization data)                                                       |
| files.billOfLading.carrierOrgId         | The internal ID of the selected Carrier                                                         |
| files.billOfLading.carrierOrgNameId     | The internal ID of the selected name of the Carrier                                                        |
| files.billOfLading.carrierOrgAddressId  | The internal ID of the selected Address of the Carrier                                                            |
| files.billOfLading.vessel               | The name of the Vessel                                                                                                                                |
| files.billOfLading.vesselIMO            | The IMO code matching the Vessel name                                                                                                                                  |
| files.billOfLading.voyageNumber         | The number of the Voyage                                                                                                                            |
| files.billOfLading.loadPort             | The name of the Loading Port                                                                                                                                  |
| files.billOfLading.loadPortUnlocode     | The UNL code matching the Load Port name                                                                                                                                 |
| files.billOfLading.dischargePort        | The name of the Discharge Port                                                                                                                                 |
| files.billOfLading.dischargePortUnlocode| The UNL code matching the Discharge Port name                                                                                                                                   |
| files.billOfLading.origin               | The Origin Port                                                                                                                                   |
| files.billOfLading.originUnlocode       | The UNL code matching the Origin name                                                                                                                                   |
| files.billOfLading.destination          | The Destination Port                                                                                                                                   |
| files.billOfLading.destinationUnlocode  | The UNL code matching the Destination name                                                                                                                                   |
| files.billOfLading.shippedOnBoardDate   | The date the cargo has been loaded on the vessel (SOB date)                                                                                                                                 |
| files.billOfLading.paymentTerms         | The paymebt terms. See [List of Payment Terms] (#List-of-PaymentTerm-values) for possible values                                                                                                                               |
| files.billOfLading.category             | Type of Bill of lading ("True" = Master)                                                                                                                                  |
| files.billOfLading.releaseType          | The Release Type for this shipment. See [List of Release Types](#List-of-ReleaseType-values) for possible values                                                                                                                               |
| files.billOfLading.goodsDescription     | Textual description of the goods                                                                                                                                 |
| files.billOfLading.transportMode        | The transport type of this shipment. See [List of Transport Modes](#List-of-TransportMode-values) for possible values                                                                                                                                  |
| files.billOfLading.containerMode        | The Container's mode. See [List of Container Modes](#List-of-ContainerMode-values) for possible values                                                                                                                                  |

### *Files/billOfLading/Container* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files.billOfLading.container.containerNo | The container number                                                                           |
| files.billOfLading.container.containerType | The container type. Possible values for this list [List of ContainerType values](#list-of-containertype-values) |
| files.billOfLading.container.seals         | List of seals included in the container                                                                                        |

### *Files/billOfLading/packLine* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files.billOfLading.packLine.containerNo | The container number the packing line is stored in                                                                                |
| files.billOfLading.packLine.packageCount | The number of pieces (or packages) in this pack line                                                                             |
| files.billOfLading.packLine.packageType | The package's type. For list of possible values, see [List of PackageType values](#list-of-packagetype-values)                    |
| files.billOfLading.packLine.weight      | The package's Weight                                                                                                                                 |
| files.billOfLading.packLine.volume      | The package's Volume                                                                                                                                  |The package's Weight  
| files.billOfLading.packLine.weightUnit  | The weight units used. Supported values are: 'kg', 't' |
| files.billOfLading.packLine.volumeUnit  | The volume units used. Supported values are: 'm^3'                                                                                                                                |

### *Files/billOfLading/notify* attributes
A Bill of Lading can have several Notify party.


| Attribute                               | Description                                                         |
| --------------------------------------- | ------------------------------------------------------------------- |
| files.billOfLading.notify.id            | The NotifyParty object ID      |
| files.billOfLading.notify.notifyParty   | The raw data extracted for the Notify Party field from the bill of lading file  |
| files.billOfLading.notify.notifyPartyCode | The code for the selected Notify Party  (as it appears in the Exception Manager UI, taken from your Organization data) |
| files.billOfLading.notify.notifyPartyOrgId           |  The internal ID of the selected Notify Party           |
| files.billOfLading.notify.notifyPartyOrgNameId            | The internal ID of the selected Name of the Notify Party |
| files.billOfLading.notify.notifyPartyOregAddressId            |   The internal ID of the Address of the selected Notify Party           |
| files.billOfLading.notify.notifyPartyOrgName            | The selected Name of the Notify Party |
| files.billOfLading.notify.notifyPartyOregAddress            |   The Address of the selected Notify Party           |

### *Files/commercialInvoice* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files.commercialInvoice                      | An array of commercial invoices extracted from this file, if any.                                                                     |
| files.commercialInvoice.id       | The internal ID of the commercial invoice.                                                                         |
| files.commercialInvoice.supplier            | The raw data extracted for the supplier field from the commercial invoice file.   |
| files.commercialInvoice.supplierCode      | The code for the selected supplier (as it appears in the Exception Manager UI) taken from your Organization data.                   |
| files.commercialInvoice.supplierOrgId                 | The internal ID of the selected supplier.                                               |
| files.commercialInvoice.supplierOrgNameId              | The internal ID of the selected name of the supplier.                              |
| files.commercialInvoice.supplierOrgAddressId              | The internal ID of the selected Address of the supplier.                                                   |
| files.commercialInvoice.supplierOrgName              | The selected name of the supplier.                              |
| files.commercialInvoice.supplierOrgAddress              | The selected Address of the supplier.                                                   |
| files.commercialInvoice.importer    | The raw data extracted for the importer field from the commercial invoice  file.                                                                                          |
| files.commercialInvoice.importerCode              | The code for the selected importer (as it appears in the Exception Manager UI), taken from your Organization data.                                                         |
| files.commercialInvoice.importerOrgId          | The internal ID of the selected importer.                                           |
| files.commercialInvoice.importerOrgNameId         | The internal ID of the selected name of the importer.                                                    |
| files.commercialInvoice.importerOrgAddressId     | The internal ID of the selected Address of the importer.                                   |
| files.commercialInvoice.importerOrgName         | The selected name of the importer.                                                    |
| files.commercialInvoice.importerOrgAddress     | The selected Address of the importer.                                   |
| files.commercialInvoice.invoiceNumber  | The commercial invoice number.                                             |
| files.commercialInvoice.invoiceDate            | The commercial invoice date.                                                  |
| files.commercialInvoice.invoiceGrossTotal          | The commercial invoice’s total amount.                                 |
| files.commercialInvoice.netTotal         | The commercial invoice's net total.                                                        |
| files.commercialInvoice.currency     | The currency used in the commercial invoice.                                           |
| files.commercialInvoice.incoTerm  | The commercial invoice incoterm.                                                     |

### *Files/commercialInvoice/lineItem* attributes

| Attribute                            | Description                               |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------  |
| files.commercialInvoice.lineItem.id            | The internal ID of the line item.   |
| files.commercialInvoice.lineItem.description            | The line item description.     |
| files.commercialInvoice.lineItem.quantity           | The number of units included in the line item.           |
| files.commercialInvoice.lineItem.unitPrice           |  The price of a single unit in the line item.              |
| files.commercialInvoice.lineItem.lineTotal            | The total amount of the line item.         |
| files.commercialInvoice.lineItem.unitType            |  The type of the unit in the line item.            |
| files.commercialInvoice.lineItem.productCode            | The code for the product in the line item.        |
| files.commercialInvoice.lineItem.origin            |  The origin country of the unit in the line item            |
| files.commercialInvoice.lineItem.productCodeMatch            |   Indicate if the product code extracted matched a code taken from your product code data.       |
| files.commercialInvoice.lineItem.hsCode            |   The HS Code of this line item.             |
| files.commercialInvoice.lineItem.matchedProductCode            | The product taken from your product data, if there was a match (productCodeMatch = true).        |
| files.commercialInvoice.lineItem.matchedDescription            | The description taken from your product data, if there was a match.     |
| files.commercialInvoice.lineItem.matchedOriginCountryCode            |  The origin country of the unit taken from your product data, if there was a match.           |
| files.commercialInvoice.lineItem.matchedUnitType            |  The type of the unit taken from your product data, if there was a match.            |
| files.commercialInvoice.lineItem.orderIndex            |  The index of the line, representing the order of it within the commercial invoice..            |
| files.commercialInvoice.lineItem.descriptionCell            |  The entire cell of the line item description.          |

### *Files/apInvoice* attributes

| Attribute                            | Description                               |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------  |
| files.apInvoice.addressee            | The raw data extracted for the addressee field from the invoice.                   |
| files.apInvoice.addresseeCode            | The code for the selected addressee (as it appears in the Exception Manager UI) taken from your Organization data.      |
| files.apInvoice.issuer           | The raw data extracted for the issuer field from the invoice.       |
| files.apInvoice.issuerCode           | The code for the selected issuer (as it appears in the Exception Manager UI) taken from your Organization data.        |
| files.apInvoice.invoiceNumber            | The invoice number.                    |
| files.apInvoice.invoiceDate            |  The invoice date            |
| files.apInvoice.grossTotal            | The invoice's gross total.        |
| files.apInvoice.netTotal            |  The invoice's net total.            |
| files.apInvoice.vatTotal            |   The invoice's total VAT.       |
| files.apInvoice.currency            |   The currency of the invoice.             |
| files.apInvoice.currencyId            |  The internal ID of the currency of the invoice.             |
| files.apInvoice.validationResultId            |   The internal ID of the last validation result.             |
| files.apInvoice.reassignTime            |   The timestamp of when this invoice was last reassigned.             |
| files.apInvoice.email            |   The email for this invoice.             |
| files.apInvoice.website            |   The website for this invoice.             |
| files.apInvoice.issuerRecordId            |  A composite internal ID for the selected issuer, name and address.             |
| files.apInvoice.glCode            |   The general ledger code of this invoice.            |
| files.apInvoice.description            |   The description of the invoice.            |
| files.apInvoice.departmentCode            |  The department code of this invoice.             |
| files.apInvoice.branchCountry            |   The branch country of this invoice.             |

### *Files/email* attributes

| Attribute                            | Description                               |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------  |
| files.email.customId           | The custom ID associated with this email.                   |
| files.email.emailAccountId            | The internal ID for the email account this was sent to.      |
| files.email.sender           | The sender of the email.       |
| files.email.created           | The date this was created in Shipamax.        |
| files.email.attachmentCount            | The number of attachments this email had.                  |
| files.email.companyId           | Your internal company ID.     |
| files.email.subject          | The subject of this email.        |
| files.email.unqId            | The internal unique ID of this email.                 |

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
> /FileGroups/1?include=lastValidationResult,files/billOfLading/importerReference,files/billOfLading/notify,
> files/billOfLading/container/seals,files/billOfLading/packline
> files/commercialInvoice,files/commercialInvoice/lineItem,files/apInvoice,files/email

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
      "email": {
        "customId": "custom001",
        "emailAccountId": 1,
        "sender": "test@shipamax.com",
        "created": "2020-05-07T15:24:47.338Z",
        "attachmentCount": 1,
        "companyId": 100000,
        "subject": "Sending file",
        "unqId": "6f847a63-bd99-4b79-965c-128ea9b3f104"
      },
      "apInvoice": [
        {
          "addressee": "PARSED VALUE ADDRESSEE",
          "addresseeCode": "ADDCODE",
          "issuer": "PARSED VALUE ISSUER",
          "issuerCode": "ISSCODE",
          "invoiceNumber": "ABC12345",
          "invoiceDate": "2020-07-03",
          "invoiceGrossTotal": 2607.92,
          "netTotal": 2600.00,
          "vatTotal": 7.92,
          "currency": "GBP",
          "currencyId": 826,
          "validationResultId": 1,
          "teamId": 1,
          "previousTeamId": 2,
          "reasssignTime": "2020-07-03",
          "email": "invoice@invoice.com",
          "website": "www.invoice.com",
          "issuerRecordId": "1-1-1",
          "glCode": "1300.00.00",
          "description": "This is an invoice",
          "departmentCode": "DEPTCODE",
          "branchCountry": "Lithuania"
        }
      ]
      "billOfLading": [
        {
          "id": 111,
          "billOfLadingNo": "BOLGRP2",
          "bookingNo": "121",
          "exportReference": "REF",
          "scac": "scac",
          "isRated": true,
          "isDraft": false,
          "shipper": "PARSED VALUE",
          "shipperCode": "ORG123",
          "shipperOrgId": 11111,
          "shipperOrgNameId": 22222,
          "shipperOrgAddressId": 121212,
          "consignee": "PARSED VALUE ORG321",
          "consigneeCode": "ORG321",
          "consigneeOrgId": 12344,
          "consigneeOrgNameId": null,
          "consigneeOrgAddressId": null,
          "carrier": "",
          "carrierCode": null,
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
          "origin": "",
          "originUnlocode": "",
          "destination": "",
          "destinationUnlocode": "",
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
              "notifyParty": "",
              "notifyPartyCode": "TEST123",
              "notifyPartyOrgId": 11121,
              "notifyPartyOrgNameId": 22133,
              "notifyPartyOrgAddressId": 12312,
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
              "numberPieces": 2,
              "pieceType": "CAS",
              "weight": 100,
              "volume": 100,
              "weightUnit": "kgs",
              "volumeUnit": "cbm"
            }
          ]
        }
      ],
      "commercialInvoice": [
                {
                    "supplier": "PARSED VALUE",
                    "supplierCode": "CODE",
                    "supplierOrgId": 1,
                    "supplierOrgNameId": 1,
                    "supplierOrgAddressId": 1,
                    "importer": "PARSEDVALUE",
                    "importerCode": "CODE",
                    "importerOrgId": 1,
                    "importerOrgNameId": 1,
                    "importerOrgAddressId": 1,
                    "invoiceNumber": "ABC12345",
                    "invoiceDate": "2020-07-03",
                    "invoiceGrossTotal": 2607.92,
                    "netTotal": 2607.92,
                    "currency": "USD",
                    "incoTerm": "FCA",
                    "id": 1,
                    "lineItem": [
                        {
                            "description": "ITEM DESCRIPTION",
                            "quantity": 10,
                            "unitPrice": 24.95,
                            "lineTotal": 199.6,
                            "unitType": "NO",
                            "productCode": null,
                            "origin": "MX",
                            "productCodeMatch": false,
                            "HsCode": "1234567890",
                            "id": 1,
                            "orderIndex": 0,
                            "descriptionCell": "ITEM DESCRTIPTION 1"
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
  https://public.shipamax-api.com/api/v2/FileGroups/{file_group_id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {TOKEN}"
```

## ClusterScore Endpoint
Get the clustering score of documents in a given file group.

The endpoint will only return the score of documents that was received via a mailbox which supports the clustering workflow.

The following endpoint is currently available:

| Endpoint                         | Verb  | Description                                                                       |
| -------------------------------- | ----- | --------------------------------------------------------------------------------- |
| /FileGroups/{file_group_id}/clusterScore | GET | Retrieve the clustering score of document with the given document group ID  |

Send a request via `GET` to `https://public.shipamax-api.com/api/v2/FileGroups/{file_group_id}/clusterScore`.

> **Example:** GET ClusterScore returns an array of scores for documents in that group, like this:

```json
[{
  "id": 1,
  "clusterConfidenceScore": 0.1,
  "descMin": 0.1,
  "descFirstQtl": 0.2,
  "descMedian": 0.4,
  "descThirdQtl": 0.3,
  "descMax": 0.3,
  "liMin": 0.7,
  "liFirstQtl": 0.8,
  "liMedian": 0.8,
  "liThirdQtl": 0.9,
  "liMax": 1.0,
}]
```

## Parse Endpoint
It is possible to trigger the parsing of a document that already exists in Shipamax via API.

The following endpoint is currently available:

| Endpoint                         | Verb  | Description                                                                       |
| -------------------------------- | ----- | --------------------------------------------------------------------------------- |
| /FileGroups/{file_group_id}/parse | POST | Trigger the parsing of the document group with the given ID. |

Send a request via `POST` to `https://public.shipamax-api.com/api/v2/FileGroups/{file_group_id}/parse`.

> The POST /parse endpoint responds with JSON like this:
```json
[{
  "filename": "FILE_NAME",
  "groupId": 00000,
  "id": 000000,
}]
```

## ValidationResult Endpoint

For a full workflow Shipamax enables you to provide Validation results via API.

The following endpoint is currently available:

| Endpoint                         | Verb  | Description                                                                       |
| -------------------------------- | ----- | --------------------------------------------------------------------------------- |
| /FileGroups/{file_group_id}/validationResult | POST  | Submit a new validationResult making it the lastValidationResult of the FileGroup  |

Send a new validation result via `POST` request to `https://public.shipamax-api.com/api/v2/FileGroups/{file_group_id}/validationResult`

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
### Attributes

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

## Organizations Endpoint
The Organizations list represents businesses that might be referenced in the documents you send Shipamax to processes (for exmaple, the Shipper on a House Bill of Lading, a Supplier on a Commercial Invoice Creditor etc.). The organization list is used to improve the accuracy of the parsing process, making sure the most likely organization is selected. 
Each Organization must have a unique identifier provided by you (referred to as `externalId`), this is usually the identifier used in your own system. 
Each organization added is assigned an internal ID unique to Shipamax (referred to as `org_id`). This ID is required in order to DELETE/PATCH the organization as well as adding Names and Addresses to the Organization

### Attributes

| Attribute                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| id                 | Unique identifier of the Organization within the Shipamax system |
| externalId                               | Unique identifier of the Organization within your own system           |
| carrier                       | Flag for denoting this Organization is a carrier   |
| consignee                       | Flag for denoting this Organization is a consignee   |
| creditor                       | Flag for denoting this Organization is a creditor   |
| forwarder                       | Flag for denoting this Organization is a forwarder   |
| debtor                       | Flag for denoting this Organization is a debtor   |
| shipper                       | Flag for denoting this Organization is a shipper (also refferred to as Consignor or Shipping Agent)  |
| active                       | Flag denoting wether this Organization is active or not   |
| updated | The timestamp of when the Organization was last updated |


### POST
Create a new Organization

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations                   | POST  | Organization's details in JSON    |  The new Organization object in JSON           |

> **Body structure for POST Organizations request:**

```json
{
    "externalId": string,
    "carrier": boolean,
    "consignee": boolean,
    "creditor": boolean,
    "forwarder": boolean,
    "debtor": boolean,
    "shipper": boolean,
    "active": boolean
}
```

> **Example:** POST Organization request body

```json
{
    "externalId": "TRRRRFF",
    "carrier": false,
    "consignee": true,
    "creditor": true,
    "forwarder": false,
    "debtor": false,
    "shipper": false,
    "active": false
}
```

> **Example:** POST Organization response

```json
{
  "id": 35,
  "externalId": "TRRRRFF",
  "carrier": false,
  "consignee": true,
  "creditor": true,
  "forwarder": false,
  "debtor": false,
  "shipper": false,
  "active": false,
  "updated": "2020-01-01T00:00:00.000Z"
}
```

### GET (specific Organization)
Retrieve details of a an existing Organization

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id} | GET | Not required | An Organization object in JSON |


> **Example:** GET Organization response

```json
{
  "id": 35,
  "externalId": "TRRRRFF",
  "carrier": true,
  "consignee": true,
  "creditor": true,
  "forwarder": false,
  "debtor": false,
  "shipper": true,
  "active": true,
  "updated": "2021-08-06T09:58:20.384Z"
}
```

### GET (list of Organistion using Filter)
Retrieve list of Organizations that match a filter.
**Note:** When filter is included, Shipamax will return only the Organizations matching the requested pattern.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations | GET | Filter string in JSON | An array of organizations objects in JSON |


> **Body structure for GET Organization request using filter**

```json
{
  "filter": {
    "where": {
      "and": [
        {
          "externalId": "XXXYYY"
        },
        {
          "active": true
        },
        {
          "consignee": false
        }
      ]
    }
  }
}
```

### PATCH
Update details of an existing Organization

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id} | PATCH | The updated Organization details in JSON | 

> **JSON structure for PATCH Organization request**

```json
{
  "externalId": "TRFHEED",
  "active": true
}
```

> **Example:** PATCH response with the updated Organization as JSON like this:

```json
{
  "id": 35,
  "externalId": "TRFHEED",
  "carrier": false,
  "consignee": true,
  "creditor": true,
  "forwarder": false,
  "debtor": false,
  "shipper": false,
  "active": true,
  "updated": "2020-01-01T00:00:00.000Z"
}
```

### DELETE
Delete an Organization

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id} | DELETE | Not required | Number of deleted organizations |


> **Example:** DELETE Organization response

```json
{
  "count": 1
}
```

## Organization Names Endpoint
An Organization Name represents a name associated with an Organization. An Organization can have multiple names associated with it. 
Each Organization Name added is assigned an internal ID, unique to Shipamax (referred to as `name_id`). This ID is required in order to DELETE/PATCH the name


### Organization Name attributes

| Attribute                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| id                 | Unique identifier of the Organization Name within the Shipamax system |
| organizationId                               | Internal ID of the Organization this Name is associated with in Shipamax           |
| name                       | The name for the Organization   |
| main                       | Flag denoting whether this is the main name for an Organization. This is unique across Organizations; there can only be one main name per Organization  |

### POST
Create a new Name and assign it to an existing organization.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id}/Names | POST  | The Name details in JSON | The details of the created Name, including its unique ID and the Organization ID |


> **JSON structure for POST Organization Name request**

```json
{
  "name": string,
  "main": boolean
}
```

> **Example:** POST Organization's Name response
```json
{
  "id": 1,
  "organizationId": 35,
  "name": "Foo",
  "main": false
}
```

### GET
Retrieve all Names assigned to an Organization.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id}/Names | GET  | Not required | List of the Organization's Names in JSON  |

> **Example:** GET Organization's Names response

```json
[
{
  "organizationId": 35,
  "name": "Foo",
  "main": false,
  "id": 1
},
{
  "organizationId": 35,
  "name": "Fee",
  "main": true,
  "id": 2
}
]
```

### PATCH
Update an existing Organization's Name

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /OrganizationNames/{name_id} | PATCH | The updated details in JSON | The Name object in JSON  |


> **Example:** Body of PATCH OrganizationNames request (This change the name to "NewName" and set it as main name) 

```json
{
  "name": "NewName"
  "Main": true
}
```

> **Example:** PATCH OrganizationNames response

```json
{
  "organizationId": 35,
  "name": "NewName",
  "main": true,
  "id": 1
}
```

### DELETE
Delete an existing Organization's Name

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /OrganizationNames/{name_id} | DELETE  | Not required | Number of deleted objects |

## Organization Addresses Endpoint
An Organization Address represents an Address associated with an Organization. An Organization can have multiple Addresses associated with it. 
Each Organization Address added is assigned an internal ID unique to Shipamax (referred to as `addr_id`). This ID is required in order to DELETE/PATCH the Address.

### Attributes

| Attribute                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| id                 | Unique identifier of the Organization Name within the Shipamax system |
| organizationId                               | Unique ID of the Organization this Organization Name is associated to in Shipamax           |
| address1                       | The first line of the Organization Address   |
| postCode                       | The postcode of the Organization Address  |
| email                       | The email of the Organization Address  |
| main                       | Flag denoting whether this is the main address for an Organization. This is unique across Organizations; there can only be one main address per Organization  |

### POST
Create a new Address for an existing Organization

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id}/Addresses | POST  | The new Address details in JSON | The details of the created Address, including its unique ID and the Organization ID |


> **JSON structure for POST Organizations Address request**
> 
```json
{
  "address1": string,
  "postCode": string,
  "email": string,
  "main": boolean
}
```

> **Example:** Body of POST Organization's Address request
 
```json
{
  "address1": "Rue Lars",
  "postCode": "AA1 123B",
  "email": "email@email.com",
  "main": true
}
```

> **Example:** POST Organization's Address response

```json
{
  "organizationId": 35,
  "address1": "Rue Lars",
  "postCode": "AA1 123B",
  "email": "email@email.com",
  "main": true
}
```

### GET
Retrieve all Addresses assigned to an Organization.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /Organizations/{org_id}/Addresses | GET  | Not required | List of the Organization's Addresses in JSON  |

> **Example:** GET Organization's Address response

```json
[
{
  "id": 1,
  "organizationId": 35,
  "address1": "Rue Lars",
  "postCode": "AA1 123B",
  "email": "email@email.com",
  "main": true
},
{
  "id": 2,
  "organizationId": 35,
  "address1": "Green Hill",
  "postCode": "S3fdede£",
  "email": "email@email.com",
  "main": false
}
]
```

### PATCH
Update an existing Organization's Address

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /OrganizationAddresses/{addr_id} | PATCH  | The updated details in JSON | The Address object in JSON  |


> **Example:** Body of PATCH OrganizationAddresses request 

```json
{
  "address1": "New Street 1"
}
```

> **Example:** PATCH OrganizationAddresses response

```json
{
  "id": 1,
  "organizationId": 35,
  "address1": "New Street 1",
  "postCode": "AA1 123B",
  "email": "email@email.com",
  "main": true
}
```

### DELETE
Delete an existing Organization's Address

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /OrganizationAddresses/{addr_id} | DELETE  | Not required | Number of deleted objects |

## Files Endpoint

### GET Original File

You can retrieve all files processed by Shipamax. For example you can retrieve a bill of lading which was send to Shipamax as an attachment to an email. Files can be retrieved via their unique ID. The response of the endpoint is a byte stream.

| Endpoint                      | Verb   | Description                                                 |
| ----------------------------- | ------ | ----------------------------------------------------------- |
| /Files/{file_id}/original          | GET    | Get original binary file                                    |


### POST Files/upload

You are able to upload files directly to Shipamax. The endpoint takes files as `form-data` with a key of `req`, as well as three URL parameters `customId`, `mailbox` (optional), and `fileType` (optional). The endpoint will respond with a `JSON` object
containing information of all files successfully processed into the system.

The files will be processed as though they were attachments of a single email sent to the given Shipamax mailbox address. The mailbox settings determine whether all of the files are considered part of one group, and what kinds of files will be validated.

The mailbox will also determine whether these files are run against our normal parsing service, or against the clustering service.

If the mailbox given does not exist, an error will be returned and the files will not be processed, as it would not be possible to determine settings for processing and validation.

https://public.shipamax-api.com/api/v2/Files/upload

URL Parameter Definitions

| Parameter                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| customId                                | Your unique identifier of the files, could be a uuid4 string.     |
| mailbox (optional)                          | The mailbox address e.g. xxx@yyy.com. If not supplied, your default mailbox will be used.                        |
| fileType (optional)                            | The fileType of the file(s) you are posting. **If you specify a file type with multiple files, they will all process as that type** |


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

If a mailbox is configured to have one file per group, you will receieve an array response like this:
```json
[{
  "customId": "CUSTOM_ID",
  "filename": "FILE_NAME",
  "groupId": 00000,
  "id": 000000,
},
{
  "customId": "CUSTOM_ID2",
  "filename": "FILE_NAME2",
  "groupId": 00001,
  "id": 000001,
}]
```

## Cargowise References Endpoint

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

> Example xml format when sending organization data as a `<Native>` request:

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

There are two formats you can send product data in; verbose and native.

### Verbose

This is a `<XmlInterchange>` request.
XML tag `<Products>` wraps up all the product code related data.

**Following are the important tags we expect in the request:**

**Product-**
  *ProductCode*,
  *ProductDescription*,
  *StockUnit*

**RelatedOrganization-**
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
                    4sIAAAAAAAEAO1aWW/jOBJ+X2D/g5HXhVqnr8CtgeO4O9kktsfHNDAvC1qibKFlyZCodLy/fovURZGU2z3zusCgR6z6qlhkFYtVdCa/fZyi3jtOszCJP9+Zn4y7Ho69xA/jw+e7nATa6O43d7KLQ4pB0XNMcOodUXzAPZCMs893R0LO97r+48ePTx5KD8mPMMOfvOSkb7wjPqFMr4V1yzBN3TTv+AnNO/ef/+j1Jk8Y+Thl3zDa4BhGz4/udLZ6WMzhv4le00rMGnvhOcQxAdLmGJ7RG/qY6DyVKdY5zZOHxL9U8gtEwLCbl1HAFWuwYNNUa1j+iHE6S3zsTneb2W4DizAnekMtYfMY7SNMKW/ofIZ9d0ma44ku00uB+P3+ERE0S8AXH+TvuIGJ3sfvv7760hawhpqySfLUA1OjCHsE9qTmtvgcFejbyxm7qzTxc49MdDZq8V/wxTX7A2ugjUavhqkZhjHRKZHTrSuU80SFRZNZcjqjuKWGeYOFGOeXkpPHJL20LStdKqFZSJ2AlWckRVGIJjob8wbLCgWZuDeDz+SU9WBvApzREEMRjMil90p8QSVV2F4OhBOc0HMK/itODw0kjtLg3uGMCNteLG3+uJV34hFnXhqe2V7O/ZBgv4d6KfaSFGzimY1p8gzFpLusPiPNpJuNPCdb6gbvUUbgQPfApydp/bLGYpKHFMXe8TYvM5WMo1IuaCrUP+IzSskJvuQp1ouuKZgm9SwKhZAE03eW8Mr0V45q/jYNDweaTCCmXBsOET8WUXAqsGsZFpwkSzMHW2N8b/bv+4NP1nD4L9O8p8eLh0ryUgA0eJX7Sx7zf/ldC7SDos7Y6yTqSCItiOI0Ltcr1XHkDVumBxSHGaIDerY+Luq4pR5RTyfQJUsnejsz/+T6KXOf4h5hbLB3k5/PUYjTFURGb8qm+nz3Nl9/nd/x5q5eXHMwgkyJbc0YGb7m+H2sob0/0OzxcDAcBINg7IwnOgB5MdC6yE9ykq0YHHZDEu/7C8b0GoJ7hLiLJQSkSBQT5yNs1wlFqwh5OHONMvu1qeIkW/Qdzy4ebHs5QUPgoN9weDgS1/jEDC5HEn/3u/vytWLDgLcv34deJV8MRC4IvNklsy0MZ5UcK+FiwHGfWrY9ybaFfiNdDDjuG0ZZnmKYcKI33xzgFbLhLMnKCUBFTZDWj/0WsEXkwL+Ty3PM9ppBJzpH4GB/QPmVQCx634Ff2d8m8ujVGsPdgNO3MA5PEE0ULNKUePQh40sah18yeh6R8BxhziCJ3iXDIlbAi1H8GL6H9GwCrv5sx0GVs1kcqG4EdpmXIW82AdeiduEtJd7qxNtKvN2Jd5R4pxPfV+L7Mn5KSBruTbdCVuMOoCUAFSssGLYAVCytYDgCULGmgtEXgIrF0NuwWUoxUoKsFkjlJiDbLZDKN0B2WiCVQ4Dcb4Fahi8waWfIhsDn20tG8GmWYhDfhie8Ix4tEAy4RDRzuDWMe6soC1RASQ9NQ7Qu4DQVpUZ/a9m01Gg0iVBO13NG77l3XPZA9bAF+YZSfEzyDJdXqBtAhczQEqclt8ZZ0SvU+Joi7fCXCB3MCsiTlEhLRir8T8m2jFQEASU7MlIRCZTcl5GtcJjmJFmlYUymWYZP+wiyO3QbOSsoskr2OoifF8WPUEcVKPwCGbPwlUxvC8Fe4yhqwOVY6DHczXz6WlRmbefRRieJIb2uQu879pfxBkU4Y+m78ec1UEvbA0o9KBf9Os5qAgeDNUAAwr6sMVwOUDwegV/OpeRxsrTW9+GEFv/nL3iYJaKXO/s/PxtUUjto0+gprSbhSBySXlPZitaFUIFW9zs9XgKjHSyzCHxDa7tV+J4QZZ2tAnYXngwPNaVn2Qg7Q1szDexpDnZG2hibfQ0hLzDNPQoMyxKKzyIsff85DpIOS3iIxCjfB9a0DG2/CdT8P1CUY9cwTKgj2KekXFdrr+mdhrEabJqzJoj1SkURxlO6BViv2hIQ+mEmsEVpGAS0Coemqf4WQKw/wLTkQFEBokWzTBTEZscw8lkL9rR9hqNYD1U4KKEYr8RVww5oXSBUYxXuNcxIcSQrZENRbsOMvTeuoNSkr2Dl2VCxBGnqiQ2BQHbZo1D5rQDN2VGtvkSbk9gr3mEKE2kb06aIRyKFsii9rFIc4BQDFERkmiC0xhFMD3Hnhx4iCZ1GIonux14S++JMKqogSM8D64NZx1ycj2bcBX5D6ff8XBf+AlmQ2mXoAB3yqSyOW0MBuqiOIZQpHSdywTfqAFP37YU7W8grwDrB7ZZvbtH01kMBCq140cT3dCk4ynQZBtRHyhzW5rPT8/xGnytkuixbPBdyL47NWAK/Jgl4gvHWu4eH+bpH71L963TzMt9uIOU0fEkWsnPgYAOPDEOzkG1ojuEMtLE9MjXPDkYD2xx7wd5TpPG2lfMPgtMYRb0tfbymD12f79Y4KBHi7VFKdz2nNrZhB+8HeDyEO2U40hwPbNuDVZrd3w+D/b4f7A2stk1XGCcl/J95sVrhrav6yZr+xopUL8i8hctg/nFOUtJhqSKAK7kllBlhfLNcAYeMSrBahrEyheQWfdBgF6Qe9/OY/Pnnf6iCPAPMMv2CsSjeuKo+r62Hu9vKHHqgKYIlWJb21LWQAPt5JTTej7HfH2JtMAgCzRl6lrY3bEczx74RjHwfDdVOrWbIjuHZXX5blLm/oojFROKhqHyk2xfFhEARdzykNy38K9CfGP1Jor9CyVo8E0FyBy9DRelB4jbL56FO9m1qrOtqrBvV2NfV2FKgR/Thlr2r1Z+iG5ILisil1FDddAJVLQM9F5me2MN79dwmc0TRL8WbQ07gaoyDMD25iyX1vUyX4wWjrHgkbL4lkIehdS5B1bcAgmwRphda+XxJ0hMiG5gYCqmJ3sGQLlHvO5AV8l0cUQH0aW8sWW7gSqxH0iZH0e5c70q2jB8TL6fFRN2+XoMI2p5ZeijfpMrtm6EzydOmvbuKuaLPukGfhLmiz75Bn4QR9P07p78rPiDiHRdJ4QxwkIoqCFLqK7okOaG/aKQ0S9a9tpInFYG4CaNKsE2UJbjA4UR4qkqm9lVLpqFek7GUMlIeanFtpYycdJITNGMEFw05DW+ug1Ezu5J9u7BVkuXGJQsPMcZvcFEfcRS8hgGeeh4+Q1dR/BxzDSAuPw4JdDHQTVQJrqF01csdhdHT9Hkx36h+ii1RcEM6w5FlO8jUHKiE4B8f6qP+yNYCxzADsz8wTHuvrvhgdloGgOIrLwstnIJbGDEcIxzY+7HmBb6vOXtsa3uHvmwMR8ORPfK8wAuURhRrLX7IX+PDInEHVm80GPX6g2HPGljVU13JVIuDZawrmD6UPygre4QSy2quRxygPCJNgLWonbP8YnXLSV6r26tN/Mu1O1OgcwaqvKhfdeMtTjZNPBgYeKh53hBpjt3H2mjs7zUfe07fdCzDGlyxr+XHYd8eD4ZOf/xL/n3c/d+/f8m/PLP7sU7vSkdV7TbLU/pMIu1PSVY1TXANHZL2jpbNQsVSSqUkib+mSX7mBb8dM46jkCv9+xzTvxMB1U9J5NMlC0oaPi74ClV1yv7FNbNN5HuhVtd1SztV/bnDhlzYn04keSr0U8JyZHzbqJbCTfhffLs6ihaU0bepxA/JRdxYdlA4niBHn3H539XpBt60p6x0VvTBFZlHsx3m/xik5NBnxeZnrole/nXJpPxjPZGq+iNO938hIQmSASoAAA==
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

### Native

This is a `<Native>` request.
XML tag `<Product>` wraps up all the product code related data.

**Following are the important tags we expect in the request:**

**Product-**
  **OrgSupplierPart-**
    *PartNum*,
    *Desc*,
    *StockKeepingUnit*
  **OrgPartRelationCollection-**
    **OrgPartRelation-**
      *Relationship*,
      **OrgHeader**
        *Code*

> Example xml format when sending product code data:

```xml
<?xml version="1.0" encoding="utf-8"?>
<UniversalInterchange xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" version="1.1">
    <Header>
        <SenderID>TST</SenderID>
        <RecipientID>test</RecipientID>
    </Header>
    <Body>
        <Native xmlns="http://www.cargowise.com/Schemas/Native/2011/11" version="2.0">
            <Body>
                <Product version="2.0">
                    <OrgSupplierPart Action="MERGE">
                        <PartNum>TESTCODE</PartNum>
                        <StockKeepingUnit>PCE</StockKeepingUnit>
                        <Desc>TEST DESCRIPTION</Desc>
                        <OrgPartRelationCollection>
                            <OrgPartRelation Action="MERGE">
                                <Relationship>OWN</Relationship>
                                <OrgHeader>
                                    <Code>TESTORGCODE</Code>
                                </OrgHeader>
                            </OrgPartRelation>
                        </OrgPartRelationCollection>
                    </OrgSupplierPart>
                </Product>
            </Body>
        </Native>
    </Body>
</UniversalInterchange>
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
| 52              | Commercial invoice: Supplier missing |
| 53              | Commercial invoice: Importer missing |
| 54              | Commercial Invoice: Could not find Product Code |
| 55              | CommercialInvoice: Product Code not associated with Importer or Exporter |
| 56              | Commercial invoice: Mixed group has more than 1 MBL |
| 57              | Commercial invoice: Mixed group has more than 1 CI |
| 58              | Commercial invoice: Mixed groups do not support HBLs |
| 59              | Container number: No reference found for highlighted job |
| 60              | Container number: Multiple references found for highlighted job |
| 61              | Supplier Invoice: Timeout while trying to match accruals with total or highlighted sub-total |
| 62              | Commercial invoice: Mixed group has more than 1 HBL |
| 63              | Commercial Invoice: Mixed groups of this combination are not supported |
| 64              | Accruals in CargoWise have changed since previous selection. Please re-select the correct accruals to post |
| 65              | Multiple accruals with the same charge code detected on the same Shipment. Posting these may have unexpected results in CargoWise |
| 66              | Modified accrual amounts are not within the tolerated threshold |
| 67              | Job Reference: Reference extracted from email subject |
| 68              | Job Reference: Unable to set job references; multiple references found |
| 69              | Job Reference: Multiple S-Job references found in email subject. If you know the job reference, create a S-Job place holder and update the reference before posting to CW |
| 70              | Cargowise: Failed to post file to EDocs |
| 71              | Commercial Invoices: No CIVs found in documFent pack |
| 72              | Cargowise: Missing job reference |
| 73              | Job Reference: Job reference not valid for this group |
| 74              | Error fetching costs from CargoWise (please contact support) |
| 75              | Error posting invoice to CargoWise (please contact support) |
| 76              | Error while validating costs (please contact support) |
| 77              | Error posting invoice to TMS (please contact support) |
| 78              | Duplicate Invoice Number |
| 79              | Failed to post to TMS (please try again) |
| 80              | Error fetching costs from TMS (please contact support) |
| 81              | Supplier Invoice: Tax subtotals do not sum to invoice total |
| 82              | Supplier Invoice: Missing GL Code |
| 83              | Supplier Invoice: Missing Description |
| 84              | Supplier Invoice: Missing Net Total |
| 85              | Supplier Invoice: Missing Tax Code |
| 86              | Supplier Invoice: Missing Tax Total |
| 87              | Supplier Invoice: Missing Tax Amount |
| 88              | Line Items: Gross Total does not match Line Total Sum for one or more Commercial Invoices |
| 89              | Cargowise: Declaration is locked. Make sure it is not worked on and try again |
| 90              | CargoWise: Job verification failed, please try to post again. If problem persists, please contact support. |
| 91              | CargoWise: Bill of Lading: Duplicate BL number for one or more documents |
| 92              | CargoWise: Commercial Invoice: Duplicate CIV number for one or more documents |
| 93              | Supplier Invoice: Invalid accrual split |
| 94              | Cargowise: Pack is missing MBL and a Consol reference. Posting will create a new, empty Consol |
| 95              | CargoWise: Cargowise: Pack is missing HBL and a Shipment reference for one or more Shipments. Posting will create a new, empty Shipment |
| 96              | Cargowise: Shipment reference not found in cargowise |
| 97              | Cargowise: Consol reference not found in cargowise |
| 98              | CargoWise: Cargowise: One or more Shipments references found in CW but is already linked to an existing Consol |
| 99              | Shipment: Duplicate S-ref numbers |
| 100             | Consol: Pack includes a Consol reference. Posting will update an existing Consol |
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

### List of UnitType values

| UnitType    | Description        |
| ----------- | ------------------ |
| BOT         | Bottles            |
| KG          | Kilograms          |
| LB          | Pounds             |
| M           | Meters             |
| M2          | Square Meters      |
| M3          | Cubic Meters       |
| NO          | Number             |
| PCE         | Pieces             |
| PKG         | Packages           |
| T           | Tones              |
| UNT         | Units              |
| CTN         | Carton             |

### List of ContainerMode values
| Mode        | Description              |
| ----------- | ------------------------ |
| FCL         | Full Container Load      |
| LCL         | Less than Container Load |
| GRP         | Groupage                 |
| BLK         | Bulk                     |
| LQD         | Liquid                   |
| BBK         | Break Bulk               |
| BCN         | Buyer's Consolidation    |
| ROR         | Roll On/Roll Off         |
| OTH         | Other                    |


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
| 11           | Overhead AP Invoice               |
| 1000         | Multiple documents in one file |

### List of Group status
| Code         | Description
| ------------ | ------------------ |
| 1            | Unposted           |
| 2            | Discarded          |
| 3            | Posted             |
| 4            | Out Of Sync        |
| 5            | Done               |
| 6            | Processing         |
