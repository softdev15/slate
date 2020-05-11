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

The base URI for all API endpoints is `https://public.shipamax-api.com/api/v2/`.

### Content type

Unless specified otherwise, requests with a body attached should be sent with a `Content-Type: application/json` HTTP header.

# Authorization

All API methods require you to be authenticated. Once you have your access token, which will be given to you by the Shipamax Team, you can send it along with any API requests you make in a header. If your access token was `abc123token`, you would send it as the HTTP header `Authorization: bearer abc123token`.

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
    "exceptions": [EXCEPTION-LIST]
   }
}
```
  
Details of body definition:  
​  
Event names:  
- Validation/BillOfLadingGroup/Failure  
- Validation/BillOfLadingGroup/Success  
​
> Exception list contains exception objects:

```javascript
{
 "code": ExceptionCode,  
 "description": string  
}
```

> Example of body sent via webhook:

```javascript
{
  "kind": "#shipamax-webhook",
  "eventName": "Validation/BillOfLadingGroup/Failure",
  "payload": {
     "id": 1,
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
     "id": 1,
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

Shipamax groups files that are assoicated with each other into a FileGroup. For example, you may have received a Master BL with associated House BLs and these will be contained within the same FileGroup.   
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
            "id": inteher,
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
  -H "Authorization: bearer {TOKEN}"
```

## Exception

For a full workflow Shipamax requires the customer to provide Exception information via API.

Get a group by making a `POST` request to `https://public.shipamax-api.com/api/v2/Exception/{BL-Group-id}`
