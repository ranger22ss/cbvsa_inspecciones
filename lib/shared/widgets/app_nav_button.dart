import 'package:flutter/material.dart';

class AppNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onPressed;
  const AppNavButton({super.key, required this.icon, required this.label, this.description, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: scheme.onPrimaryContainer)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), if (description != null) ...[const SizedBox(height: 3), Text(description!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))]])),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: scheme.outline),
          ]),
        ),
      ),
    );
  }
}

