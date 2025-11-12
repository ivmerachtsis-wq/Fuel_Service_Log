import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '…';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
      });
    } catch (_) {
      // keep default
    }
  }

  Future<void> _openRelease() async {
    final uri = Uri.parse('https://github.com/ivmerachtsis-wq/Fuel_Service_Log/releases');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open release page')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fuel & Service Log', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('App Version: $_version'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openRelease,
              child: const Text('View Release'),
            ),
            const Spacer(),
            Text('© ${DateTime.now().year}'),
          ],
        ),
      ),
    );
  }
}
