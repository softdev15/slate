---
title: Shipamax Freight Forwarding API Reference

toc_footers:
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>


search: true
code_clipboard: true
---

# Getting started


The Shipamax API enables developers to integrate Shipamax's data extraction and process automation modules into their systems.

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

Alternatively, we also support the token in the URL as a GET parameter. In that case the URL looks like `https://public.shipamax-api.com/api/v2/someEndpoint?token=abc123token`.
**However, this is not a recommended authentication method and we'll disable this option in near future**.

## Long-term support and versioning

Shipamax aims to be a partner to our customers, this means continuously improving everything including our APIs. However, this does mean that API versions will eventually be discontinued. We aim to honour the expected End-Of-Life, but in case this is not possible we will work with our customers to find a solution.

Version: v1
Launch: April 2020
Expected End-Of-Life: Not before March 2023

# Webhooks

Sometimes you will want to know when certain events happen in the Shipamax system, and for that purpose we use webhooks. During the onboarding process you can register a URL with us that we will use to inform you when certain events occur. This will consist of sending an HTTP POST message to that endpoint. To register a URL for a webhook event, please contact the support team.

All requests will be HTTP POST requests with a `Content-Type` of `application/json`.

## Responses

When we connect to your endpoint to deliver the webhook body your server will need to send back a response. For most requests, any response with a status of 200 OK will be considered a success, and the body of the response is unimportant. We may in the future specify an optional response format, but any response not in that format will be considered as an empty response rather than an error.

Other requests that expect a specific response format are detailed in their own section.

## Security
All endpoints *must* use HTTPS, so that we can verify that the endpoint is genuine.

To allow our customers to verify that each message is genuine, Shipamax adds one or two HTTP headers to each webhook request, `x-shipamax-signature` and optionally `x-api-key`. See [Validating webhook signatures](#validating-webhook-signatures) for more details on validating the webhook event.


> The webhook endpoint will send a request to the provided endpoint via POST with a body in the following format:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": string,
  "payload": EventSpecificPayload
}
```

## Forwarding Import/Export webhooks

### Main Webhook Event:

| Event Name                                   | Description                                |
| -------------------------------------------- | ------------------------------------------ |
| ValidationComplete                              |   The event includes a json payload with attributes: *GroupID* - The ID of the pack that was posted This value can be used with the <FileGroups Endpoint> to retrieve the data extracted from documents in that pack and/or get the validation results. *Success* - true/false flag indicating whether the internal validation of the pack’s was a successful (true) or failed (false).|

### Additional Webhooks:

| Event Name                                    | Description                                |
| --------------------------------------------- | ------------------------------------------ |
| Validation/BillOfLadingGroup/NoBillsOfLading  | Pack received but did not include a bill of lading (used by Forwarding scenario only)   |
| ClusteringComplete                            | Clustering calculation of a document has been completed (used by a specific workflow)   |
| ParsingComplete                               | Parsing of a document, triggered by the [parse endpoint](#parse-endpoint) , has been completed (used by a specific workflow |
| Validation/BillOfLadingGroup/Success | Validation finished and was successful (used by a specific workflow) |
| Validation/BillOfLadingGroup/Warning | Validation finished with warnings (used by a specific workflow) |
| Validation/BillOfLadingGroup/Failure | Validation finished with exceptions (used by a specific workflow) |


These events are triggered when the bills of lading in a FileGroup validation pass, fail or no bill of lading is found in the file, respectively.

For more details of exception codes, check our [list of exceptions](#list-of-exceptioncode-values)

> Example of body sent via webhook:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "ValidationComplete",
  "payload": {
     "fileGroupId": 13704,
     "success": true
   }
}

or

{
  "kind": "#shipamax-webhook",
  "eventName": "Validation/BillOfLadingGroup/NoBillsOfLading",
  "payload": {
     "fileGroupId": 13704,
     "exceptions": []
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
  "eventName": "ValidationComplete",
  "payload": {
     "fileGroupId": 13704,
     "success": false
   }
  }'
```

## Webhooks for AP validation
These are the relevant webhook messages for AP customers.

### Metadata
In each request belowe, the **metadata** object is an optional parameter that can be used to send company code data relating to the mailbox that the invoice was sent to. If you have no company codes or other company specific data configured on your mailbox, the metadata object will not be included.  Any metadata that is set for a mailbox will be sent with all relevant webhook messages.

### ValidationComplete

```json
{
  "kind": "#shipamax-webhook",
  "eventName": "ValidationComplete",
  "payload": {
    "fileGroupId": 13704,
    "success": true
  }
}
```

Each time we finish validation, this webhook will be raised. Resubmitting from the Exception Manager starts validation.

Rather than attempt to guess all of the possible things that a customer might find useful to include in this message, we instead provide the file group ID. This can be used with the API to find all of the parsed information as well as details of any validation problems that occurred. However, many customers may only need to take action on failure, so we include a `success` flag that simply indicates whether the validation succeeded.


<br style="clear: right;"/>

### AccrualsRequest

```json
{
  "kind": "#shipamax-webhook",
  "eventName": "AccrualsRequest",
  "metadata": { "companyCode": "ABC" },
  "payload": {
    "issuerReference": "SHPMXLON",
    "jobReferences": ["S00000001", "S00001234"],
    "billNumbers": ["HWBABC001234"],
    "containerNumbers": [
      {
        "number": "CCLU1234567",
        "serviceStartDate": "2021-12-16",
        "serviceEndDate": null
      }
    ],
    "purchaseOrders": ["ABC12345"],
    "currency": "USD",
    "invoiceDate": "2021-10-08",
    "fileGroupId": 13704
  }
}
```

> Shipamax expects the response to this message to look like:

```json
{
  "kind": "#shipamax-webhook",
  "eventName": "AccrualsResponse",
  "payload": {
    "jobs": [
      {
        "jobReference": "S00000001",
        "billNumbers": [],
        "containerNumbers": ["CCLU1234567"],
        "accruals": [
          {
            "id": "90111",
            "currency": "USD",
            "netAmount": 150,
            "taxAmount": 30,
            "localAmount": 200,
            "exchangeRate": 0.75,
            "chargeCode": "FRT"
          }
        ]
      },
      {
        "jobReference": "S00001234",
        "billNumbers": [],
        "containerNumbers": ["CCLU1234567"],
        "accruals": [
          {
            "id": "90112",
            "currency": "USD",
            "netAmount": 75,
            "taxAmount": 15,
            "localAmount": 100,
            "exchangeRate": 0.75,
            "chargeCode": "DOC"
          },
          {
            "id": "90113",
            "currency": "AUD",
            "netAmount": 123,
            "taxAmount": 0,
            "localAmount": 123,
            "exchangeRate": 1,
            "chargeCode": "FRT"
          }
        ]
      },
      {
        "jobReference": "S00002222",
        "billNumbers": ["HWBABC004321"],
        "containerNumbers": [],
        "purchaseOrders": ["ABC12345"],
        "accruals": [
          {
            "id": "90114",
            "currency": "USD",
            "netAmount": 100,
            "taxAmount": 0,
            "localAmount": 133.33,
            "exchangeRate": 0.75,
            "chargeCode": "DDOC"
          }
        ]
      }
    ]
  }
}
```

This message is sent as part of validating AP Invoices, and it represents Shipamax asking the customer to provide information about the unpaid accrued costs associated with the invoice being processed.

- The `issuerReference` matches the `externalId` of the Organisation in our system that issued the invoice. We only want to receive accruals that are for this issuer.
- Job references, bill numbers and container numbers are various references found on the invoice that we believe to be of the associated type. These are used to identify the jobs that the accruals relate to.

