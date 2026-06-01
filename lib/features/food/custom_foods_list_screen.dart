import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CustomFoodsListScreen extends StatefulWidget {
  const CustomFoodsListScreen({super.key});

  @override
  State<CustomFoodsListScreen> createState() => _CustomFoodsListScreenState();
}

class _CustomFoodsListScreenState extends State<CustomFoodsListScreen> {
  late Future<List<CustomFood>> _foodsFuture;

  @override
  void initState() {
    super.initState();
    _foodsFuture = context.read<CalTrackRepository>().allCustomFoods();
  }

  void _refresh() {
    setState(() {
      _foodsFuture = context.read<CalTrackRepository>().allCustomFoods();
    });
  }

  Future<void> _delete(CustomFood food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete food?'),
        content: Text(
          'Delete "${food.name}"? This cannot be undone. '
          'Existing log entries will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final repo = context.read<CalTrackRepository>();
    await repo.deleteCustomFood(food.id);
    if (!mounted) return;
    context.showAppSnackBar('Deleted "${food.name}".');
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Custom foods')),
      body: FutureBuilder<List<CustomFood>>(
        future: _foodsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final foods = snap.data!;
          if (foods.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No custom foods yet.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await context.push('/add-custom-food');
                        _refresh();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add food'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4),
              itemCount: foods.length,
              itemBuilder: (context, i) {
                final food = foods[i];
                return Dismissible(
                  key: ValueKey('custom-${food.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) => _delete(food),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        food.name.isNotEmpty
                            ? food.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    title: Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${food.brand ?? ""}${food.brand != null ? " · " : ""}'
                      '${food.calories.round()} kcal per ${food.servingSize.round()} ${food.servingUnit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push(
                        '/add-custom-food',
                        extra: {'existingFood': food},
                      );
                      _refresh();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/add-custom-food');
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
