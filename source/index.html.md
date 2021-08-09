---
title: Shipamax Customs Declarations API Reference

toc_footers:
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>


search: true
---

# Getting started

The Shipmax Customs Declarations API allows developers to submit customs declarations to authorities, like HMRC.

If you would like to use this API and are not already a Shipamax Customs Declarations customer, please contact our [support team](mailto:support@shipamax.com).


## Workflow

CCC

## API basics

The API is [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_Web_services), and messages are encoded as JSON documents

### Endpoint

The base URI for all API endpoints is `https://customs.shipamax-api.com/api/v1/`.

### Content type

Unless specified otherwise, requests with a body attached should be sent with a `Content-Type: application/json` HTTP header.

## Authorization

All API methods require you to be authenticated. This is done using an access token which will be given to you by the Shipamax team.

This access token should be sent in the header of all API requests you make. If your access token was `abc123token`, you would send it as the HTTP header `Authorization: Bearer abc123token`.


## Long-term support and versioning

Shipamax aims to be a partner to our customers, this means continuously improving everything including our APIs. However, this does mean that APIs can only be supported for a given timeframe. We aim to honour the expected End-Of-Life, but in case this is not possible we will work with our customers to find a solution.  
  
Version: v1  
Launch: January 2021
Expected End-Of-Live: December 2023


# Reference

## XXX Endpoint