Accruals are split by job, with each job associated with some references, bills and/or containers. It is important that we can match each accrual to the appropriate jobs/bills/containers as this is how we determine which sub-total to associate the accrual with on invoices that have multiple sub-totals.

It is not essential to include bill numbers and container numbers associated with each job if they were not in the list of requested references, but the response should include at least one job for each valid reference requested, even if there are no accruals. A requested reference that does not appear in the response will be treated as an invalid reference, and *may* result in a validation failure.

Each accrual needs to have an identifier that is unique across all accruals in the customer system. Shipamax receives this as a string and does not attempt to interpret it. This same identifier will be used in the PostInvoice webhook message to identify which accruals have been matched to the invoice.

The response *should* have a `Content-Type` of `application/json`. A response status other than `200 OK`, a body that cannot be parsed as JSON, or a body not in the above format, will be interpreted as a problem with the endpoint, and the message may be retried.

A valid response with no jobs, or jobs with no accruals, *may* cause validation to fail but is otherwise treated as a successful response.

We expect the exchange rate to be sent to us in the following format: **exchangeRate = Local/Foreign**

<br style="clear: right;"/>

**PostInvoice**

```json
{
  "kind": "#shipamax-webhook",
  "eventName": "PostInvoice",
  "metadata": { "companyCode": "ABC" },
  "payload": {
    "invoiceNumber": "71431",
    "issuerReference": "SHPMXLON",
    "invoiceDate": "2021-10-08",
    "netTotal": 200,
    "taxTotal": 30,
    "currency": "USD",
    "localTotal": 266.66,
    "fileId": 1820,
    "fileGroupId": 13704,
    "accruals": [
      { "id": "90111", "netAmount": 150, "taxAmount": 30, "localAmount": 200, "exchangeRate": 0.75, "chargeCode": "FRT" },
      { "id": "90114", "netAmount": 50, "taxAmount": 0, "localAmount": 66.66, "exchangeRate": 0.75, "chargeCode": "DOC", "partial": true }
    ]
  }
}
```

When the validation process for an AP invoice is complete, Shipamax will send a message to the webhook endpoint that contains the details of the validated invoice. This is instead of simply storing the invoice and letting the customer react to the ValidationComplete webhook because we want to verify that the message was successfully retrieved before marking the validation as complete.

Again, the content of the response is not important, but any status other than `200 OK` will be interpreted as a failure, and posting may be retried and/or validation may fail.

For each accrual, the `id` matches the `id` of an accrual previously fetched via the `AccrualRequest` webhook. Shipamax sends the values for the amounts as these can be edited during the validation process. When the optional `partial` flag is false or missing this means that the new amount should be interpreted as the new full amount to be paid for that accrued cost. When `partial` is true it means that the invoice is requesting payment for only part of the accrued cost, and the remaining value of the cost should remain as a separate cost to be paid later.

<br style="clear: right;"/>

**PostOverheadInvoice**

```json
{
  "kind": "#shipamax-webhook",
  "eventName": "PostOverheadInvoice",
  "metadata": { "companyCode": "ABC" },
  "payload": {
    "invoiceNumber": "71431",
    "issuerReference": "SHPMXLON",
    "invoiceDate": "2021-10-08",
    "netTotal": 200,
    "taxTotal": 30,
    "currency": "USD",
    "localTotal": 266.66,
    "fileId": 1820,
    "fileGroupId": 13704,
    "costs": [
      { "netAmount": 150, "taxAmount": 30, "taxCode": "VAT", "glCode": "3905.00.00", "description": "Equipment" },
      { "netAmount": 50, "taxAmount": 0, "taxCode": "VAT", "glCode": "3905.00.00", "description": "Equipment" }
    ]
  }
}
```

When the invoice is an Overhead, there will be no costs accrued in the customer system so there will be no AccrualsRequest webhook sent and no further validation after being submitted from the Exception Manager.

For these invoices the webhook message for posting will be slightly different, as we have slightly different cost data.

## Validating webhook signatures

Each webhook event includes two custom HTTP headers that can be used for validating that the event and its content where generated by Shipamax:

### 'x-shipamax-signature' and 'x-shipamax-signature-version'
A signature value unique for each event.
During the onboarding process, you will receive a secret key that can be used to generate cryptographic hash of the request.

To verify the message, use your secret key to generate an HMAC-SHA256 hash of the body of the HTTP request, and compare this to the value in the `X-Shipamax-Signature` header. If they match, then the message came from Shipamax. If they do not match then the message may have come from a malicious third-party, and should be ignored.

For example with a secret of 12345 and a body of

`{"kind":"#shipamax-webhook","eventName":"Validation/ValidationComplete","payload":{"fileGroupId":13704,"success":false}}`

The resulting hash would be: `da76f9e37775cd072b5dd594926996b1dca3373b82d53756b4cb3cf5c9cafd49`

### 'x-api-key' (optional)
A static token shared between your system and Shipamax. This token will be the same for all webhook events your receive from Shipamax.
During the onboarding process you can provide this shared token.

# Reference

## FileGroups Search Ids Endpoint

| Endpoint                    | Verb | Description                                                 |
| --------------------------- | ---- | ----------------------------------------------------------- |
| /FileGroups/searchIds       | GET  | Get File group IDs                                          |

Get a FileGroup by making a `GET` request to `https://public.shipamax-api.com/api/v2/FileGroups/searchIds`

### URL Parameter Definitions

| Parameter                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| filter                                  | *Required* Filter used to search group ids                        |
| limit                                   | Limit number of ids returned. Max/Default 200                     |
| skip                                    | Amount of rows to skip/offset. Default 0                          |

### Available objects
The following objects can be used as parameters in the *filter*

| Value                                   |  Description                                                       |
| --------------------------------------- | ------------------------------------------------------------------ |
| mailboxTypeId                           | *Required* The Mailbox Validation Type Id                          |
| packStatusId                            | *Required* The Group/Pack status                                   |
| receiveDateFrom                         | The start range for receive date                                   |
| receiveDateTo                           | The end range for receive date                                     |
| postedDateFrom                          | The start range for last posted date                               |
| postedDateTo                            | The end range for last posted date                                 |


> Example of search ids request - The filter object is an encoded JSON string
> You can achieve this on JS like so:
    let filter = {
      mailboxTypeId: 2,
      packStatusId: 3,
      postedDateFrom: '2016-06-01 11:00',
      postedDateTo: '2017-06-01 23:00',
    }
    filter = encodeURIComponent(JSON.stringify(filter))
> /FileGroups/searchIds?filter=%7B%22mailboxTypeId%22%3A2%2C%22packStatusId%22%3A3%2C%22postedDateFrom%22%3A%222016-06-01%2011%3A00%22%2C%22postedDateTo%22%3A%222017-06-01%2023%3A00%22%7D

> An array of groupIds will be returned:

```json
​[5021, 5022, 5054]
```

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
| files/packingList                       | Details of the group's Packing Lists                               |
| files/packingList/lineItem              | List of line items associated with the Packing List                |
| files/apInvoice                         | Details of the Accounts Payable Invoice                            |
| files/apInvoice/cluster                 | List of clusters associated with Payable Invoice                   |
| files/apInvoice/cluster/jobReference    | List of References associated with Payable Invoice's cluster       |
| files/apInvoice/cluster/extractedLine   | List of extracted charge lines associated with Payable invoice's cluster   |
| files/email                             | Details of the Email                                               |


> You can use comma separated values for the include parameter. Example usage of include parameter
>/FileGroups/{file_group_id}?include=files/billOfLading,files/commercialInvoice

> The GET FileGroup when requested with all its inner objects returns JSON structured like this:

