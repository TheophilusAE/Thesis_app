import 'package:flutter/material.dart';
import '../services/devotional_service.dart';
import '../models/devotional.dart';

class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({Key? key}) : super(key: key);

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  final DevotionalService _devotionalService = DevotionalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renungan Harian'),
      ),
      body: FutureBuilder<Devotional>(
        future: _devotionalService.getTodaysDevotional(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada renungan'));
          }

          final devotional = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image/Banner
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          devotional.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (devotional.author != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'oleh ${devotional.author}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Verse Reference
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devotional.verseReference,
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        devotional.verse,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue[800],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Renungan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        devotional.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Share functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fitur berbagi akan segera hadir'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Bagikan'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Save to favorites
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Disimpan ke favorit'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bookmark_add),
                              label: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // History Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Renungan Sebelumnya',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Devotional>>(
                        future: _devotionalService.getDevotionalHistory(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: snapshot.data!.map((dev) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.menu_book),
                                  title: Text(dev.title),
                                  subtitle: Text(dev.verseReference),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    // Navigate to devotional detail
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
