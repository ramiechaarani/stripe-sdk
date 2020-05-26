import 'dart:async';

import 'models/card.dart';
import 'stripe_api_handler.dart';

typedef Future<Map<String, dynamic>> IntentProvider(Uri uri);

class StripeApi {
  static StripeApi _instance;

  final StripeApiHandler _apiHandler;

  final String publishableKey;

  final String apiVersion;

  /// Create a new instance, which can be used with e.g. dependency injection.
  /// Throws a [Exception] if an invalid [publishableKey] has been submitted.
  ///
  /// [publishableKey] is your publishable key, beginning with "sk_".
  /// Your can copy your key from https://dashboard.stripe.com/account/apikeys
  ///
  /// [stripeAccount] is the id of a stripe customer and stats with "cus_".
  /// This is a optional parameter.
  StripeApi(this.publishableKey,
      {this.apiVersion = DEFAULT_API_VERSION, String stripeAccount})
      : _apiHandler = StripeApiHandler(stripeAccount: stripeAccount) {
    _validateKey(publishableKey);
    _apiHandler.apiVersion = apiVersion;
  }

  /// Initialize the managed singleton instance of [StripeApi].
  /// Afterwards you can use [StripeApi.instance] to access the created instance.
  ///
  /// [publishableKey] is your publishable key, beginning with "sk_".
  /// Your can copy your key from https://dashboard.stripe.com/account/apikeys
  ///
  /// [stripeAccount] is the id of a stripe customer and stats with "cus_".
  /// This is a optional parameter.
  static void init(String publishableKey,
      {String apiVersion = DEFAULT_API_VERSION, String stripeAccount}) {
    if (_instance == null) {
      _instance = StripeApi(publishableKey,
          apiVersion: apiVersion, stripeAccount: stripeAccount);
    }
  }

  /// Access the singleton instance of [StripeApi].
  /// Throws an [Exception] if [StripeApi.init] hasn't been called previously.
  static StripeApi get instance {
    if (_instance == null) {
      throw Exception(
          "Attempted to get singleton instance of StripeApi without initialization");
    }
    return _instance;
  }