```json
​{
  "id": integer,
  "created": "[ISO8601 timestamp]",
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
    "created": "[ISO8601 timestamp]"
  },
  "files": [
    {
      "id": integer,
      "filename": string,
      "created": "[ISO8601 timestamp]",
      "fileType": integer,
      "parent": {
        "fileId": integer
      },
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
          "firstArrivalPort": string,
          "firstArrivalPortUnlocode": string,
          "firstArrivalPortEta": string,
          "ownersReference": string,
          "originEtd": string,
          "destinationEta": string,
          "coLoader": string,
          "coLoaderMblNumber": string,
          "loadPortEtd": string,
          "dischargePortEta": string,
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
              "isConsol": boolean
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
      ]
    },
    {
      "id": integer,
      "filename": string,
      "created": "[ISO8601 timestamp]",
      "fileType": 5:integer,
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
                      "originCountryCode": string,
                      "productCodeMatch": boolean,
                      "hsCode": string,
                      "matchedHsCode": string,
                      "matchedProductCode": string,
                      "matchedDescription": string,
                      "matchedOriginCountryCode": string,
                      "matchedUnitType": string,
                      "matchedClassificationCode": string,
                      "id": integer,
                      "orderIndex": integer,
                      "descriptionCell": string
                  }
              ]
          }
      ]
    },
    {
      "id": integer,
      "filename": string,
      "created": "[ISO8601 timestamp]",
      "fileType": 8:integer,
      "packingList": [
          {
              "documentId": string,
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
              "weightGrossTotal": integer,
              "weightNetTotal": integer,
              "volumeTotal": integer,
              "weightUnit": string,
              "volumeUnit": string,
              "packageUnit": string,
              "packageQuantityTotal": integer,
              "itemUnit": string,
              "itemQtyTotal": integer,
              "id": integer,
              "packingListNumber": string,
              "lineItem": [
                  {
                    "packingListId": integer,
                    "description": string,
                    "marks": string,
                    "itemQty": string,
                    "packageQty": string,
                    "netWeight": integer,
                    "grossWeight": integer,
                    "volume": string,
                    "productCode": string,
                    "hsCode": string,
                    "id": integer,
                    "orderIndex": string,
                    "descriptionCell": string,
                    "fullText": string,
                  }
              ]
          }
      ]
    },
    {
      "id": integer,
      "filename": string,
      "created": "[ISO8601 timestamp]",
      "fileType": 4:integer,
      "apInvoice": [
        {
          "addressee": string,
          "addresseeCode": string,
          "issuer": string,
          "issuerCode": string,
          "invoiceNumber": string,
          "invoiceDate": string,
          "invoiceGrossTotal": float,
          "netTotal": float,
          "vatTotal": float,
          "currency": string,
          "currencyId": integer,
          "validationResultId": integer,
          "reassignTime": string,
          "email": string,
          "website": string,
          "issuerRecordId": string,
          "glCode": string,
          "description": string,
          "departmentCode": string,
          "branchCountry": string,
          "cluster": [
            {
              "total": float,
              "description": string,
              "vatTotal": float,
              "extractedLine": [
                {
                  "service": string,
                  "journey": string,
                  "unitPrice": float,
                  "quantity": float,
                  "currency": string,
                  "lineVat": float,
                  "lineNet": float,
                  "lineGross": float,
                  "exchangeRate": float
                }
              ],
              "jobReference": [
                {
                  "jobRef": string,
                  "bolNum": string,
                  "containerNum": string,
                  "purchaseOrder": sring,
                  "serviceStartDate": "[ISO8601 timestamp]",
                  "serviceEndDate": "[ISO8601 timestamp]"
                },
                {
                  "jobRef": string,
                  "bolNum": string,
                  "containerNum": string,
                  "purchaseOrder": string,
                  "serviceStartDate": "[ISO8601 timestamp]",
                  "serviceEndDate": "[ISO8601 timestamp]"
                }
              ]
            }
          ]
        }
      ]
    },
  ]
}
```

