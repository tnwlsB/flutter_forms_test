import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkTile extends StatelessWidget {
  final String label;
  final String? url;
  const LinkTile({super.key, required this.label, this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: Text(url!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final uri = Uri.parse(url!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