  /// Create a stripe Token
  /// https://stripe.com/docs/api/tokens
  Future<Map<String, dynamic>> createToken(Map<String, dynamic> data) async {
    final path = "/tokens";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: data);
  }

  /// Retrieve a Plan with a given ID
  /// https://stripe.com/docs/api/plans/retrieve
  Future<Map<String, dynamic>> retrievePlanMethod(
      Map<String, dynamic> data,
      String planID) async {
    final path = "/plans/$planID";
    return _apiHandler.request(
        RequestMethod.get, path, publishableKey, apiVersion,
        params: data);
  }

  /// Create a Customer.
  /// https://stripe.com/docs/api/customers/create
  Future<Map<String, dynamic>> createCustomerMethod(
      Map<String, dynamic> data) async {
    final path = "/customers";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: data);
  }

  /// Create a Charge.
  /// https://stripe.com/docs/api/charges/create
  Future<Map<String, dynamic>> createChargeMethod(
      Map<String, dynamic> data) async {
    final path = "/charges";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: data);
  }

  /// Create a PaymentMethod.
  /// https://stripe.com/docs/api/payment_methods/create
  Future<Map<String, dynamic>> createPaymentMethod(
      Map<String, dynamic> data) async {
    final path = "/payment_methods";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: data);
  }

  /// Create Card for Customer
  /// https://stripe.com/docs/api/cards/create
  Future<Map<String, dynamic>> createPaymentMethodForCustomer(
      String customerId,
      Map<String, dynamic> data) async {
    final path = "/customers/${customerId}/sources";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: data);
  }

  /// List Cards for Customer
  /// https://stripe.com/docs/api/cards/create
  Future<Map<String, dynamic>> listPaymentMethodsForCustomer(
      String customerId,
      Map<String, dynamic> data) async {
    final path = "/customers/${customerId}/sources";
    return _apiHandler.request(
        RequestMethod.get, path, publishableKey, apiVersion,
        params: data);
  }

  /// List Cards for Customer
  /// https://stripe.com/docs/api/cards/create
  Future<Map<String, dynamic>> deletePaymentMethodsForCustomer(
      String customerId,
      String cardId,
      Map<String, dynamic> data) async {
    final path = '/customers/${customerId}/sources/${cardId}';
    return _apiHandler.request(
        RequestMethod.delete, path, publishableKey, apiVersion,
        params: data);
  }

  Future<Map<String, dynamic>> createPaymentMethodForCustomerFromCard(
      String customerId,
      StripeCard card) async {
    return createPaymentMethodForCustomer(customerId, card.toPaymentMethod());
  }

  /// Create Subscription for Customer
  /// https://stripe.com/docs/api/subscriptions/create
  Future<Map<String, dynamic>> createSubscriptionMethodForCustomer(
      Map<String, dynamic> data) async {
    final path = "/subscriptions";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: data);
  }

  /// Retrieve Subscription for Customer
  /// https://stripe.com/docs/api/subscriptions/create
  Future<Map<String, dynamic>> retrieveSubscriptionsMethod(
      Map<String, dynamic> data) async {
    final path = "/subscriptions";
    return _apiHandler.request(
        RequestMethod.get, path, publishableKey, apiVersion,
        params: data);
  }

  /// Cancel Subscription for Customer
  /// https://stripe.com/docs/api/subscriptions/create
  Future<Map<String, dynamic>> cancelSubscriptionMethod(
      String subscriptionID, Map<String, dynamic> data) async {
    final path = "/subscriptions/${subscriptionID}";
    return _apiHandler.request(
        RequestMethod.delete, path, publishableKey, apiVersion,
        params: null);
  }

  Future<Map<String, dynamic>> createPaymentMethodFromCard(
      StripeCard card) async {
    return createPaymentMethod(card.toPaymentMethod());
  }

  /// Retrieve a PaymentIntent.
  /// https://stripe.com/docs/api/payment_intents/retrieve
  Future<Map<String, dynamic>> retrievePaymentIntent(String clientSecret,
      {String apiVersion}) async {
    final intentId = _parseIdFromClientSecret(clientSecret);
    final path = "/payment_intents/$intentId";
    final params = {'client_secret': clientSecret};
    return _apiHandler.request(
        RequestMethod.get, path, publishableKey, apiVersion,
        params: params);
  }

  /// Confirm a PaymentIntent
  /// https://stripe.com/docs/api/payment_intents/confirm
  Future<Map<String, dynamic>> confirmPaymentIntent(String clientSecret,
      {Map<String, dynamic> data}) async {
    final params = data ?? {};
    final intent = _parseIdFromClientSecret(clientSecret);
    params['client_secret'] = clientSecret;
    final path = "/payment_intents/$intent/confirm";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: params);
  }

  /// Retrieve a SetupIntent.
  /// https://stripe.com/docs/api/setup_intents/retrieve
  Future<Map<String, dynamic>> retrieveSetupIntent(String clientSecret,
      {String apiVersion}) async {
    final intentId = _parseIdFromClientSecret(clientSecret);
    final path = "/setup_intents/$intentId";
    final params = {'client_secret': clientSecret};
    return _apiHandler.request(
        RequestMethod.get, path, publishableKey, apiVersion,
        params: params);
  }

  /// Confirm a SetupIntent
  /// https://stripe.com/docs/api/setup_intents/confirm
  Future<Map<String, dynamic>> confirmSetupIntent(String clientSecret,
      {Map<String, dynamic> data}) async {
    final params = data ?? {};
    final intent = _parseIdFromClientSecret(clientSecret);
    params['client_secret'] = clientSecret;
    final path = "/setup_intents/$intent/confirm";
    return _apiHandler.request(
        RequestMethod.post, path, publishableKey, apiVersion,
        params: params);
  }

  /// Validates the received [publishableKey] and throws a [Exception] if an
  /// invalid key has been submitted.
  static void _validateKey(String publishableKey) {
    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception("Invalid Publishable Key: " +
          "You must use a valid publishable key to create a token.  " +
          "For more info, see https://stripe.com/docs/stripe.js.");
    }

//    if (publishableKey.startsWith("sk_")) {
//      throw Exception("Invalid Publishable Key: " +
//          "You are using a secret key to create a token, " +
//          "instead of the publishable one. For more info, " +
//          "see https://stripe.com/docs/stripe.js");
//    }
  }
}

String _parseIdFromClientSecret(String clientSecret) {
  return clientSecret.split("_secret")[0];
}
