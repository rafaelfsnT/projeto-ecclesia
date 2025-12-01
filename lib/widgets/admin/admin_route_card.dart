import 'package:flutter/material.dart';

class AdminRouteCard extends StatelessWidget {
  final String label;
  final String routePath;
  final IconData icon;
  final VoidCallback onTap;

  const AdminRouteCard({
    super.key,
    required this.label,
    required this.routePath,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(routePath, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
