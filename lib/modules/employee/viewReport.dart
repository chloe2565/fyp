import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../model/databaseModel.dart';
import '../../controller/report.dart';
import '../../shared/helper.dart';

class ViewReportPage extends StatefulWidget {
  final ReportModel report;

  const ViewReportPage({Key? key, required this.report}) : super(key: key);

  @override
  State<ViewReportPage> createState() => ViewReportPageState();
}

class ViewReportPageState extends State<ViewReportPage> {
  final ReportController controller = ReportController();
  bool isLoading = true;
  Map<String, dynamic>? reportData;
  String? error;
  int topN = 5;
  final List<int> topNOptions = [5, 10, 15, 20];

  final GlobalKey barChartKey = GlobalKey();
  final GlobalKey pieChartKey = GlobalKey();
  final GlobalKey summaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadReportData();
  }

  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> loadReportData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      Map<String, dynamic> data = await controller.fetchReportData(
        widget.report,
      );
      setState(() {
        reportData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> downloadPDF() async {
    if (reportData == null) return;

    try {
      showLoadingDialog(context, 'Generating PDF with charts...');

      Uint8List? summaryImage = await captureWidget(summaryKey);
      Uint8List? barChartImage;
      Uint8List? pieChartImage;

      if (widget.report.reportType.toLowerCase() != 'service request') {
        barChartImage = await captureWidget(barChartKey);
        pieChartImage = await captureWidget(pieChartKey);
      } else {
        pieChartImage = await captureWidget(pieChartKey);
      }

      final pdf = await generatePDFWithCharts(
        summaryImage: summaryImage,
        barChartImage: barChartImage,
        pieChartImage: pieChartImage,
      );
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final fileName = '${widget.report.reportName.replaceAll(' ', '_')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Report: ${widget.report.reportName}');
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorDialog(
          context,
          title: 'PDF Error',
          message: 'Failed to generate PDF: $e',
        );
      }
    }
  }

  Future<bool> isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;

    try {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      return false;
    }
  }

  void showDownloadSuccessDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('PDF Saved', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved to Downloads',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You can find this file in your Downloads folder.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          // Close button
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),

          TextButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Share.shareXFiles([
                  XFile(filePath),
                ], text: 'Report: ${widget.report.reportName}');
              } catch (e) {}
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
          ),

          // Open PDF button
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final result = await OpenFile.open(filePath);
              } catch (e) {
                if (mounted) {
                  showErrorDialog(
                    context,
                    title: 'Cannot Open',
                    message:
                        'Please install a PDF viewer app to open this file.',
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> generatePDFWithCharts({
    Uint8List? summaryImage,
    Uint8List? barChartImage,
    Uint8List? pieChartImage,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 2),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    widget.report.reportType.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    widget.report.reportName,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Report Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated: ${dateFormat.format(widget.report.reportCreatedAt)}',
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Period: ${dateFormat.format(widget.report.reportStartDate)} - ${dateFormat.format(widget.report.reportEndDate)}',
            ),
            pw.SizedBox(height: 24),

            if (summaryImage != null) ...[
              pw.Text(
                'Summary Metrics',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Image(pw.MemoryImage(summaryImage), height: 150),
              pw.SizedBox(height: 24),
            ],

            if (barChartImage != null) ...[
              pw.Text(
                'Performance Analysis',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Image(pw.MemoryImage(barChartImage), height: 250),
              pw.SizedBox(height: 24),
            ],

            if (pieChartImage != null) ...[
              pw.Text(
                'Distribution Chart',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Image(pw.MemoryImage(pieChartImage), height: 250),
              pw.SizedBox(height: 24),
            ],

            ...buildPDFTextContent(context),
          ];
        },
      ),
    );

    return pdf;
  }

  List<pw.Widget> buildPDFTextContent(pw.Context context) {
    if (reportData == null) return [];

    final List<pw.Widget> content = [];

    switch (widget.report.reportType.toLowerCase()) {
      case 'handyman performance':
        content.addAll(buildHandymanPerformanceText());
        break;
      case 'service request':
        content.addAll(buildServiceRequestText());
        break;
      case 'financial':
        content.addAll(buildFinancialText());
        break;
    }

    return content;
  }

  List<pw.Widget> buildHandymanPerformanceText() {
    List<dynamic> performance = reportData!['handymanPerformance'] ?? [];
    int itemCount = topN == 999 ? performance.length : topN;
    List<dynamic> displayData = performance.take(itemCount).toList();

    return [
      pw.Text(
        'Handyman Details (Top ${itemCount == performance.length ? 'All' : itemCount})',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: ['Name', 'Requests', 'Completed', 'Rating', 'Reviews'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        data: displayData
            .map(
              (h) => [
                h['handymanName'].toString(),
                h['totalRequests'].toString(),
                h['completedRequests'].toString(),
                h['averageRating'].toStringAsFixed(1),
                h['totalReviews'].toString(),
              ],
            )
            .toList(),
      ),
    ];
  }

  List<pw.Widget> buildServiceRequestText() {
    Map<String, int> statusCounts = Map<String, int>.from(
      reportData!['statusCounts'],
    );

    return [
      pw.Text(
        'Status Breakdown',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: ['Status', 'Count', 'Percentage'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 9),
        data: statusCounts.entries.map((e) {
          double percentage = (reportData!['totalRequests'] > 0)
              ? (e.value / reportData!['totalRequests'] * 100)
              : 0;
          return [
            e.key[0].toUpperCase() + e.key.substring(1),
            e.value.toString(),
            '${percentage.toStringAsFixed(1)}%',
          ];
        }).toList(),
      ),
    ];
  }

  List<pw.Widget> buildFinancialText() {
    Map<String, dynamic> serviceRevenue = Map<String, dynamic>.from(
      reportData!['serviceRevenue'],
    );
    List<MapEntry<String, dynamic>> serviceList = serviceRevenue.entries
        .toList();
    int itemCount = topN == 999 ? serviceList.length : topN;
    List<MapEntry<String, dynamic>> displayServices = serviceList
        .take(itemCount)
        .toList();

    return [
      pw.Text(
        'Revenue Details (Top ${itemCount == serviceList.length ? 'All' : itemCount})',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table.fromTextArray(
        headers: ['Service', 'Revenue', 'Requests', 'Percentage'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        data: displayServices.map((e) {
          double revenue = e.value['revenue'].toDouble();
          double percentage = (reportData!['totalRevenue'] > 0)
              ? (revenue / reportData!['totalRevenue'] * 100)
              : 0;
          return [
            e.value['serviceName'].toString(),
            'RM ${revenue.toStringAsFixed(2)}',
            e.value['count'].toString(),
            '${percentage.toStringAsFixed(1)}%',
          ];
        }).toList(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Details',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading report',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: loadReportData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadReportData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  buildReportInfoCard(),
                  const SizedBox(height: 16),

                  buildSummaryMetrics(),
                  const SizedBox(height: 16),

                  buildTopNSelector(),

                  buildChartSection(),
                ],
              ),
            ),
      bottomNavigationBar: isLoading || error != null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: downloadPDF,
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          'Download PDF',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildTopNSelector() {
    if (widget.report.reportType.toLowerCase() != 'handyman performance' &&
        widget.report.reportType.toLowerCase() != 'financial') {
      return const SizedBox.shrink();
    }

    int totalCount = 0;
    String itemLabel = '';

    if (widget.report.reportType.toLowerCase() == 'handyman performance') {
      totalCount = reportData?['totalHandymen'] ?? 0;
      itemLabel = 'handymen';
    } else {
      totalCount = (reportData?['serviceRevenue'] as Map?)?.length ?? 0;
      itemLabel = 'services';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Display:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: topN,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                items: [
                  ...topNOptions.map(
                    (n) => DropdownMenuItem(value: n, child: Text('Top $n')),
                  ),
                  DropdownMenuItem(value: 999, child: Text('All $itemLabel')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      topN = value;
                    });
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$totalCount total $itemLabel',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget buildReportInfoCard() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: Colors.orange[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.reportType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Report Name: ${widget.report.reportName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(widget.report.reportStartDate)} - ${dateFormat.format(widget.report.reportEndDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Generated',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(widget.report.reportCreatedAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryMetrics() {
    List<Map<String, String>> metrics = [];

    switch (widget.report.reportType.toLowerCase()) {
      case 'handyman performance':
        metrics = [
          {
            'label': 'Total Handymen',
            'value': '${reportData!['totalHandymen'] ?? 0}',
            'icon': '👷',
          },
          {
            'label': 'Total Requests',
            'value': '${reportData!['totalRequests'] ?? 0}',
            'icon': '📋',
          },
          {
            'label': 'Total Reviews',
            'value': '${reportData!['totalReviews'] ?? 0}',
            'icon': '⭐',
          },
        ];
        break;
      case 'service request':
        Map<String, int> statusCounts = Map<String, int>.from(
          reportData!['statusCounts'] ?? {},
        );
        metrics = [
          {
            'label': 'Total Requests',
            'value': '${reportData!['totalRequests'] ?? 0}',
            'icon': '📋',
          },
          {
            'label': 'Completed',
            'value': '${statusCounts['completed'] ?? 0}',
            'icon': '✅',
          },
          {
            'label': 'Pending',
            'value': '${statusCounts['pending'] ?? 0}',
            'icon': '⏳',
          },
          {
            'label': 'Cancelled',
            'value': '${statusCounts['cancelled'] ?? 0}',
            'icon': '❌',
          },
        ];
        break;
      case 'financial':
        metrics = [
          {
            'label': 'Total Revenue',
            'value':
                'RM ${(reportData!['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
            'icon': '💰',
          },
          {
            'label': 'Completed',
            'value': '${reportData!['totalCompletedRequests'] ?? 0}',
            'icon': '✅',
          },
          {
            'label': 'Paid',
            'value': '${reportData!['totalPaidRequests'] ?? 0}',
            'icon': '💳',
          },
        ];
        break;
    }

    return RepaintBoundary(
      key: summaryKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[50]!, Colors.orange[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            metric['icon']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              metric['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric['value']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visual Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        buildCharts(),
      ],
    );
  }

  Widget buildCharts() {
    switch (widget.report.reportType.toLowerCase()) {
      case 'handyman performance':
        return buildHandymanPerformanceCharts();
      case 'service request':
        return buildServiceRequestCharts();
      case 'financial':
        return buildFinancialCharts();
      default:
        return const Center(child: Text('No charts available'));
    }
  }

  Widget buildHandymanPerformanceCharts() {
    List<dynamic> performance = reportData!['handymanPerformance'] ?? [];

    if (performance.isEmpty) {
      return buildNoDataCard('No handyman performance data for this period');
    }

    List<dynamic> validPerformance = performance.where((h) {
      bool hasRating = h['averageRating'] > 0;
      return hasRating;
    }).toList();

    List<dynamic> displayData = topN == 999
        ? validPerformance
        : validPerformance.take(topN).toList();

    const double chartHeight = 320;

    return Column(
      children: [
        buildChartCard(
          'Handyman Average Ratings (${topN == 999 ? 'All' : 'Top $topN'})',
          RepaintBoundary(
            key: barChartKey,
            child: Container(
              color: Colors.white,
              child: displayData.isEmpty
                  ? buildNoDataWidget('No ratings available for this period')
                  : SizedBox(
                      height: chartHeight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 16,
                          top: 16,
                          bottom: 16,
                        ),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 5.0,
                            minY: 0,
                            barGroups: displayData.asMap().entries.map((entry) {
                              double rating = entry.value['averageRating']
                                  .toDouble();
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: rating,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange[300]!,
                                        Colors.orange[600]!,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 35,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 35,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        value.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < displayData.length) {
                                      String fullName =
                                          displayData[value
                                                  .toInt()]['handymanName']
                                              .toString();

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: SizedBox(
                                          width: 60,
                                          child: Text(
                                            fullName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey[300],
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                left: BorderSide(color: Colors.grey[300]!),
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        buildChartCard(
          'Completed Requests Distribution',
          RepaintBoundary(
            key: pieChartKey,
            child: Container(
              color: Colors.white,
              child:
                  displayData.where((h) => h['completedRequests'] > 0).isEmpty
                  ? buildNoDataWidget('No completed requests in this period')
                  : SizedBox(
                      height: chartHeight,
                      child: Row(
                        children: [
                          // Pie Chart
                          Expanded(
                            flex: 3,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double maxDimension =
                                    constraints.maxWidth;
                                final double responsiveRadius =
                                    (maxDimension / 2) * 0.70;
                                final double centerSpace =
                                    responsiveRadius * 0.3;

                                return PieChart(
                                  PieChartData(
                                    sections: displayData
                                        .where(
                                          (h) => h['completedRequests'] > 0,
                                        )
                                        .map((h) {
                                          int index = performance.indexOf(h);
                                          int completed =
                                              h['completedRequests'];

                                          return PieChartSectionData(
                                            value: completed.toDouble(),
                                            title: '$completed',
                                            color:
                                                Colors.primaries[index %
                                                    Colors.primaries.length],
                                            radius: responsiveRadius,
                                            titleStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            badgeWidget: null,
                                          );
                                        })
                                        .toList(),
                                    sectionsSpace: 3,
                                    centerSpaceRadius: centerSpace,
                                    pieTouchData: PieTouchData(
                                      touchCallback:
                                          (
                                            FlTouchEvent event,
                                            pieTouchResponse,
                                          ) {},
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Legend
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: displayData
                                  .where((h) => h['completedRequests'] > 0)
                                  .map((h) {
                                    int index = performance.indexOf(h);
                                    String name = h['handymanName'].toString();
                                    int completed = h['completedRequests'];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.primaries[index %
                                                      Colors.primaries.length],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '$name ($completed)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildServiceRequestCharts() {
    Map<String, int> statusCounts = Map<String, int>.from(
      reportData!['statusCounts'] ?? {},
    );

    List<MapEntry<String, int>> validStatuses = statusCounts.entries.where((e) {
      bool hasValue = e.value > 0;
      return hasValue;
    }).toList();

    if (validStatuses.isEmpty) {
      return buildNoDataCard('No service request data for this period');
    }

    const double chartHeight = 320;

    return Column(
      children: [
        buildChartCard(
          'Request Status Distribution',
          RepaintBoundary(
            key: pieChartKey,
            child: Container(
              color: Colors.white,
              child: SizedBox(
                height: chartHeight,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double maxDimension = constraints.maxWidth;
                          final double responsiveRadius =
                              (maxDimension / 2) * 0.70;
                          final double centerSpace = responsiveRadius * 0.3;

                          return PieChart(
                            PieChartData(
                              sections: validStatuses.map((entry) {
                                Color color;
                                switch (entry.key) {
                                  case 'completed':
                                    color = Colors.green[600]!;
                                    break;
                                  case 'pending':
                                    color = Colors.orange[600]!;
                                    break;
                                  case 'cancelled':
                                    color = Colors.red[600]!;
                                    break;
                                  case 'confirmed':
                                    color = Colors.blue[600]!;
                                    break;
                                  case 'departed':
                                    color = Colors.purple[600]!;
                                    break;
                                  default:
                                    color = Colors.grey[600]!;
                                }

                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '${entry.value}',
                                  color: color,
                                  radius: responsiveRadius,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 3,
                              centerSpaceRadius: centerSpace,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: validStatuses.map((entry) {
                          Color color;
                          switch (entry.key) {
                            case 'completed':
                              color = Colors.green[600]!;
                              break;
                            case 'pending':
                              color = Colors.orange[600]!;
                              break;
                            case 'cancelled':
                              color = Colors.red[600]!;
                              break;
                            case 'confirmed':
                              color = Colors.blue[600]!;
                              break;
                            case 'departed':
                              color = Colors.purple[600]!;
                              break;
                            default:
                              color = Colors.grey[600]!;
                          }

                          String label =
                              entry.key[0].toUpperCase() +
                              entry.key.substring(1);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$label (${entry.value})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        buildChartCard(
          'Completion & Cancellation Rates',
          SizedBox(
            height: chartHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: reportData!['completionRate']?.toDouble() ?? 0.0,
                          gradient: LinearGradient(
                            colors: [Colors.green[300]!, Colors.green[700]!],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 60,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY:
                              reportData!['cancellationRate']?.toDouble() ??
                              0.0,
                          gradient: LinearGradient(
                            colors: [Colors.red[300]!, Colors.red[700]!],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 60,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Completion\nRate',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            case 1:
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Cancellation\nRate',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300], strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey[300]!),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildFinancialCharts() {
    Map<String, dynamic> serviceRevenue = Map<String, dynamic>.from(
      reportData!['serviceRevenue'] ?? {},
    );
    double totalRevenue = reportData!['totalRevenue']?.toDouble() ?? 0.0;

    if (serviceRevenue.isEmpty || totalRevenue == 0) {
      return buildNoDataCard('No revenue data for this period');
    }

    List<MapEntry<String, dynamic>> serviceList = serviceRevenue.entries
        .toList();
    List<MapEntry<String, dynamic>> displayServices = topN == 999
        ? serviceList
        : serviceList.take(topN).toList();

    double maxRevenue = displayServices.isEmpty
        ? 1000
        : displayServices.first.value['revenue'].toDouble();

    const double chartHeight = 320;

    return Column(
      children: [
        buildChartCard(
          'Revenue by Service (${topN == 999 ? 'All' : 'Top $topN'})',
          RepaintBoundary(
            key: barChartKey,
            child: Container(
              color: Colors.white,
              child: SizedBox(
                height: chartHeight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxRevenue * 1.2,
                      minY: 0,
                      barGroups: displayServices.asMap().entries.map((entry) {
                        double revenue = entry.value.value['revenue']
                            .toDouble();

                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: revenue,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[300]!,
                                  Colors.green[700]!,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 55,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'RM${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 70,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < displayServices.length) {
                                String serviceName =
                                    displayServices[value.toInt()]
                                        .value['serviceName'];

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: 70,
                                    child: Text(
                                      serviceName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        buildChartCard(
          'Revenue Distribution by Service',
          RepaintBoundary(
            key: pieChartKey,
            child: Container(
              color: Colors.white,
              child: SizedBox(
                height: chartHeight,
                child: Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double maxDimension = constraints.maxWidth;
                          final double responsiveRadius =
                              (maxDimension / 2) * 0.70;
                          final double centerSpace = responsiveRadius * 0.3;

                          return PieChart(
                            PieChartData(
                              sections: displayServices.asMap().entries.map((
                                entry,
                              ) {
                                double revenue = entry.value.value['revenue']
                                    .toDouble();
                                double percentage =
                                    (revenue / totalRevenue) * 100;

                                return PieChartSectionData(
                                  value: revenue,
                                  title: '${percentage.toStringAsFixed(1)}%',
                                  color:
                                      Colors.primaries[entry.key %
                                          Colors.primaries.length],
                                  radius: responsiveRadius,
                                  titleStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 3,
                              centerSpaceRadius: centerSpace,
                            ),
                          );
                        },
                      ),
                    ),
                    // Legend
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: displayServices.asMap().entries.map((entry) {
                          String serviceName = entry.value.value['serviceName'];
                          double revenue = entry.value.value['revenue']
                              .toDouble();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.primaries[entry.key %
                                            Colors.primaries.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        serviceName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'RM${revenue.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          chart,
        ],
      ),
    );
  }

  Widget buildNoDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoDataWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
