import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({Key? key}) : super(key: key);

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<QuestProvider>(context, listen: false).loadReadingPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Baca Alkitab Setahun'),
      ),
      body: Consumer<QuestProvider>(
        builder: (context, questProvider, child) {
          if (questProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Progress Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCard(
                          icon: Icons.calendar_today,
                          label: 'Hari Selesai',
                          value: '${questProvider.completedDays.length}/365',
                          color: Colors.white,
                        ),
                        _StatCard(
                          icon: Icons.local_fire_department,
                          label: 'Streak',
                          value: '${questProvider.streak} hari',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(questProvider.progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: questProvider.progress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reading Plan List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questProvider.readingPlan.length,
                  itemBuilder: (context, index) {
                    final quest = questProvider.readingPlan[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: quest.isCompleted
                              ? Colors.green
                              : Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(
                            quest.isCompleted ? Icons.check : Icons.book,
                            color: quest.isCompleted ? Colors.white : Colors.grey,
                          ),
                        ),
                        title: Text(
                          'Hari ${quest.day}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: quest.readings
                              .map((reading) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '📖 ${reading.displayText}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        trailing: quest.isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Tandai Selesai'),
                                      content: Text(
                                        'Tandai bacaan Hari ${quest.day} sebagai selesai?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Ya'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && mounted) {
                                    await questProvider.markDayCompleted(quest.day);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Selamat! Bacaan hari ini selesai! 🎉'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
