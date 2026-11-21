import 'package:flutter/material.dart';
import '../models/client.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onDelete;

  const ClientCard({
    super.key,
    required this.client,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(client.name),
        subtitle: Text(
          client.hasLocation
              ? 'Location available (${client.locationText})'
              : 'Location not captured',
        ),
        leading: const CircleAvatar(child: Icon(Icons.person)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              client.hasLocation ? Icons.location_on : Icons.location_off,
              color: client.hasLocation ? Colors.green : Colors.grey,
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Supprimer ce client',
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