### *FileGroup* root attributes
| Attribute                               | Description                                                                                                                |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------|
| status                                  | Status of the group in the Shipamax flow. Possible values can be seen in our [list of group status](#list-of-group-status) |

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
| files.parent                            | An object that potentially contains the files parent fileId                                                                       |
| files.parent.fileId                     | The parent file ID, if this file is a child                                                                                       |

### *Files/billOfLading* attributes

| Attribute                               | Description                                                                                                                                         |
| --------------------------------------- | -----------------------------------------------------------------------------------------------------------------------------------------------------|
| files.billOfLading                      | An array of bills of lading extracted from this file, if any.                                                                                       |
| files.billOfLading.billOfLadingNo       | The Bill of Lading number as extracted from the document.                                                                                           |
| files.billOfLading.bookingNo            | The Booking reference extracted from the bill of lading. This is the reference provided by Issuer to the Shipper (also known as Carrier Reference). |
| files.billOfLading.exportReference      | The Export Reference as extracted from the document. This is the reference given by the Shipper to the Issuer                                       |
| files.billOfLading.scac                 | This is the SCAC code for the issuer of the Bill of Lading                                                                                          |
| files.billOfLading.isRated              | If isRated is True, then the Bill of Lading contains pricing for the transport of the goods                                                         |
| files.billOfLading.isDraft              | If isDraft is True, then this Bills of Lading is a Draft version and not Final                                                                      |
| files.billOfLading.importerReference    | Importer Job Ref List                                                                                                                               |
| files.billOfLading.shipper              | The raw data extracted for the Shipper field from the bill of lading file                                                                           |
| files.billOfLading.shipperCode          | The code for the selected Shipper (as it appears in the Exception Manager UI, taken from your Organization data)                                    |
| files.billOfLading.shipperOrgId         | The internal ID of the selected Shipper                                                                                                             |
| files.billOfLading.shipperOrgNameId     | The internal ID of the selected name of the Shipper                                                                                                 |
| files.billOfLading.shipperOrgAddressId  | The internal ID of the selected address of the Shipper                                                                                              |
| files.billOfLading.shipperOrgName       | The selected name of the Shipper                                                                                                                    |
| files.billOfLading.shipperOrgAddress    | The selected address of the Shipper                                                                                                                 |
| files.billOfLading.consignee            | The raw data extracted for the Consignee field from the bill of lading file                                                                         |
| files.billOfLading.consigneeCode          | The code for the selected Consignee (as it appears in the Exception Manager UI, taken from your Organization data)                                  |
| files.billOfLading.consigneeOrgId         | The internal ID of the selected Consignee                                                                                                           |
| files.billOfLading.consigneeOrgNameId     | The internal ID of the selected name of the Consignee                                                                                               |
| files.billOfLading.consigneeOrgAddressId  | The internal ID of the selected Address of the Consignee                                                                                            |
| files.billOfLading.consigneeOrgName     | The selected name of the Consignee                                                                                                                  |
| files.billOfLading.consigneeOrgAddress  | The selected Address of the Consignee                                                                                                               |
| files.billOfLading.carrier              | The raw data extracted for the Carrier field from the bill of lading file                                                                           |
| files.billOfLading.carrierCode          | The code for the selected Carrier (as it appears in the Exception Manager UI, taken from your Organization data)                                    |
| files.billOfLading.carrierOrgId         | The internal ID of the selected Carrier                                                                                                             |
| files.billOfLading.carrierOrgNameId     | The internal ID of the selected name of the Carrier                                                                                                 |
| files.billOfLading.carrierOrgAddressId  | The internal ID of the selected Address of the Carrier                                                                                              |
| files.billOfLading.vessel               | The name of the Vessel                                                                                                                              |
| files.billOfLading.vesselIMO            | The IMO code matching the Vessel name                                                                                                               |
| files.billOfLading.voyageNumber         | The number of the Voyage                                                                                                                            |
| files.billOfLading.loadPort             | The name of the Loading Port                                                                                                                        |
| files.billOfLading.loadPortUnlocode     | The UNL code matching the Load Port name                                                                                                            |
| files.billOfLading.dischargePort        | The name of the Discharge Port                                                                                                                      |
| files.billOfLading.dischargePortUnlocode| The UNL code matching the Discharge Port name                                                                                                       |
| files.billOfLading.origin               | The Origin Port                                                                                                                                     |
| files.billOfLading.originUnlocode       | The UNL code matching the Origin name                                                                                                               |
| files.billOfLading.destination          | The Destination Port                                                                                                                                |
| files.billOfLading.destinationUnlocode  | The UNL code matching the Destination name                                                                                                          |
| files.billOfLading.shippedOnBoardDate   | The date the cargo has been loaded on the vessel (SOB date)                                                                                         |
| files.billOfLading.paymentTerms         | The payment terms. See [List of Payment Terms] (#List-of-PaymentTerm-values) for possible values                                                    |
| files.billOfLading.category             | Type of Bill of lading ("True" = Master)                                                                                                            |
| files.billOfLading.releaseType          | The Release Type for this shipment. See [List of Release Types](#List-of-ReleaseType-values) for possible values                                    |
| files.billOfLading.goodsDescription     | Textual description of the goods                                                                                                                    |
| files.billOfLading.transportMode        | The transport type of this shipment. See [List of Transport Modes](#List-of-TransportMode-values) for possible values                               |
| files.billOfLading.containerMode        | The Container's mode. See [List of Container Modes](#List-of-ContainerMode-values) for possible values                                              |
| files.billOfLading.shipmentType         | The shipment type                                                                                                                                   |
| files.billOfLading.consolType           | The consol type                                                                                                                                     |
| files.billOfLading.firstArrivalPort     | The first arrival port                                                                                                                              |
| files.billOfLading.firstArrivalPortUnlocode | The first arrival port's unlocode                                                                                                               |
| files.billOfLading.firstArrivalPortEta  | The first arrival port's ETA                                                                                                                        |
| files.billOfLading.ownersReference      | The owners reference                                                                                                                                |
| files.billOfLading.originEtd            | The origin ETD                                                                                                                                      |
| files.billOfLading.destinationEta       | The destination ETA                                                                                                                                 |
| files.billOfLading.coLoader             | The co loader                                                                                                                                       |
| files.billOfLading.coLoaderMblNumber    | The co loader's MBL number                                                                                                                          |
| files.billOfLading.loadPortEtd          | The load port's ETD                                                                                                                                 |
| files.billOfLading.dischargePortEta      | The dispatch port's ETA                                                                                                                             |

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

#### Using the lineItem attributes to determine the product code and description
The attributes extracted from an invoice for each line item (eg. Product code, description, HS Code, Origin and Unit) are available in the attributes `productCode`, `description`, `hsCode`, `originCountryCode`, `unitType`.

When a line item is successfully matched to a product code from your company’s product code database, the matched values, taken from your product code database, are available in the ‘matched’ attributes (eg. `matchedproductCode`, `matchedDescription`, `matchedHsCode`, `matchedoriginCountryCode`, `matchedUnitType`)

To determine if a line item was matched, use the productCodeMatched attribute:

`productCodeMatched=true` - The line item was successfully matched
`productCodeMatched=false` - the line item was not matched

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
| files.commercialInvoice.lineItem.originCountryCode            |  The origin (2 letters code) country of the unit in the line item            |
| files.commercialInvoice.lineItem.productCodeMatch            |   Indicate if the product code extracted matched a code taken from your product code data.       |
| files.commercialInvoice.lineItem.hsCode            |   The HS Code of this line item.             |
| files.commercialInvoice.lineItem.matchedHsCode            | The hsCode taken from your product data, if there was a match.        |
| files.commercialInvoice.lineItem.matchedProductCode            | The product taken from your product data, if there was a match (productCodeMatch = true).        |
| files.commercialInvoice.lineItem.matchedDescription            | The description taken from your product data, if there was a match.     |
| files.commercialInvoice.lineItem.matchedOriginCountryCode            |  The origin country of the unit taken from your product data, if there was a match.           |
| files.commercialInvoice.lineItem.matchedUnitType            |  The type of the unit taken from your product data, if there was a match.            |
| files.commercialInvoice.lineItem.matchedClassificationCode            |  The classification / tariff lookup code, if there was a match.            |
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

### *Files/apInvoice/Cluster* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files.apInvoice.cluster.total   | The cluster total, subtotal of the invoice                                                 |
| files.apInvoice.cluster.description | Textual description of a cluster on the invoice                                                 |
| files.apInvoice.cluster.vatTotal         | Total tax amount of the cluster                                                  |
| files.apInvoice.cluster.jobReference.jobRef         | The shipment or consol reference                                 |
| files.apInvoice.cluster.jobReference.bolNum         | The Bol Number                                                      |
| files.apInvoice.cluster.jobReference.containerNum         | The Container  Number                                                      |
| files.apInvoice.cluster.jobReference.purchaseOrder         | The Purchase Order                                                     |
| files.apInvoice.cluster.jobReference.serviceStartDate         |  The Service start date                                                    |
| files.apInvoice.cluster.jobReference.serviceEndDate         | The Service end date                                                      |
| files.apInvoice.cluster.extractedLine.service         | The service of the charge line       |
| files.apInvoice.cluster.extractedLine.journey         | The Journey of the charge Line       |
| files.apInvoice.cluster.extractedLine.unitPrice         | The Unit price of the charge Line         |
| files.apInvoice.cluster.extractedLine.quantity         | The quantity of the charge Line         |
| files.apInvoice.cluster.extractedLine.currency         | The currency of the charge Line        |
| files.apInvoice.cluster.extractedLine.lineVat         | Total tax amount of the charge line        |
| files.apInvoice.cluster.extractedLine.lineGross         | The Gross value of the charge Line     |
| files.apInvoice.cluster.extractedLine.exchangeRate         | The exchange rate of the charge line       |

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

### *Files/packingList* attributes

| Attribute                               |  Description                                                                                                                      |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| files.packingList                       | An array of packing invoices extracted from this file, if any. |
| files.packingList.documentId            | The internal ID of the packing list document. |
| files.packingList.supplier              | The raw data extracted for the supplier field from the packing list file. |
| files.packingList.supplierCode          | The code for the selected supplier (as it appears in the Exception Manager UI) taken from your Organization data. |
| files.packingList.supplierOrgId         | The internal ID of the selected supplier. |
| files.packingList.supplierOrgNameId     | The internal ID of the selected name of the supplier. |
| files.packingList.supplierOrgName       | The selected name of the supplier. |
| files.packingList.supplierOrgAddressId  | The internal ID of the selected Address of the supplier |
| files.packingList.supplierOrgAddress    | The selected Address of the supplier. |
| files.packingList.importer              | The raw data extracted for the importer field from the packing list file. |
| files.packingList.importerCode          | The code for the selected importer (as it appears in the Exception Manager UI), taken from your Organization data. |
| files.packingList.importerOrgId         | The internal ID of the selected importer. |
| files.packingList.importerOrgNameId     | The internal ID of the selected name of the importer. |
| files.packingList.importerOrgName       | The selected name of the importer. |
| files.packingList.importerOrgAddressId  | The internal ID of the selected Address of the importer. |
| files.packingList.importerOrgAddress    | The selected Address of the importer. |
| files.packingList.invoiceNumber         | The packing list invoice number. |
| files.packingList.invoiceDate           | The packing list invoice date. |
| files.packingList.weightGrossTotal      | The packing lists total gross weight. |
| files.packingList.weightNetTotal        | The packing lists total net weight. |
| files.packingList.volumeTotal           | The packing lists total volume. |
| files.packingList.weightUnit            | The packing lists weight unit. |
| files.packingList.volumeUnit            | The packing lists volume unit. |
| files.packingList.packageUnit           | The packing lists package unit type. |
| files.packingList.itemUnit              | The packing lists item unit. |
| files.packingList.itemQtyTotal          | The packing lists total item quanity. |
| files.packingList.id                    | The internal ID of the packing list. |
| files.packingList.packingListNumber     | The packing list number. |

#### Using the lineItem attributes to determine the product code and description
The attributes extracted from an invoice for each line item (eg. Product code, description, HS Code, Origin and Unit) are available in the attributes `productCode`, `description`, `hsCode`, `originCountryCode`, `unitType`.

### *Files/packingList/lineItem* attributes

| Attribute                            | Description                               |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------  |
| files.packingList.lineItem.packingListId   | The internal ID of the line items packing list. |
| files.packingList.lineItem.description     | The description of the line item. |
| files.packingList.lineItem.marks           | The line item marks. |
| files.packingList.lineItem.itemQty         | The line items total item quantity. |
| files.packingList.lineItem.packageQty      | The line items total package quantity. |
| files.packingList.lineItem.netWeight       | The line items net weight. |
| files.packingList.lineItem.grossWeight     | The line items gross weight. |
| files.packingList.lineItem.volume          | The line items volume. |
| files.packingList.lineItem.productCode     | The code for the product in the line item. |
| files.packingList.lineItem.hsCode          | The HS Code of this line item. |
| files.packingList.lineItem.id              | The internal ID of the line item. |
| files.packingList.lineItem.orderIndex      | The index of the line, representing the order of it within the commercial invoice. |

> Example of request without include parameter:
> /FileGroups/1

```json
{
  "id": 1,
  "created": "2020-05-07T15:24:47.338Z",
  "status": 1
}
```

> Example of request with lastValidationResult and files included:
> /FileGroups/2?include=lastValidationResult,files

```json
{
  "id": 2,
  "created": "2020-05-07T15:24:47.338Z",
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
    "created": "2020-05-07T15:24:47.509Z"
  },
  "files": [
    {
      "id": 442,
      "filename": "file.pdf",
      "created": "2020-05-07T15:24:47.338Z",
      "fileType": 6
    }
  ]
}
```

> Example of request with all inner objects included:
> /FileGroups/1?include=lastValidationResult,files/billOfLading/importerReference,files/billOfLading/notify,
> files/billOfLading/container/seals,files/billOfLading/packline
> files/commercialInvoice,files/commercialInvoice/lineItem,files/apInvoice/cluster/extractedLine,files/apInvoice/cluster/jobReference,files/email,files/parent
> files/packingList,files/packingList/lineItem

```json
{
  "id": 1,
  "created": "2020-05-07T15:24:47.338Z",
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
    "created": "2020-05-07T15:24:47.509Z"
  },
  "files": [
    {
      "id": 442,
      "filename": "file.pdf",
      "created": "2020-05-07T15:24:47.338Z",
      "fileType": 4,
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
      "parent": {
        "fileId": 22
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
          "reassignTime": "2020-07-03",
          "email": "invoice@invoice.com",
          "website": "www.invoice.com",
          "issuerRecordId": "1-1-1",
          "glCode": "1300.00.00",
          "description": "This is an invoice",
          "departmentCode": "DEPTCODE",
          "branchCountry": "Lithuania",
          "cluster": [
            {
              "total": 100,
              "description": null,
              "vatTotal": 5,
              "extractedLine": [
                {
                  "service": "A2",
                  "journey": "B2",
                  "unitPrice": 10,
                  "quantity": 10,
                  "currency": "EUR",
                  "lineVat": 20,
                  "lineNet": 80,
                  "lineGross": 100,
                  "exchangeRate": 1.3,
                  "id": 2
                }
              ],
              "jobReference": [
                {
                  "jobRef": "C00000118",
                  "bolNum": null,
                  "containerNum": null,
                  "purchaseOrder": null,
                  "serviceStartDate": null,
                  "serviceEndDate": null
                },
                {
                  "jobRef": "C00000119",
                  "bolNum": null,
                  "containerNum": null,
                  "purchaseOrder": null,
                  "serviceStartDate": null,
                  "serviceEndDate": null
                }
              ]
            }
          ]
        }
      ],
      "billOfLading": [],
      "commercialInvoice": [],
      "packingList": []
    },
    {
      "id": 443,
      "filename": "file2.pdf",
      "created": "2020-05-07T15:24:47.338Z",
      "fileType": 6,
      "email": {
        "customId": "custom001",
        "emailAccountId": 1,
        "sender": "test@shipamax.com",
        "created": "2020-05-07T15:34:47.338Z",
        "attachmentCount": 1,
        "companyId": 100000,
        "subject": "Sending file",
        "unqId": "6f847a63-bd99-4b79-965c-128ea9b3f104"
      },
      "parent": {
        "fileId": 22
      },
      "apInvoice": [],
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
          "consolType": "",
          "firstArrivalPortUnlocode": "",
          "firstArrivalPortEta": "2020-05-07T15:24:47.338Z",
          "ownersReference": "",
          "originEtd": "2020-05-07T15:24:47.338Z",
          "destinationEta": "2020-05-07T15:24:47.338Z",
          "coLoader": "",
          "coLoaderMblNumber": "",
          "loadPortEtd": "2020-05-07T15:24:47.338Z",
          "dischargePortEta": "2020-05-07T15:24:47.338Z",
          "notify": [
            {
              "id": 211,
              "notifyParty": "",
              "notifyPartyCode": "TEST123",
              "notifyPartyOrgId": 11121,
              "notifyPartyOrgNameId": 22133,
              "notifyPartyOrgAddressId": 12312
            }
          ],
          "importerReference:": [
            {
              "id": 322,
              "importerReference": "C0000001",
              "isConsol": true
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
      "commercialInvoice": [],
      "packingList": []
    },
    {
      "id": 444,
      "filename": "file3.pdf",
      "created": "2020-05-07T15:44:35.338Z",
      "fileType": 5,
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
      "parent": {
        "fileId": 22
      },
      "apInvoice": [],
      "billOfLading": [],
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
              "origin": "Mexico",
              "originCountryCode": "MX",
              "productCodeMatch": false,
              "hsCode": "1234567890",
              "matchedHsCode": "1234567890",
              "matchedProductCode": null,
              "matchedDescription": "ITEM DESCRIPTION",
              "matchedOriginCountryCode": "MX",
              "matchedUnitType": "NO",
              "matchedClassificationCode": null,
              "id": 1,
              "orderIndex": 0,
              "descriptionCell": "ITEM DESCRIPTION 1"
            }
          ]
        }
      ],
      "packingList": []
    },
    {
      "id": 555,
      "filename": "file3.pdf",
      "created": "2020-05-07T15:44:35.338Z",
      "fileType": 5,
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
      "parent": {
        "fileId": 22
      },
      "apInvoice": [],
      "billOfLading": [],
      "commercialInvoice": [],
      "packingList": [
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
          "weightGrossTotal": 2607.92,
          "weightNetTotal": 2607.92,
          "volumeTotal": 500.05,
          "weightUnit": "kgs",
          "volumeUnit": "cbm",
          "packageUnit": "BAG",
          "packageQuantityTotal": 1000.60,
          "itemUnit": "BOT",
          "itemQtyTotal": 5,
          "id": 1,
          "packingListNumber": "PKL123",
          "lineItem": [
            {
              "description": "ITEM DESCRIPTION",
              "marks": "",
              "itemQty": 10,
              "packageQty": 24.95,
              "netWeight": 199.6,
              "grossWeight": 199.6,
              "volume": 500.05,
              "productCode": null,
              "hsCode": "1234567890",
              "id": 1,
              "orderIndex": 0,
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

## Organizations Endpoint
The Organizations list represents businesses that might be referenced in the documents you send Shipamax to processes (for example, the Shipper on a House Bill of Lading, a Supplier on a Commercial Invoice Creditor etc.). The organization list is used to improve the accuracy of the parsing process, making sure the most likely organization is selected.
Each Organization must have a unique identifier provided by you (referred to as `externalId`), this is usually the identifier used in your own system.
Each organization added is assigned an internal ID unique to Shipamax (referred to as `org_id`). This ID is required in order to DELETE/PATCH the organization as well as adding Names and Addresses to the Organization

### Attributes

| Attribute                               | Description                                                                                       |
| --------------------------------------- |---------------------------------------------------------------------------------------------------|
| id                 | Unique identifier of the Organization within the Shipamax system                                  |
| externalId                               | Unique identifier of the Organization within your own system                                      |
| carrier                       | Flag for denoting this Organization is a carrier                                                  |
| consignee                       | Flag for denoting this Organization is a consignee                                                |
| creditor                       | Flag for denoting this Organization is a creditor                                                 |
| forwarder                       | Flag for denoting this Organization is a forwarder                                                |
| debtor                       | Flag for denoting this Organization is a debtor                                                   |
| shipper                       | Flag for denoting this Organization is a shipper (also referred to as Consignor or Shipping Agent) |
| active                       | Flag denoting whether this Organization is active or not                                          |
| updated | The timestamp of when the Organization was last updated                                           |


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
  "active": false
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

### GET (list of Organisation using Filter)
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
Delete an Organization. Instead of an actual delete of the Organization it sets the flag `active` to `FALSE`, so it can be still displayed for existing documents.

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
  "name": "NewName",
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
Delete an existing Organization's Name. Instead of an actual delete of the Organization's Name it sets the flag `active` to `FALSE`, so it can be still displayed for existing documents.

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
Delete an existing Organization's Address. Instead of an actual delete of the Organization's Address it sets the flag `active` to `FALSE`, so it can be still displayed for existing documents.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /OrganizationAddresses/{addr_id} | DELETE  | Not required | Number of deleted objects |

-----

## Products Endpoint
The product reference data is used to improve the accuracy of the line item parsing, making it more likely that the correct product is associated with each line.
During the processing of a Commercial Invoice, Shipamax will attempt to match the parsed data with the available product reference data. If a match is found, the product reference data (product code, description, type and HS Code) will be used instead of the parsed data.

The Product endpoint allows you to send Shipamax any changes/additions to your product reference data in real-time and keep it up-to-date with your TMS system.

### Attributes

| Attribute                               |  Description                                                      |
| --------------------------------------- | ----------------------------------------------------------------- |
| id                 | Unique identifier of the Product within the Shipamax system |
| productCode                               | The code of the Product within your own system           |
| owner                       | Unique identifier of the owner (eg. importer) of the product within your own system     |
| supplier                       | Unique identifier of the supplier of the product within your own system     |
| description                       | Description of the product  |
| unitType                       | The unit the product is quantified by   |
| tariff                       | The tariff (eg. HS Code) for the product   |
| lookupCode                   | The tariff lookup code |
| origin                       | The origin country of the product |



### POST
Create a new Product

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /ReferenceProducts                   | POST  | Product's details in JSON    |  The new Product object in JSON           |

> **Body structure for POST Products request:**

```json
{
    "productCode": string,
    "owner": string,
    "supplier": string,
    "description": string,
    "unitType": string,
    "tariff": string,
    "lookupCode": string,
    "origin": string
}
```

> **Example:** POST Product request body

```json
{
    "productCode": "CODEABC",
    "owner": "TRRRRFF",
    "supplier": "BRRRRGG",
    "description": "Description of product",
    "unitType": "PKG",
    "tariff": "123456",
    "lookupCode": "12345",
    "origin": "GB"
}
```

> **Example:** POST Product response

```json
{
  "id": 35,
  "productCode": "CODEABC",
  "owner": "TRRRRFF",
  "supplier": "BRRRRGG",
  "description": "Description of product",
  "unitType": "PKG",
  "tariff": "123456",
  "lookupCode": "12345",
  "origin": "GB"
}
```

### GET (specific Product)
Retrieve details of a an existing Product reference by using the product code from your system.
If there are multiple product with the same code they will all be included in the response.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /ReferenceProducts/{product_code} | GET | Not required | An Product object in JSON |


> **Example:** GET Product response

```json
{
  "id": 35,
  "productCode": "CODEABC",
  "owner": "TRRRRFF",
  "supplier": "BRRRRGG",
  "description": "Description of product",
  "unitType": "PKG",
  "tariff": "123456",
  "origin": "GB"
}
```

### GET (list of Organisation using Filter)
Retrieve list of Products that match a filter.
**Note:** When filter is included, Shipamax will return only the Products matching the requested pattern.

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /ReferenceProducts | GET | Filter string in JSON | An array of products objects in JSON |


> **Body structure for GET Product request using filter**

```json
{
  "filter": {
    "where": {
      "and": [
        {
          "productCode": "TRRRRFF"
        },
        {
          "supplier": "BRRRRGG"
        }
      ]
    }
  }
}
```

### PATCH
Update details of an existing Product

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /ReferenceProducts/{product_id} | PATCH | The updated Product details in JSON |

> **JSON structure for PATCH Product request**

```json
{
  "productCode": "TRFHEED",
  "owner": "BRFGHH"
}
```

> **Example:** PATCH response with the updated Product as JSON like this:

```json
{
  "id": 35,
  "productCode": "CODEABC",
  "owner": "TRRRRFF",
  "supplier": "BRRRRGG",
  "description": "Description of product",
  "unitType": "PKG",
  "tariff": "123456",
  "origin": "GB"
}
```

### DELETE
Delete a Product

| Endpoint                         | Verb  | Body                              | Response                                       |
| -------------------------------- | ----- | ----------------------------------| ---------------------------------------------- |
| /ReferenceProducts/{product_id} | DELETE | Not required | Number of deleted products |


> **Example:** DELETE Product response

```json
{
  "count": 1
}
```
-----

## Files Endpoint

### GET Original File

You can retrieve all files processed by Shipamax. For example you can retrieve a bill of lading which was sent to Shipamax as an attachment to an email. Files can be retrieved via their unique ID. The response of the endpoint is a byte stream.

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
  "id": 000000
}
```

If a mailbox is configured to have one file per group, you will receive an array response like this:
```json
[{
  "customId": "CUSTOM_ID",
  "filename": "FILE_NAME",
  "groupId": 00000,
  "id": 000000
},
{
  "customId": "CUSTOM_ID2",
  "filename": "FILE_NAME2",
  "groupId": 00001,
  "id": 000001
}]
```

## Cargowise References Endpoint

You are able to send Cargowise reference data (XML) directly to Shipamax. The endpoint takes the content-type as `text/xml`, and the request body as raw data. The endpoint will respond with a `text/xml`.

The Cargowise reference request will then be saved to the database, interpreted as UTF-8 encoded text, and added to a queue to be processed later on a first come first served basis, hence the API endpoint will mostly always return success status.
If the request is empty an error will be returned.

| Endpoint                      | Verb   | Description                                                 |
| ----------------------------- | ------ | ----------------------------------------------------------- |
| /CargowiseReferences/send     | POST   | Send Cargowise reference data                               |

Send Cargowise reference data (xml) by making a `POST` request to
`https://public.shipamax-api.com/api/v2/CargowiseReferences/send`

This endpoint can be used to send Organization/Container Number/Product Code reference data.
How to send each of these format has been explained in this document below.

### Organization data:

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

### Container reference data:

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

### Product code data:

There are two formats you can use to send product code updates: Legacy (`XmlInterchange`) or Native (`UniversalInterchange`).

#### **Native**
This uses the `<UniversalInterchange>` xml format. The XML tag `<Product>` wraps all the relevant data.
The following elements will be processed form the XML:

| Section                       | Elements                                                    |
| ------------------------------| ----------------------------------------------------------- |
| OrgSupplierPart               | PartNum, StockKeepingUnit, Desc                             |
| CusClassPartPivotCollection   | Tariff                                                    |
| CusClassification             |  LookupCode, OrgHeader, Relationship                      |
  

> Product code update example with Native xml (`UniversalInterchange`) format:
    
```xml
<?xml version="1.0" encoding="utf-8"?>
<UniversalInterchange xmlns="http://www.cargowise.com/Schemas/Universal/2011/11">
    <Header>
        <SenderID>TESTSENDER</SenderID>
        <RecipientID>EVT-SHIPAMAX</RecipientID>
    </Header>

    <Body>
        <Native version="2.0" xmlns="http://www.cargowise.com/Schemas/Native/2011/11">
            <Header>
                <OwnerCode>TESTCODE</OwnerCode>
                <EnableCodeMapping>true</EnableCodeMapping>
                <nv:DataContext xmlns="http://www.cargowise.com/Schemas/Universal/2011/11" xmlns:nv="http://www.cargowise.com/Schemas/Native/2011/11">
                    <DataSourceCollection>
                        <DataSource>
                            <Type>Product</Type>
                            <Key>TESTCODE</Key>
                        </DataSource>
                    </DataSourceCollection>
                    <Company>
                        <Code>TST</Code>
                        <Country>
                            <Code>US</Code>
                            <Name>United States</Name>
                        </Country>
                        <Name>Shipamax ltd test company</Name>
                    </Company>
                    <EnterpriseID>ENT</EnterpriseID>
                    <EventType>
                        <Code>ADD</Code>
                        <Description>Added a record to the system</Description>
                    </EventType>
                    <EventBranch>
                        <Code>BRN</Code>
                        <Name>Shipamax ltd Brunch</Name>
                    </EventBranch>
                </nv:DataContext>
            </Header>
            <Body>
                <Product version="2.0">
                    <OrgSupplierPart Action="MERGE">
                        <PartNum>ProductCode</PartNum>
                        <StockKeepingUnit>NO</StockKeepingUnit>
                        <Desc>3732 - CONNECTOR ANCHORAGE 1/2" CLEAR CHROMATE</Desc>
                        <CusClassPartPivotCollection>
                            <CusClassPartPivot Action="MERGE">
                                <TariffNum>7326908688</TariffNum>
                                <CusClassificationCollection>
                                    <CusClassification Action="MERGE">
                                        <CountryCode>AU</CountryCode>
                                        <LookupCode>84148020-62</LookupCode>
                                    </CusClassification>
                                    <CountryOfOrigin TableName="RefDbEntUS_USCCountry" />
                                </CusClassificationCollection>
                            </CusClassPartPivot>
                        </CusClassPartPivotCollection>
                        <OrgPartRelationCollection>
                            <OrgPartRelation Action="MERGE">
                                <Relationship>OWN</Relationship>
                                <OrgHeader>
                                    <Code>LJBILM</Code>
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
 #### **Legacy**
This uses the `<XmlInterchange>` format. The XML tag `<Products>` wraps all the relevant data.
The following elements are processed from the XML:
    
| Section                       | Elements                                                    |
| ------------------------------| ----------------------------------------------------------- |
| Product                       | ProductCode, ProductDescription, StockUnit                  |
| RelatedOrganization           |  OwnerCode, RelationshipType                               |
    
> Product code update example with Legacy xml (`XmlInterchange`) format:

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

Cargowise Reference endpoint can also accept SOAP message which is a Cargowise default i.e, Request that starts with tag <s: Envelope>, Or
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

## Lists of codes for fields

Several fields listed in the sections above should usually only contain specific values from a known list. For example, where the type of the `releaseType` field of a billOfLading is given as `ReleaseType`, it means that the expected set of values comes from the [list of ReleaseType values](#list-of-releasetype-values).

These values are show in the following lists.

### List of ExceptionCode values

Exception codes other than -1 have a specific meaning within the Shipamax system, as listed in the table below. When creating a validation result you should use an existing code where there is an appropriate one available, or -1 if there is not. You can use any description you like for any code, but the default descriptions for each code that Shipamax generates are listed in the table.


| Exception code | Description                                                                                                                                                               |
|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1              | Missing Info: Missing Invoice Number                                                                                                                                      
| 2              | Missing Info: Missing Invoice Date                                                                                                                                        
| 3              | Missing Info: Missing Issuer                                                                                                                                              
| 4              | Missing Info: Missing Invoice Total                                                                                                                                       
| 5              | Missing Info: Missing Invoice Currency                                                                                                                                    
| 6              | Missing Info: No Job references                                                                                                                                           
| 7              | Business Validation Failure: Invalid Addressee                                                                                                                            
| 8              | Business Validation Failure: Duplicate Invoice Number                                                                                                                     
| 9              | Costs: Failed to match a set of accruals to the Invoice Total                                                                                                             
| 10             | CargoWise: Currencies didn't match                                                                                                                                        
| 11             | Costs: Tax amounts on accruals do not sum to invoice tax total                                                                                                            
| 12             | Error: Request to TMS failed.                                                                                                                                             
| 13             | Costs: Multiple possible accrual combinations                                                                                                                             
| 14             | Error: Missing Issuer Code                                                                                                                                                
| 16             | Demo: Document passed validation                                                                                                                                          
| 17             | Business Validation Failure: Invoice date is in the future                                                                                                                
| 18             | Error: Job not found                                                                                                                                                      
| 19             | Error: Request to TMS failed                                                                                                                                              
| 20             | Error in validation process                                                                                                                                               
| 21             | Business Validation Failure: (Unallocated) Invoice Number already exists                                                                                                  
| 22             | Bill of Lading: Missing MBL                                                                                                                                               
| 23             | Multiple MBLs. Pack can include 0 or 1 MBL. Change the type of the extra MBLs and/or split the pack                                                                       
| 24             | Consol: Receiving Agent might be incorrect for the selected Consol Type                                                                                                   
| 25             | Bill of Lading: Missing HBLs                                                                                                                                              
| 26             | Manual approval required to post                                                                                                                                          
| 27             | Unable to Match to Job                                                                                                                                                    
| 28             | Multiple possible Jobs                                                                                                                                                    
| 29             | Bill of Lading: Missing References                                                                                                                                        
| 30             | Bill of Lading: Missing SCAC                                                                                                                                              
| 31             | Supplied job reference does not exist in CargoWise                                                                                                                        
| 32             | Bill of Lading: MBL missing Consignee                                                                                                                                     
| 33             | Error: Documents exceeds maximum file size limit: X MB                                                                                                                   
| 34             | Costs: Net subtotals do not sum to invoice total                                                                                                                          
| 35             | Costs: Multiple possible accrual combinations                                                                                                                             
| 36             | Costs: Failed to match a set of accruals for highlighted sub total                                                                                                        
| 38             | Bill of Lading: Missing consignor/consignee                                                                                                                               
| 39             | Bill of Lading: Missing origin                                                                                                                                            
| 40             | Bill of Lading: Missing destination                                                                                                                                       
| 41             | Bill of Lading: Missing container mode                                                                                                                                    
| 42             | Bill of Lading: Missing release type                                                                                                                                      
| 43             | Bill of Lading: Missing packing mode                                                                                                                                      
| 44             | Costs: No accruals found for this creditor                                                                                                                                
| 45             | Error in validation process                                                                                                                                               
| 46             | Error in CargoWise validator                                                                                                                                              
| 47             | Commercial Invoice: Mixed invoice/bill groups must be MBL and CI                                                                                                          
| 48             | Commercial Invoice: Invoice number missing                                                                                                                                
| 49             | Commercial Invoice: Gross total missing                                                                                                                                   
| 50             | Costs: Failed to find a matching Job Ref for highlighted BL or Container Number                                                                                           
| 51             | Costs: No accruals found for this creditor on highlighted sub total                                                                                                       
| 52             | Commercial Invoice: Supplier missing                                                                                                                                      
| 53             | Commercial Invoice: Importer missing                                                                                                                                      
| 54             | Commercial Invoice: One or more product codes could not be found                                                                                                          
| 55             | Commercial Invoice: One or more product codes not associated with Importer or Exporter                                                                                    
| 56             | Commercial Invoice: Mixed group has more than 1 MBL                                                                                                                       
| 57             | Commercial Invoice: Mixed group has more than 1 CI                                                                                                                        
| 58             | Commercial Invoice: Mixed groups do not support HBLs                                                                                                                      
| 59             | Container number: No reference found for highlighted job                                                                                                                  
| 60             | Container number: Multiple references found for highlighted job                                                                                                           
| 61             | Error: Too many accruals to automatically find a match. Please select the correct costs manually                                                                          
| 62             | Commercial Invoice: Mixed group has more than 1 HBL                                                                                                                       
| 63             | Multiple MBLs. This pack can’t be used to create a Brokerage Job. Recategorise the extra MBL(s) or split the pack                                                         
| 64             | Business Validation Failure: Accruals in TMS have changed since previous updates were made in Shipamax.                                                                   
| 65             | Business Validation Failure: Other accruals with the same charge code detected on the same Job. Posting these accruals may delete information in CargoWise                
| 66             | Costs: Modified accrual amounts are not within the tolerated threshold                                                                                                    
| 67             | Job Reference: Reference extracted from email subject                                                                                                                     
| 68             | Job Reference: Unable to set job references; multiple references found                                                                                                    
| 69             | Error: CargoWise: Failed to post file to EDocs                                                                                                                            
| 70             | Commercial Invoices: No CIVs found in document pack                                                                                                                       
| 71             | Job Reference: Multiple S-Job references found in email subject. If you know the job reference, create a S-Job place holder and update the reference before posting to CW 
| 72             | CargoWise: Missing job reference                                                                                                                                          
| 73             | Job Reference REF is not valid CONSOL/SHIPMENT reference                                                                                                                                
| 74             | Error fetching costs from CargoWise                                                                                                                                       
| 75             | Error posting invoice to CargoWise                                                                                                                                        
| 76             | Error while validating costs                                                                                                                                              
| 77             | Error posting invoice to TMS                                                                                                                                              
| 78             | Business Validation Failure: Duplicate Invoice Number                                                                                                                     
| 79             | Error: Failed to post to TMS. Please try again.                                                                                                                           
| 80             | Error fetching costs from TMS.                                                                                                                                            
| 81             | Costs: Tax subtotals do not sum to invoice total                                                                                                                          
| 82             | Missing Info: Missing GL Code                                                                                                                                             
| 83             | Missing Info: Missing Description                                                                                                                                         
| 84             | Missing Info: Missing Net Total                                                                                                                                           
| 85             | Missing Info: Missing Tax Code                                                                                                                                            
| 86             | Missing Info: Missing Tax Amount                                                                                                                                          
| 87             | Missing Info: Missing Tax Total                                                                                                                                           
| 88             | Line Items: Gross Total does not match Line Total Sum for one or more Commercial Invoices                                                                                 
| 89             | CargoWise: Declaration is locked. Make sure it is not worked on and try again                                                                                             
| 90             | CargoWise: Job verification failed, please try to post again. If problem persists, please raise an eRequest.                                                              
| 91             | Shipment: Duplicate HBL numbers                                                                                                                                           
| 92             | Commercial Invoice: Duplicate CIV numbers                                                                                                                                 
| 93             | Costs: Invalid accrual split                                                                                                                                              
| 94             | Consol: Missing MBL and Consol reference. Posting will create a new, empty Consol                                                                                         
| 95             | CargoWise: Pack is missing HBL and a Shipment reference for one or more Shipments. Posting will create a new, empty Shipment                                              
| 96             | Reference mismatch: Shipment REF not found in CargoWise                                                                                                                  
| 97             | Reference mismatch: Consol REF not found in CargoWise                                                                                                                    
| 98             | Reference mismatch: Shipment REF is linked to an existing Consol (CONSOL_REF) in Cargowise                                                                                     
| 99             | Shipment: Duplicate S-ref numbers                                                                                                                                         
| 100            | Consol: Pack includes a Consol reference. Posting will update an existing Consol                                                                                          
| 101            | Costs: Modified exchange rate is not within the tolerated threshold                                                                                                       
| 102            | Total packages' volume in CW for job REF (Xm3) differ from HBL                                                                                                            
| 103            | Total packages' weight in CW for job REF (Xkg) differ from HBL                                                                                                            
| 104            | Could not compare volumes for job REF - Multiple unit types in HBL                                                                                                         
| 105            | Could not compare weights for job REF - Multiple unit types in HBL                                                                                                         
| 106            | Business Validation Failure: Consol costs must have all sub-shipment apportioned costs posted at once                                                                     
| 107            | Multiple HBLs. This pack can’t be used to create a Brokerage Job. Recategorise the extra HBL(s) or split the pack                                                         
| 108            | Multiple HBLs in zip file. Grouping was not created                                                                                                                       
| 109            | There exists another open invoice with this invoice number                                                                                                                
| 111            | Reference update: BL NUMBER found in Cargowise. Job card updated with the matching reference                                                                                 
| 112            | Reference mismatch: BL NUMBER does not match job REF in Cargowise                                                                                                            
| 113            | Reference mismatch: BL NUMBER is associated with Shipment SHIPMENT_REF that is linked to an existing Consol (CONSOL_REF) in Cargowise                                                     
| 114            | Difference between the accrued local costs and the updated local costs exceeds the tolerated exchange rate threshold of X CUR or Y% per Job                              
| 115            | Commercial Invoice: Importer Name Missing                                                                                                                                 
| 116            | Commercial Invoice: Importer Address Missing                                                                                                                              
| 117            | Commercial Invoice: Supplier Name Missing                                                                                                                                 
| 118            | Commercial Invoice: Supplier Address Missing                                                                                                                              
| 119            | Master Bill of Lading: Sending Agent Name Missing                                                                                                                         
| 120            | Master Bill of Lading: Sending Agent Address Missing                                                                                                                      
| 121            | Master Bill of Lading: Receiving Agent Name Missing                                                                                                                       
| 122            | Master Bill of Lading: Receiving Agent Address Missing                                                                                                                    
| 123            | Master Bill of Lading: Carrier Missing                                                                                                                                    
| 124            | House Bill of Lading: Shipper Name Missing                                                                                                                                
| 125            | House Bill of Lading: Shipper Address Missing                                                                                                                             
| 126            | House Bill of Lading: Consignee Name Missing                                                                                                                              
| 127            | House Bill of Lading: Consignee Address Missing                                                                                                                           
| 128            | Bill of Lading: Missing Bill of Lading Number                                                                                                                             
| 129            | Failed to update accruals to avoid rollup up of costs with same charge code                                                                                               
| 130            | Commercial Invoice: Total, QTY and PPU do not match for some of the line items. Review the highlighted line items before posting                                          |
| -1             | Custom exception                                                                                                                                                          |

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
| 20TK          | Twenty foot tank                 |

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
| PK          | Package            |
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
