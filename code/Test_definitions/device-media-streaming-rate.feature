Feature: CAMARA Device Media Streaming Rate API, vwip - Operation retrieveMaximumDownstreamMediaRate

  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * List of device identifier types which are not supported, among: phoneNumber, ipv4Address, ipv6Address, networkAccessIdentifier
  # * Whether the service is offered only to certain types of devices or subscriptions
  #
  # Testing assets:
  # * A device object identifying a device for which the network can determine the maximum permitted downstream media streaming rate
  # * A device object including more than one identifier type, all identifying the same device
  # * A device object which is schema compliant but does not identify any device known to the network
  # * A device object for which the service is not applicable, if the service is not offered to all devices
  # * Access tokens: a two-legged access token which does not identify any device, and a three-legged access token which identifies the testing device
  #
  # Note: Unless a scenario states otherwise, request bodies are assumed to be otherwise
  # valid, with only the property under test deviating.
  #
  # References to OAS spec schemas refer to schemas specified in device-media-streaming-rate.yaml
  # or, for referenced common schemas, in CAMARA_common.yaml

  Background: Common Device Media Streaming Rate setup
    Given an environment at "apiRoot"
    And the resource "/device-media-streaming-rate/vwip/retrieve-maximum-downstream-media-rate"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set by default to a request body compliant with the schema at "#/components/schemas/DeviceMediaStreamingRateRequest"

  ##########################
  # Happy path scenarios
  ##########################

  @device_media_streaming_rate_01_two_legged_device_in_body
  Scenario: Retrieve the maximum downstream media streaming rate with a two-legged access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to a valid device supported by the implementation
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceMediaStreamingRateResponse"
    And the response property "$.maxDownstreamMediaRate.value" is an integer greater than or equal to 0
    And the response property "$.maxDownstreamMediaRate.unit" is one of "bps", "kbps", "Mbps", "Gbps" or "Tbps"
    And the response property "$.device", if present, contains a single device identifier that was included in the request

  @device_media_streaming_rate_02_three_legged_device_from_token
  Scenario: Retrieve the maximum downstream media streaming rate with a three-legged access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is not included
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceMediaStreamingRateResponse"
    And the response property "$.maxDownstreamMediaRate.value" is an integer greater than or equal to 0
    And the response property "$.maxDownstreamMediaRate.unit" is one of "bps", "kbps", "Mbps", "Gbps" or "Tbps"
    And the response property "$.device" is not present

  @device_media_streaming_rate_03_multiple_device_identifiers
  Scenario: Retrieve the maximum downstream media streaming rate providing more than one device identifier
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" includes more than one identifier type, all identifying the same valid device
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "#/components/schemas/DeviceMediaStreamingRateResponse"
    And the response property "$.device" is present
    And the response property "$.device" contains a single device identifier that was included in the request

  ##########################
  # 400 - Request body validation
  ##########################

  @device_media_streaming_rate_400.1_no_request_body
  Scenario: Missing request body
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body is not included
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_400.2_empty_request_body
  Scenario: Empty object as request body
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body is set to "{}"
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Request body strictness: undeclared properties are rejected at any nesting level
  @device_media_streaming_rate_400.3_unknown_property
  Scenario Outline: A request body with an undeclared property is rejected
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to a valid device supported by the implementation
    And the request body property "<property>" is set to "x"
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | property                 |
      | $.unknownProperty        |
      | $.device.unknownProperty |

  ##########################
  # Device identifier errors (Commonalities C01)
  ##########################

  @device_media_streaming_rate_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to: {}
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | device_identifier                | oas_spec_schema                              |
      | $.device.phoneNumber             | #/components/schemas/PhoneNumber             |
      | $.device.ipv4Address             | #/components/schemas/DeviceIpv4Address       |
      | $.device.ipv6Address             | #/components/schemas/DeviceIpv6Address       |
      | $.device.networkAccessIdentifier | #/components/schemas/NetworkAccessIdentifier |

  # This scenario may happen e.g. with 2-legged access tokens, which do not identify a single device.
  @device_media_streaming_rate_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is compliant with the schema but does not identify a valid device
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is set to a valid device
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_C01.06_unsupported_device
  Scenario: None of the provided device identifiers is supported by the implementation
    Given that some types of device identifiers are not supported by the implementation
    And the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" only includes device identifiers not supported by the implementation
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNSUPPORTED_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # When the service is only offered to certain types of devices or subscriptions, e.g. IoT, B2C, etc.
  @device_media_streaming_rate_C01.07_device_not_supported
  Scenario: Service not available for the device
    Given that the service is not available for all devices commercialized by the operator
    And a valid device, identified by the token or provided in the request body, for which the service is not applicable
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  ##########################
  # 401 - Authentication errors
  ##########################

  @device_media_streaming_rate_401.1_no_authorization_header
  Scenario: No Authorization header
    Given the header "Authorization" is removed
    And the request body property "$.device" is set to a valid device supported by the implementation
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_401.2_expired_access_token
  Scenario: Expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body property "$.device" is set to a valid device supported by the implementation
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @device_media_streaming_rate_401.3_invalid_access_token
  Scenario: Invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body property "$.device" is set to a valid device supported by the implementation
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  ##########################
  # 403 - Authorization errors
  ##########################

  @device_media_streaming_rate_403.1_missing_access_token_scope
  Scenario: Access token does not include the required scope
    Given the header "Authorization" is set to a valid access token which does not include the scope "device-media-streaming-rate:retrieve-maximum-downstream-media-rate"
    And the request body property "$.device" is set to a valid device supported by the implementation
    When the request "retrieveMaximumDownstreamMediaRate" is sent
    Then the response status code is 403
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text
