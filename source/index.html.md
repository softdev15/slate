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

# API basics

The API is [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_Web_services), and messages are encoded as JSON documents

### Endpoint

The base URI for all API endpoints is `https://developer.shipamax-api.com/api/v2/`.

### Content type

Unless specified otherwise, requests with a body attached should be sent with a `Content-Type: application/json` HTTP header.

# Authorization

All API methods require you to be authenticated. Once you have your access token, which will be given to you by the Shipamax Team, you can send it along with any API requests you make in a header. If your access token was `abc123token`, you would send it as the HTTP header `Authorization: Bearer abc123token`.

# Reference


## FileGroup

A FileGroup is responsible for managing a group of Bill of Lading files. A FileGroup has association with Files which have association with BillOfLading Entities. The following endpoint is currently available

| Endpoint                   | Verb | Description                                                 |
| -------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroup/{id}            | GET  | Get a Bill of Lading Group based on the given ID.           |

Get a group by making a `GET` request to `https://developer.shipamax-api.com/api/v2/FileGroup/{id}`

> The GET FileGroup request returns JSON structured like this:

```json
{
    "id": 1,
    "created": "2020-05-07T15:24:47.338Z",
    "status": 1,
    "consol": {
        "documentId": 441,
        "billOfLadingNo": "BOLGRP1",
        "bookingNo": "100",
        "shipper": "SHIPPER F",
        "consignee": "SOME CONSIGNEE",
        "notify": "AAA",
        "grossWeight": "2322 kg",
        "destinationAgent": null,
        "vessel": "VESSEL",
        "carrier": "CARRIER",
        "grossVolume": null,
        "voyageNumber": "12121XW1MD",
        "loadPort": "LOAD PORT1",
        "dischargePort": "DISCHARGE PORT1",
        "shippedOnBoardDate": "2019-06-01T23:00:00.000Z",
        "paymentTerms": "FREIGHT COLLECT",
        "category": true,
        "subcategory": "TELEX BILL",
        "secondNotify": null,
        "exportReference": null,
        "created": "2020-05-07T15:24:47.366Z",
        "scac": null,
        "loadPortUnlocode": null,
        "dischargePortUnlocode": null,
        "goodsDescription": null,
        "carrierCWCode": null,
        "consigneeCWCode": null,
        "notifyCWCode": null,
        "secondNotifyCWCode": null,
        "shipperCWCode": null,
        "vesselIMO": null,
        "transportMode": null,
        "containerMode": null,
        "shipmentType": null,
        "id": 13,
        "container": [],
        "filename": "bl_.pdf",
        "unqId": "xxxABC"
    },
    "shipments": [
        {
            "documentId": 442,
            "billOfLadingNo": "BOLGRP2",
            "bookingNo": "121",
            "shipper": "SHIPPER C",
            "consignee": "SOME CONSIGNEE",
            "notify": "BBB",
            "grossWeight": "2323 kg",
            "destinationAgent": null,
            "vessel": "VESSEL 2",
            "carrier": "CARRIER",
            "grossVolume": null,
            "voyageNumber": "121212",
            "loadPort": "LOAD PORT2",
            "dischargePort": "DISCHARGE PORT2",
            "shippedOnBoardDate": "2019-06-01T23:00:00.000Z",
            "paymentTerms": "FREIGHT PREPAID",
            "category": true,
            "subcategory": "ORIGINAL BILL",
            "secondNotify": "notifyG",
            "exportReference": null,
            "created": "2020-05-07T15:24:47.366Z",
            "scac": null,
            "loadPortUnlocode": null,
            "dischargePortUnlocode": null,
            "goodsDescription": null,
            "carrierCWCode": null,
            "consigneeCWCode": null,
            "notifyCWCode": null,
            "secondNotifyCWCode": null,
            "shipperCWCode": null,
            "vesselIMO": null,
            "transportMode": null,
            "containerMode": null,
            "shipmentType": null,
            "id": 14,
            "container": [
                {
                    "billOfLadingId": 14,
                    "containerNo": null,
                    "numberPieces": null,
                    "pieceType": null,
                    "weight": null,
                    "volume": null,
                    "containerType": null,
                    "seals": [
                        "SEAL123"
                    ],
                    "id": 30
                }
            ],
            "filename": "bl_2.pdf",
            "unqId": "xxxCDE"
        }
    ],
    "lastValidationResult": {
        "valid": false,
        "status": 0,
        "teamId": 1,
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
        "supplierInvoiceId": null,
        "documentGroupId": 1,
        "id": 102
    }
}
```

## WebHooks

The webhooks will be triggered when a document successfully parses the first validation. The destination URL which webhooks should call will be provided by the customer to Shipamax, for example by email.

The webhooks endpoint will send a request to the provided endpoint via POST with the following body

> Body Definition

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "[EVENT-NAME]",
  "payload": {
      "id": integer,
     "exceptions": [EXCEPTION-LIST]
   }
}
```

Details of body definition

Event names:

- Validation/BillOfLadingGroup/Failure
- Validation/BillOfLadingGroup/Success

Exception list contains exception objects:

{  
 "code": integer,  
 "description": string  
}  

> Example of body sent via webhook

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "Validation/BillOfLadingGroup/Failure",
  "payload": {
     "id": 1,
     "exceptions": [{ "code": 1, "description": "Bill of Lading: More than one MBL in group" }]
   } 
}
```
