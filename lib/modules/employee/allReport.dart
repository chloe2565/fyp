import 'package:flutter/material.dart';
import '../../model/databaseModel.dart';
import '../../controller/report.dart';
import '../../shared/helper.dart';
import 'generateReport.dart';
import 'viewReport.dart';

class EmpReportScreen extends StatefulWidget {
  const EmpReportScreen({Key? key}) : super(key: key);

  @override
  State<EmpReportScreen> createState() => EmpReportScreenState();
}

class EmpReportScreenState extends State<EmpReportScreen> {
  final ReportController controller = ReportController();
  final TextEditingController searchController = TextEditingController();

  String? selectedReportType;
  int? selectedYear;
  String searchQuery = '';
  String? currentProviderID;
  bool isLoadingProviderID = true;
  String? errorLoadingProviderID;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
    fetchCurrentProviderID();
  }

  Future<void> fetchCurrentProviderID() async {
    try {
      setState(() {
        isLoadingProviderID = true;
        errorLoadingProviderID = null;
      });

      final providerID = await controller.fetchCurrentProviderID();
      setState(() {
        currentProviderID = providerID;
        isLoadingProviderID = false;
      });
    } catch (e) {
      setState(() {
        errorLoadingProviderID = e.toString();
        isLoadingProviderID = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProviderID) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Reports',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorLoadingProviderID != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Reports',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                errorLoadingProviderID!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchCurrentProviderID,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reports',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedReportType,
                            hint: const Text('Performance'),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Types'),
                              ),
                              ...controller.getReportTypes().map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedReportType = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Year Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedYear,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: controller.getAvailableYears().map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(year.toString()),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add Report Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GenerateReportPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Reports List
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: controller.fetchReports(
                reportType: selectedReportType,
                year: selectedYear,
                providerID: currentProviderID!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<ReportModel> reports = snapshot.data!;

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  reports = reports.where((report) {
                    return report.reportName.toLowerCase().contains(
                          searchQuery,
                        ) ||
                        report.reportType.toLowerCase().contains(searchQuery);
                  }).toList();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: reports.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    ReportModel report = reports[index];
                    return buildReportItem(report);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReportItem(ReportModel report) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewReportPage(report: report),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                report.reportName,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewReportPage(report: report),
                    ),
                  );
                } else if (value == 'delete') {
                  showDeleteDialog(report);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void showDeleteDialog(ReportModel report) {
    showConfirmDialog(
      context,
      title: 'Delete Report',
      message:
          'Are you sure you want to delete "${report.reportName}"? This action cannot be undone.',
      affirmativeText: 'Delete',
      negativeText: 'Cancel',
      onAffirmative: () async {
        print(
          'DEBUG: User confirmed deletion for report: ${report.reportID}',
        );

        // Show loading dialog
        showLoadingDialog(context, 'Deleting report...');

        try {
          await controller.deleteReport(context, report.reportID);

          // Close loading dialog
          if (context.mounted) {
            Navigator.of(context).pop();

            // Show success dialog
            showSuccessDialog(
              context,
              title: 'Report Deleted',
              message: 'The report has been deleted successfully.',
              primaryButtonText: 'OK',
              onPrimary: () {
                Navigator.of(context).pop();
              },
            );
          }
        } catch (e) {
          // Close loading dialog
          if (context.mounted) {
            Navigator.of(context).pop();

            // Show error dialog
            showErrorDialog(
              context,
              title: 'Delete Failed',
              message: 'Failed to delete report: $e',
              buttonText: 'OK',
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
