import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';

class ReportService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String> generateReportID() async {
    final reportsSnapshot = await firestore
        .collection('Report')
        .orderBy('reportID', descending: true)
        .limit(1)
        .get();

    if (reportsSnapshot.docs.isEmpty) {
      return 'R0001';
    }

    final lastReportID =
        reportsSnapshot.docs.first.data()['reportID'] as String;
    final lastNumber = int.parse(lastReportID.substring(1));
    final newNumber = lastNumber + 1;
    return 'R${newNumber.toString().padLeft(4, '0')}';
  }

  // Check for duplicate reports
  Future<bool> isDuplicateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    required String providerID,
  }) async {
    try {
      final querySnapshot = await firestore
          .collection('Report')
          .where('reportType', isEqualTo: reportType)
          .where('providerID', isEqualTo: providerID)
          .where('reportStartDate', isEqualTo: Timestamp.fromDate(startDate))
          .where('reportEndDate', isEqualTo: Timestamp.fromDate(endDate))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Generate a new report
  Future<String> generateReport({
    required String reportName,
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    required String providerID,
  }) async {
    try {
      bool isDuplicate = await isDuplicateReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        providerID: providerID,
      );

      if (isDuplicate) {
        throw Exception(
          'A report with the same type and date range already exists',
        );
      }

      String reportID = await generateReportID();

      ReportModel report = ReportModel(
        reportID: reportID,
        reportName: reportName,
        reportType: reportType,
        reportStartDate: startDate,
        reportEndDate: endDate,
        reportCreatedAt: DateTime.now(),
        providerID: providerID,
      );

      await firestore.collection('Report').doc(reportID).set(report.toMap());

      return reportID;
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  // Fetch all reports with filtering
  Stream<List<ReportModel>> fetchReports({
    String? reportType,
    int? year,
    String? providerID,
  }) {
    Query query = firestore.collection('Report');

    if (reportType != null && reportType.isNotEmpty) {
      query = query.where('reportType', isEqualTo: reportType);
    }

    if (providerID != null && providerID.isNotEmpty) {
      query = query.where('providerID', isEqualTo: providerID);
    }

    if (year != null) {
      DateTime startOfYear = DateTime(year, 1, 1);
      DateTime endOfYear = DateTime(year, 12, 31, 23, 59, 59);
      query = query
          .where(
            'reportCreatedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          )
          .where(
            'reportCreatedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfYear),
          );
    }

    return query.orderBy('reportCreatedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get report types
  List<String> getReportTypes() {
    return ['Handyman Performance', 'Service Request', 'Financial'];
  }

  // Delete report
  Future<void> deleteReport(String reportID) async {
    try {
      final querySnapshot = await firestore
          .collection('Report')
          .where('reportID', isEqualTo: reportID)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Fetch report data based on type and date range
  Future<Map<String, dynamic>> fetchReportData(ReportModel report) async {
    try {
      switch (report.reportType.toLowerCase()) {
        case 'handyman performance':
          return await fetchHandymanPerformanceData(report);
        case 'service request':
          return await fetchServiceRequestData(report);
        case 'financial':
          return await fetchFinancialData(report);
        default:
          return {};
      }
    } catch (e) {
      throw Exception('Failed to fetch report data: $e');
    }
  }

  // Handyman Performance Report - based on ratings and reviews
  Future<Map<String, dynamic>> fetchHandymanPerformanceData(
    ReportModel report,
  ) async {
    QuerySnapshot requestsSnapshot = await firestore
        .collection('ServiceRequest')
        .where(
          'scheduledDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(report.reportStartDate),
        )
        .where(
          'scheduledDateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(report.reportEndDate),
        )
        .get();

    List<ServiceRequestModel> requests = requestsSnapshot.docs
        .map(
          (doc) =>
              ServiceRequestModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();

    // Fetch ratings for these requests
    List<String> requestIDs = requests.map((r) => r.reqID).toList();
    Map<String, RatingReviewModel> ratingsMap = {};

    if (requestIDs.isNotEmpty) {
      QuerySnapshot ratingsSnapshot = await firestore
          .collection('RatingReview')
          .where('reqID', whereIn: requestIDs.take(10).toList())
          .get();

      for (var doc in ratingsSnapshot.docs) {
        RatingReviewModel rating = RatingReviewModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        ratingsMap[rating.reqID] = rating;
      }
    }

    // Fetch handyman data
    QuerySnapshot handymenSnapshot = await firestore
        .collection('Handyman')
        .get();
    List<HandymanModel> handymen = handymenSnapshot.docs
        .map((doc) => HandymanModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Fetch employee and user data for handyman names
    Map<String, String> handymanNames = {};
    for (var handyman in handymen) {
      try {
        var empDoc = await firestore
            .collection('Employee')
            .where('empID', isEqualTo: handyman.empID)
            .limit(1)
            .get();
        if (empDoc.docs.isNotEmpty) {
          String userID = empDoc.docs.first.data()['userID'];
          var userDoc = await firestore
              .collection('User')
              .where('userID', isEqualTo: userID)
              .limit(1)
              .get();
          if (userDoc.docs.isNotEmpty) {
            handymanNames[handyman.handymanID] = userDoc.docs.first
                .data()['userName'];
          }
        }
      } catch (e) {
        handymanNames[handyman.handymanID] = 'Unknown';
      }
    }

    // Group by handyman
    Map<String, Map<String, dynamic>> handymanStats = {};
    for (var request in requests) {
      final String? handymanID = request.handymanID;
      if (handymanID == null) {
        continue;
      }
      if (!handymanStats.containsKey(handymanID)) {
        handymanStats[handymanID] = {
          'totalRequests': 0,
          'completedRequests': 0,
          'ratings': <double>[],
          'reviews': <RatingReviewModel>[],
        };
      }

      handymanStats[handymanID]!['totalRequests']++;
      if (request.reqStatus == 'completed') {
        handymanStats[handymanID]!['completedRequests']++;

        if (ratingsMap.containsKey(request.reqID)) {
          RatingReviewModel rating = ratingsMap[request.reqID]!;
          handymanStats[handymanID]!['ratings'].add(rating.ratingNum);
          handymanStats[handymanID]!['reviews'].add(rating);
        }
      }
    }

    // Calculate averages
    List<Map<String, dynamic>> handymanPerformance = [];
    handymanStats.forEach((handymanID, stats) {
      List<double> ratings = stats['ratings'];
      double avgRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      handymanPerformance.add({
        'handymanID': handymanID,
        'handymanName': handymanNames[handymanID] ?? 'Unknown',
        'totalRequests': stats['totalRequests'],
        'completedRequests': stats['completedRequests'],
        'averageRating': avgRating,
        'totalReviews': ratings.length,
        'reviews': stats['reviews'],
      });
    });

    // Sort by average rating
    handymanPerformance.sort(
      (a, b) => b['averageRating'].compareTo(a['averageRating']),
    );

    return {
      'handymanPerformance': handymanPerformance,
      'totalHandymen': handymanStats.length,
      'totalRequests': requests.length,
      'totalReviews': ratingsMap.length,
    };
  }

  // Service Request Report - Use scheduledDateTime and include all status counts in summary
  Future<Map<String, dynamic>> fetchServiceRequestData(
    ReportModel report,
  ) async {
    QuerySnapshot requestsSnapshot = await firestore
        .collection('ServiceRequest')
        .where(
          'scheduledDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(report.reportStartDate),
        )
        .where(
          'scheduledDateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(report.reportEndDate),
        )
        .get();

    List<ServiceRequestModel> requests = requestsSnapshot.docs
        .map(
          (doc) =>
              ServiceRequestModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();

    Map<String, int> statusCounts = {
      'pending': 0,
      'confirmed': 0,
      'departed': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (var request in requests) {
      statusCounts[request.reqStatus] =
          (statusCounts[request.reqStatus] ?? 0) + 1;
    }

    // Group by month
    Map<String, int> monthlyRequests = {};
    for (var request in requests) {
      String monthKey =
          '${request.scheduledDateTime.year}-${request.scheduledDateTime.month.toString().padLeft(2, '0')}';
      monthlyRequests[monthKey] = (monthlyRequests[monthKey] ?? 0) + 1;
    }

    Map<String, int> dailyRequests = {};
    for (var request in requests) {
      String dateKey =
          '${request.scheduledDateTime.year}-${request.scheduledDateTime.month.toString().padLeft(2, '0')}-${request.scheduledDateTime.day.toString().padLeft(2, '0')}';
      dailyRequests[dateKey] = (dailyRequests[dateKey] ?? 0) + 1;
    }

    return {
      'totalRequests': requests.length,
      'statusCounts': statusCounts,
      'dailyRequests': dailyRequests,
      'monthlyRequests': monthlyRequests,
      'pendingRequests': statusCounts['pending'],
      'confirmedRequests': statusCounts['confirmed'],
      'departedRequests': statusCounts['departed'],
      'completedRequests': statusCounts['completed'],
      'cancelledRequests': statusCounts['cancelled'],
      'completionRate': requests.isEmpty
          ? 0.0
          : (statusCounts['completed']! / requests.length * 100),
      'cancellationRate': requests.isEmpty
          ? 0.0
          : (statusCounts['cancelled']! / requests.length * 100),
    };
  }

  // Financial Report
  Future<Map<String, dynamic>> fetchFinancialData(ReportModel report) async {
    QuerySnapshot requestsSnapshot = await firestore
        .collection('ServiceRequest')
        .where('reqStatus', isEqualTo: 'completed')
        .where(
          'scheduledDateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(report.reportStartDate),
        )
        .where(
          'scheduledDateTime',
          isLessThanOrEqualTo: Timestamp.fromDate(report.reportEndDate),
        )
        .get();

    List<ServiceRequestModel> completedRequests = requestsSnapshot.docs
        .map(
          (doc) =>
              ServiceRequestModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();

    // Fetch billings for these requests
    List<String> requestIDs = completedRequests.map((r) => r.reqID).toList();
    Map<String, BillingModel> billingsMap = {};

    if (requestIDs.isNotEmpty) {
      QuerySnapshot billingsSnapshot = await firestore
          .collection('Billing')
          .where('reqID', whereIn: requestIDs.take(10).toList())
          .get();

      for (var doc in billingsSnapshot.docs) {
        BillingModel billing = BillingModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        billingsMap[billing.reqID] = billing;
      }
    }

    // Fetch payments for paid billings
    List<String> billingIDs = billingsMap.values
        .map((b) => b.billingID)
        .toList();
    Map<String, PaymentModel> paymentsMap = {};

    if (billingIDs.isNotEmpty) {
      QuerySnapshot paymentsSnapshot = await firestore
          .collection('Payment')
          .where('billingID', whereIn: billingIDs.take(10).toList())
          .where('payStatus', isEqualTo: 'paid')
          .get();

      for (var doc in paymentsSnapshot.docs) {
        PaymentModel payment = PaymentModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        paymentsMap[payment.billingID] = payment;
      }
    }

    // Fetch services
    QuerySnapshot servicesSnapshot = await firestore
        .collection('Service')
        .get();
    Map<String, ServiceModel> servicesMap = {};
    for (var doc in servicesSnapshot.docs) {
      ServiceModel service = ServiceModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
      servicesMap[service.serviceID] = service;
    }

    // Calculate revenue by service
    Map<String, Map<String, dynamic>> serviceRevenue = {};
    double totalRevenue = 0.0;

    for (var request in completedRequests) {
      if (request.serviceID.isEmpty) continue;

      if (billingsMap.containsKey(request.reqID)) {
        BillingModel billing = billingsMap[request.reqID]!;

        if (paymentsMap.containsKey(billing.billingID)) {
          PaymentModel payment = paymentsMap[billing.billingID]!;

          if (!serviceRevenue.containsKey(request.serviceID)) {
            serviceRevenue[request.serviceID] = {
              'serviceName':
                  servicesMap[request.serviceID]?.serviceName ?? 'Unknown',
              'revenue': 0.0,
              'count': 0,
            };
          }

          serviceRevenue[request.serviceID]!['revenue'] += payment.payAmt;
          serviceRevenue[request.serviceID]!['count']++;
          totalRevenue += payment.payAmt;
        }
      }
    }

    List<MapEntry<String, Map<String, dynamic>>> sortedServices =
        serviceRevenue.entries.toList()
          ..sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));

    return {
      'totalRevenue': totalRevenue,
      'totalCompletedRequests': completedRequests.length,
      'totalPaidRequests': paymentsMap.length,
      'serviceRevenue': Map.fromEntries(sortedServices),
      'topService': sortedServices.isEmpty
          ? 'N/A'
          : sortedServices.first.value['serviceName'],
      'topServiceRevenue': sortedServices.isEmpty
          ? 0.0
          : sortedServices.first.value['revenue'],
    };
  }
}
