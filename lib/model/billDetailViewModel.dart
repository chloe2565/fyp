class BillDetailViewModel {
  // From BillingModel
  final double totalPrice;
  final String billStatus;
  final String billingID;

  // From ServiceRequestModel
  final String customerAddress;
  final DateTime bookingTimestamp; // scheduledDateTime
  final DateTime serviceCompleteTimestamp; // reqCompleteTime

  // From Customer + User
  final String customerName;
  final String customerContact;

  // From ServiceModel
  final String serviceName;
  final double? serviceBasePrice;

  // From Handyman + Employee + User
  final String handymanName;

  // From PaymentModel
  final DateTime? paymentTimestamp;

  // Calculated
  final double outstationFee;

  BillDetailViewModel({
    required this.totalPrice,
    required this.billStatus,
    required this.billingID,
    required this.customerAddress,
    required this.bookingTimestamp,
    required this.serviceCompleteTimestamp,
    required this.customerName,
    required this.customerContact,
    required this.serviceName,
    this.serviceBasePrice,
    required this.handymanName,
    this.paymentTimestamp,
  }) : outstationFee = 15;

  bool get isPaymentPending {
    final status = billStatus.toLowerCase();
    return status != 'paid' && status != 'cancelled';
  }
}