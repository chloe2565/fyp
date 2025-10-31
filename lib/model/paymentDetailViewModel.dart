class PaymentDetailViewModel {
  final String billingID;
  final String payStatus;
  final String payMethod;
  final double payAmt;
  final DateTime payCreatedAt;

  final String customerName;
  final String customerContact;
  final String customerAddress;

  final String serviceName;
  final double serviceBasePrice;
  final double outstationFee;
  final double totalPrice;

  final String handymanName;
  final DateTime bookingTimestamp;
  final DateTime serviceCompleteTimestamp;
  final DateTime paymentTimestamp;

  PaymentDetailViewModel({
    required this.billingID,
    required this.payStatus,
    required this.payMethod,
    required this.payAmt,
    required this.payCreatedAt,
    required this.customerName,
    required this.customerContact,
    required this.customerAddress,
    required this.serviceName,
    required this.serviceBasePrice,
    required this.outstationFee,
    required this.totalPrice,
    required this.handymanName,
    required this.bookingTimestamp,
    required this.serviceCompleteTimestamp,
    required this.paymentTimestamp,
  });
}