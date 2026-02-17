import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/ui/igris_ui.dart';

/// Example screen demonstrating Igris UI components
/// This file shows how to use IgrisButton, IgrisCard, IgrisInputField, etc.
class IgrisComponentsExample extends ConsumerStatefulWidget {
  const IgrisComponentsExample({super.key});

  @override
  ConsumerState<IgrisComponentsExample> createState() => _IgrisComponentsExampleState();
}

class _IgrisComponentsExampleState extends ConsumerState<IgrisComponentsExample> {
  final _taskController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _showExampleDialog() async {
    final confirmed = await IgrisDialog.showConfirmation(
      context: context,
      title: 'Delete Task',
      description: 'This action cannot be undone. Are you sure?',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  Future<void> _showExampleBottomSheet() async {
    final selected = await IgrisBottomSheet.showList<String>(
      context: context,
      title: 'Select Action',
      items: [
        const IgrisBottomSheetItem(
          label: 'Edit Task',
          subtitle: 'Modify task details',
          icon: Icons.edit,
          value: 'edit',
        ),
        const IgrisBottomSheetItem(
          label: 'Share Task',
          subtitle: 'Share with others',
          icon: Icons.share,
          value: 'share',
        ),
        const IgrisBottomSheetItem(
          label: 'Delete Task',
          icon: Icons.delete,
          isDestructive: true,
          value: 'delete',
        ),
      ],
    );

    if (selected != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: $selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Igris Components'),
      ),
      body: SingleChildScrollView(
        padding: DesignSystem.paddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buttons Section
            IgrisCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buttons',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  IgrisButton(
                    text: 'Primary Button',
                    onPressed: () {},
                    icon: Icons.add,
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  IgrisButton(
                    text: 'Destructive Button',
                    variant: IgrisButtonVariant.destructive,
                    onPressed: _showExampleDialog,
                    icon: Icons.delete,
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  IgrisButton(
                    text: 'Outline Button',
                    variant: IgrisButtonVariant.outline,
                    onPressed: () {},
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  IgrisButton(
                    text: 'Full Width Button',
                    fullWidth: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignSystem.spacing24),

            // Input Fields Section
            IgrisCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Input Fields',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  IgrisInputField(
                    label: 'Task Name',
                    hint: 'Enter task name',
                    controller: _taskController,
                    prefixIcon: Icons.task,
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  IgrisInputField(
                    label: 'Description',
                    hint: 'Enter description',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignSystem.spacing24),

            // Controls Section
            IgrisCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Controls',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  IgrisSwitch(
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                    label: 'Enable notifications',
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  IgrisCheckbox(
                    value: _agreedToTerms,
                    onChanged: (value) => setState(() => _agreedToTerms = value),
                    label: 'I agree to the terms and conditions',
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignSystem.spacing24),

            // Actions Section
            IgrisCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dialogs & Sheets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  IgrisButton(
                    text: 'Show Dialog',
                    onPressed: _showExampleDialog,
                    icon: Icons.info_outline,
                    fullWidth: true,
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  IgrisButton(
                    text: 'Show Bottom Sheet',
                    onPressed: _showExampleBottomSheet,
                    icon: Icons.more_horiz,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignSystem.spacing24),

            // Card Variants Section
            const Text(
              'Card Variants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: DesignSystem.spacing12),
            IgrisCard(
              variant: IgrisCardVariant.elevated,
              showGlow: true,
              child: const Text('Elevated card with glow'),
            ),
            SizedBox(height: DesignSystem.spacing12),
            IgrisCard(
              variant: IgrisCardVariant.surface,
              child: const Text('Surface card'),
            ),
            SizedBox(height: DesignSystem.spacing12),
            IgrisCard(
              variant: IgrisCardVariant.transparent,
              showBorder: false,
              child: const Text('Transparent card'),
            ),
          ],
        ),
      ),
    );
  }
}
