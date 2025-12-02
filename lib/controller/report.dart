import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/databaseModel.dart';
import '../service/report.dart';

class ReportController {
  final ReportService reportService = ReportService();

  Future<String> fetchCurrentProviderID() async {
    try {
      final User? authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      final userSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('authID', isEqualTo: authUser.uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('User document not found');
      }

      final String userID = userSnapshot.docs.first.data()['userID'];

      final employeeSnapshot = await FirebaseFirestore.instance
          .collection('Employee')
          .where('userID', isEqualTo: userID)
          .limit(1)
          .get();

      if (employeeSnapshot.docs.isEmpty) {
        throw Exception('Employee document not found');
      }

      final String empID = employeeSnapshot.docs.first.data()['empID'];

      final providerSnapshot = await FirebaseFirestore.instance
          .collection('ServiceProvider')
          .where('empID', isEqualTo: empID)
          .limit(1)
          .get();

      if (providerSnapshot.docs.isEmpty) {
        throw Exception('Service Provider document not found');
      }

      final String providerID = providerSnapshot.docs.first
          .data()['providerID'];

      return providerID;
    } catch (e) {
      throw Exception('Failed to fetch provider ID: $e');
    }
  }

  // Duplicate check
  Future<bool> checkDuplicateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    required String providerID,
  }) async {
    try {
      return await reportService.isDuplicateReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        providerID: providerID,
      );
    } catch (e) {
      return false;
    }
  }

  // Generate a new report
  Future<String> generateReport({
    required BuildContext context,
    required String reportName,
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    required String providerID,
  }) async {
    try {
      if (endDate.isBefore(startDate)) {
        throw Exception('End date must be after start date');
      }

      String reportID = await reportService.generateReport(
        reportName: reportName,
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        providerID: providerID,
      );

      return reportID;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch reports with filters
  Stream<List<ReportModel>> fetchReports({
    String? reportType,
    int? year,
    String? providerID,
  }) {
    return reportService.fetchReports(
      reportType: reportType,
      year: year,
      providerID: providerID,
    );
  }

  // Get available report types
  List<String> getReportTypes() {
    return reportService.getReportTypes();
  }

  // Delete a report -
  Future<void> deleteReport(BuildContext context, String reportID) async {
    try {
      await reportService.deleteReport(reportID);
    } catch (e) {
      rethrow;
    }
  }

  // Fetch report data for viewing
  Future<Map<String, dynamic>> fetchReportData(
    ReportModel report, {
    int topN = 5,
  }) async {
    try {
      final data = await reportService.fetchReportData(report);
      data['topN'] = topN;
      return data;
    } catch (e) {
      throw Exception('Failed to load report data: $e');
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String formatMonthYear(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  List<int> getAvailableYears() {
    int currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }
}
