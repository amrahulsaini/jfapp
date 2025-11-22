import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_constants.dart';
import '../models/plan_model.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class PaymentService {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  Razorpay? _razorpay;
  
  // Store callback for later use
  Function(bool)? _currentCallback;
  BuildContext? _currentContext;

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

  Future<void> initiatePurchase(BuildContext context, PlanModel plan, Function(bool) onComplete) async {
    try {
      final token = await _storageService.getToken();
      
      // Store callback and context
      _currentCallback = onComplete;
      _currentContext = context;
      
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

      // Initialize or reuse Razorpay instance
      _razorpay ??= Razorpay();
      
      // Remove old listeners to avoid duplicates
      _razorpay!.clear();
      
      // Set up event listeners
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
        _handlePaymentSuccess(response);
      });
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        _handlePaymentError(response);
      });
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        _handleExternalWallet(response);
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
        },
        'modal': {
          'ondismiss': () {
            print('Payment modal dismissed');
          }
        }
      };

      _razorpay!.open(options);
    } catch (e) {
      onComplete(false);
      throw Exception('Payment initiation failed: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
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
          // Show notification
          final purchase = data['purchase'];
          if (purchase != null) {
            await _notificationService.showPlanPurchaseNotification(
              planName: purchase['plan_name'] ?? 'Plan',
              viewsRemaining: purchase['views_remaining'] ?? 0,
            );
          }
          
          if (_currentContext != null && _currentContext!.mounted) {
            ScaffoldMessenger.of(_currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Plan activated 🎉'),
                backgroundColor: Color(0xFF34C759),
                duration: Duration(seconds: 3),
              ),
            );
          }
          _currentCallback?.call(true);
          return;
        }
      }
      
      // If verification failed
      _currentCallback?.call(false);
      if (_currentContext != null && _currentContext!.mounted) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    } catch (e) {
      print('Payment verification error: $e');
      _currentCallback?.call(false);
      if (_currentContext != null && _currentContext!.mounted) {
        ScaffoldMessenger.of(_currentContext!).showSnackBar(
          SnackBar(
            content: Text('Payment verification error: $e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    } finally {
      _razorpay?.clear();
      _currentCallback = null;
      _currentContext = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _currentCallback?.call(false);
    if (_currentContext != null && _currentContext!.mounted) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
    _razorpay?.clear();
    _currentCallback = null;
    _currentContext = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_currentContext != null && _currentContext!.mounted) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName}'),
        ),
      );
    }
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
