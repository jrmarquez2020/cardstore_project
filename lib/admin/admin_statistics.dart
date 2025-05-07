import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminStatistics extends StatefulWidget {
  const AdminStatistics({super.key});

  @override
  State<AdminStatistics> createState() => _AdminStatisticsState();
}

class _AdminStatisticsState extends State<AdminStatistics> {
  Map<String, double> totalSalesPerMonth = {};
  Map<String, int> totalOrdersPerMonth = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactionData();
  }

  Future<void> fetchTransactionData() async {
    final transactions =
        await FirebaseFirestore.instance.collection('transactions').get();

    for (var doc in transactions.docs) {
      final data = doc.data();
      final Timestamp orderedAt = data['orderedAt'];
      final double total = (data['total'] ?? 0).toDouble();
      final String month = DateFormat('MMM').format(orderedAt.toDate());

      totalSalesPerMonth[month] = (totalSalesPerMonth[month] ?? 0) + total;
      totalOrdersPerMonth[month] = (totalOrdersPerMonth[month] ?? 0) + 1;
    }

    setState(() {
      isLoading = false;
    });
  }

  double _calculateOverallAverage() {
    final totalSales = totalSalesPerMonth.values.fold(0.0, (a, b) => a + b);
    final totalOrders = totalOrdersPerMonth.values.fold(0, (a, b) => a + b);
    return totalOrders > 0 ? totalSales / totalOrders : 0;
  }

  Widget _buildStatCard({required String title, required String value}) {
    return Container(
      width: 110,
      height: 60,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 52, 52, 52),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final months =
        totalSalesPerMonth.keys.toList()..sort(
          (a, b) => DateFormat(
            'MMM',
          ).parse(a).month.compareTo(DateFormat('MMM').parse(b).month),
        );

    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text("Statistics", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[800],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          title: "Sales Total",
                          value: totalSalesPerMonth.values
                              .fold(0.0, (a, b) => a + b)
                              .toStringAsFixed(2),
                        ),
                        _buildStatCard(
                          title: "Avg Order Value",
                          value: _calculateOverallAverage().toStringAsFixed(2),
                        ),
                        _buildStatCard(
                          title: "Total Orders",
                          value:
                              totalOrdersPerMonth.values
                                  .fold(0, (a, b) => a + b)
                                  .toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          // Legend for Sales and Avg Order
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                color: Colors.blue,
                                label: 'Total Sales',
                              ),
                              const SizedBox(width: 12),
                              _buildLegendItem(
                                color: Colors.orange,
                                label: 'Avg Order',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Sales and Avg Order Bar Chart
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, _) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            months[value.toInt()],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget:
                                          (value, _) => Text(
                                            value.toInt().toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                barGroups: List.generate(months.length, (
                                  index,
                                ) {
                                  final month = months[index];
                                  final total = totalSalesPerMonth[month] ?? 0;
                                  final avg =
                                      totalOrdersPerMonth[month] != 0
                                          ? total / totalOrdersPerMonth[month]!
                                          : 0;

                                  return BarChartGroupData(
                                    x: index,
                                    barsSpace: 8,
                                    barRods: [
                                      BarChartRodData(
                                        toY: total,
                                        color: Colors.blue,
                                        width: 14,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      BarChartRodData(
                                        toY: avg.toDouble(),
                                        color: Colors.orange,
                                        width: 14,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }),
                                gridData: FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(enabled: true),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Legend for Orders
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem(
                                color: Colors.green,
                                label: 'Total Orders',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Orders Bar Chart
                          SizedBox(
                            height: 150,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, _) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            months[value.toInt()],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget:
                                          (value, _) => Text(
                                            value.toInt().toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                barGroups: List.generate(months.length, (
                                  index,
                                ) {
                                  final month = months[index];
                                  final orders =
                                      totalOrdersPerMonth[month] ?? 0;

                                  return BarChartGroupData(
                                    x: index,
                                    barsSpace: 8,
                                    barRods: [
                                      BarChartRodData(
                                        toY: orders.toDouble(),
                                        color: Colors.green,
                                        width: 14,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                }),
                                gridData: FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(enabled: true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
