---
title: Shipamax Freight Forwarding API Reference

language_tabs: # must be one of https://git.io/vQNgJ
  - shell

toc_footers:
  - <a href='mailto:support@shipamax.com'>Get a Developer Key</a>

includes:
  - errors

search: true
---

# Introduction

Welcome to the Shipamax Freight Forwarding API. The Shipamax freight forwarding API converts documents into structured JSON.

If you have any questions please contact [techsupport@shipamax.com](techsupport@shipamax.com).

Example code can be found at
[https://github.com/shipamax/samples/tree/master/freightforwarding](https://github.com/shipamax/samples/tree/master/freightforwarding)

# Support cycle

Current APIv1, published January 2019, will have end-of-life by July 2019, where it will be replaced with a newer version APIv2. Please keep in mind that this might require you to allocate development ressources to migrate to the new version.

# Workflow

There are two ways for sending data to the Shipamax API.

1. Pushing directly to the API

2. Forwarding of e-mails

## API
The workflow of the API is

1. Login and get an access token

2. Post a document with a custom ID to be parsed

3. Retrieve the parsing results via custom ID

4. Log out and invalidate the access token


## E-mail forwarding to API
The workflow of email to API is

1. Send email to forwarding address provided by Shipamax. If you need one please contact
[support@shipamax.com](support@shipamax.com)

2. Login to API and get an access token

3. Retrieve the parsing results. Information about the custom ID can be found [below](#custom-id-for-email-forwarding).

4. Log out and invalidate the access token


# Logging in

> To log in, use this code:

```shell
# With shell, you can just pass the correct header with each request

curl -X POST --header 'Content-Type: application/json'
  -d '{"username":"[USERNAME]", "password":"[PASSWORD]"}'
  'https://developer.shipamax-api.com/api/users/login?version=190206'
```

> Make sure to replace `[USERNAME]` with your username and `[PASSWORD]` with your password respectively.

Shipamax requires you to log in before any calls with your username and password. See the example on the side how to log in and obtain an access token.

Shipamax expects for the access token to be included in all API requests to the server in a header that looks like the following:

<aside class="notice">
You must replace <code>[USERNAME]</code> and <code>[PASSWORD]</code> with your personal login details.
</aside>

# Retrieving parsing results

> To retrieve parsing results

```shell
# With shell, you can just pass the correct header with each request

curl -X GET --header 'Accept: application/json'
  'https://developer.shipamax-api.com/api/DocumentContainers/query?customIds=%5B%22%22%5D&access_token=[TOKEN]&version=190206'
```

> Make sure to replace `[TOKEN]` with your username and `[TOKEN]` with your password respectively.

Shipamax requires you to log in before any calls with your username and password. See the example on the side how to log in and obtain an access token.

Shipamax expects for the access token to be included in all API requests to the server in a header that looks like the following:

<aside class="notice">
You must replace <code>[USERNAME]</code> and <code>[PASSWORD]</code> with your personal login details.
</aside>

# Custom ID for email forwarding

When you forward emails to a forwarding account you will need to match that email to a custom ID so you can retrieve the results via API. You can use the Message-ID field to query parsing results.

![alt text](./images/messageid.png)

In this example custom ID would be <5c52f8e7.1c69fb81.e6555.702d@mx.google.com>.
More information about the email Message-ID can be found here
[https://tools.ietf.org/html/rfc5322](https://tools.ietf.org/html/rfc5322)
