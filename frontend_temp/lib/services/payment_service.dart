import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_constants.dart';
import '../models/plan_model.dart';
import 'storage_service.dart';

class PaymentService {
  final StorageService _storageService = StorageService();
  late Razorpay _razorpay;

  Future<List<PlanModel>> getPlans() async {
    try {
      final token = await _storageService.getToken();
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payment/plans'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['plans'] as List)
              .map((json) => PlanModel.fromJson(json))
              .toList();
        }
      }
      
      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      
      throw Exception('Failed to load plans');
    } catch (e) {
      print('Payment service error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyPurchases() async {
    try {
      final token = await _storageService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payment/my-purchases'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'hasActivePlan': data['hasActivePlan'] ?? false,
            'activePlan': data['activePlan'] != null 
                ? PurchaseModel.fromJson(data['activePlan']) 
                : null,
            'purchases': (data['purchases'] as List)
                .map((json) => PurchaseModel.fromJson(json))
                .toList(),
          };
        }
      }
      throw Exception('Failed to load purchases');
    } catch (e) {
      throw Exception('Error loading purchases: $e');
    }
  }

  Future<bool> canViewResult(String rollNo) async {
    try {
      final token = await _storageService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/payment/can-view/$rollNo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['canView'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> recordView(String rollNo) async {
    try {
      final token = await _storageService.getToken();
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/record-view'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'roll_no': rollNo}),
      );
    } catch (e) {
      print('Error recording view: $e');
    }
  }

  Future<bool> initiatePurchase(BuildContext context, PlanModel plan) async {
    try {
      final token = await _storageService.getToken();
      
      // Create order
      final orderResponse = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'plan_id': plan.planId}),
      );

      if (orderResponse.statusCode != 200) {
        throw Exception('Failed to create order');
      }

      final orderData = json.decode(orderResponse.body);
      if (orderData['success'] != true) {
        throw Exception(orderData['message'] ?? 'Failed to create order');
      }

      // Initialize Razorpay
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
        _handlePaymentSuccess(context, response);
      });
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        _handlePaymentError(context, response);
      });
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        _handleExternalWallet(context, response);
      });

      // Open Razorpay checkout
      var options = {
        'key': orderData['key_id'],
        'amount': orderData['order']['amount'],
        'currency': orderData['order']['currency'],
        'name': 'JF Foundation',
        'description': plan.planName,
        'order_id': orderData['order']['id'],
        'prefill': {
          'email': '', // Will be filled from token
        },
        'theme': {
          'color': '#FF6B00'
        }
      };

      _razorpay.open(options);
      return true;
    } catch (e) {
      throw Exception('Payment initiation failed: $e');
    }
  }

  void _handlePaymentSuccess(BuildContext context, PaymentSuccessResponse response) async {
    try {
      final token = await _storageService.getToken();
      
      // Verify payment on backend
      final verifyResponse = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
        }),
      );

      if (verifyResponse.statusCode == 200) {
        final data = json.decode(verifyResponse.body);
        if (data['success'] == true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Plan activated 🎉'),
                backgroundColor: Color(0xFF34C759),
              ),
            );
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      print('Payment verification error: $e');
    } finally {
      _razorpay.clear();
    }
  }

  void _handlePaymentError(BuildContext context, PaymentFailureResponse response) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
    _razorpay.clear();
  }

  void _handleExternalWallet(BuildContext context, ExternalWalletResponse response) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName}'),
        ),
      );
    }
    _razorpay.clear();
  }

  Future<bool> submitPremiumRequest({
    required String requestType,
    required String subject,
    required String description,
  }) async {
    try {
      final token = await _storageService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/premium-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'request_type': requestType,
          'subject': subject,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error submitting request: $e');
      return false;
    }
  }
}
