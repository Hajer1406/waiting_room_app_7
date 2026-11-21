import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/queue_state.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/queue_provider.dart';
import '../services/sync_service.dart';
import '../widgets/client_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/offline_banner.dart';
import '../widgets/queue_empty_widget.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().fetchInitialQueue();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<QueueProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addClient([String? customName]) async {
    final name = (customName ?? _nameController.text).trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final error = await context.read<QueueProvider>().addClient(name);
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        _nameController.clear();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = context.watch<QueueProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final auth = context.watch<AuthProvider?>();

    final isStaff = auth == null || auth.isStaff;
    final currentUser = auth?.user;

    // Check if the current client is already in the queue
    int clientPosition = -1;
    if (currentUser != null && !isStaff) {
      final myName = currentUser.name.toLowerCase();
      clientPosition = queueProvider.clients.indexWhere(
        (c) => c.name.toLowerCase() == myName,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Single-Room Waiting Queue',
              style: TextStyle(fontSize: 18),
            ),
            if (currentUser != null)
              Text(
                '${currentUser.name} • ${currentUser.role.displayName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isStaff ? Colors.green.shade800 : Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchronize',
            onPressed: () async {
              try {
                final syncService = context.read<SyncService?>();
                final qProvider = context.read<QueueProvider>();
                final messenger = ScaffoldMessenger.of(context);
                if (syncService != null) {
                  await syncService.synchronize();
                }
                await qProvider.refresh();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Synchronization completed')),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sync failed: $e')),
                  );
                }
              }
            },
          ),
          if (auth != null && auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: () => auth.signOut(),
            ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(status: connectivity.status),

          // Client personalized status banner
          if (currentUser != null && !isStaff) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: clientPosition >= 0 ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: clientPosition >= 0 ? Colors.green.shade300 : Colors.blue.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    clientPosition >= 0 ? Icons.check_circle_outline : Icons.info_outline,
                    color: clientPosition >= 0 ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      clientPosition >= 0
                          ? 'Vous êtes dans la file d\'attente : Position #${clientPosition + 1} sur ${queueProvider.clients.length}'
                          : 'Vous n\'êtes pas encore inscrit dans la file.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: clientPosition >= 0 ? Colors.green.shade900 : Colors.blue.shade900,
                      ),
                    ),
                  ),
                  if (clientPosition < 0)
                    FilledButton.tonal(
                      onPressed: _isSubmitting ? null : () => _addClient(currentUser.name),
                      child: const Text('Rejoindre'),
                    ),
                ],
              ),
            ),
          ],

          // Form to add client
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: isStaff ? 'Nom du client' : 'Ajouter un autre nom',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addClient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _addClient(),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clients: ${queueProvider.clients.length}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (queueProvider.isLoadingMore)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _buildQueueContent(queueProvider, isStaff: isStaff),
          ),

          // Bottom action button: Next Client (restricted to staff)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  key: const Key('nextClientButton'),
                  onPressed: (!isStaff || queueProvider.clients.isEmpty)
                      ? null
                      : () => queueProvider.nextClient(),
                  icon: Icon(isStaff ? Icons.arrow_forward : Icons.lock_outline),
                  label: Text(
                    isStaff ? 'Next Client' : 'Next Client (Réservé aux Agents)',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isStaff ? Colors.green : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueContent(QueueProvider provider, {required bool isStaff}) {
    switch (provider.state) {
      case QueueState.initial:
      case QueueState.loading:
        return const LoadingWidget(message: 'Loading queue...');
      case QueueState.empty:
        return const QueueEmptyWidget();
      case QueueState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.errorMessage ?? 'An error occurred',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => provider.fetchInitialQueue(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case QueueState.loaded:
      case QueueState.refreshing:
      case QueueState.loadingMore:
        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: provider.clients.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.clients.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final client = provider.clients[index];

              // Only staff can swipe to delete
              if (isStaff) {
                return Dismissible(
                  key: Key(client.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => provider.removeClient(client.id),
                  child: ClientCard(client: client),
                );
              }

              return ClientCard(client: client);
            },
          ),
        );
    }
  }
}
