import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../folder/presentation/bloc/document_bloc.dart';
import '../../../folder/presentation/bloc/document_event.dart';
import '../../../folder/presentation/bloc/document_state.dart';
import '../../../folder/presentation/screens/add_document_screen.dart';

class DocumentPickerBottomSheet extends StatefulWidget {
  const DocumentPickerBottomSheet({super.key});

  @override
  State<DocumentPickerBottomSheet> createState() => _DocumentPickerBottomSheetState();
}

class _DocumentPickerBottomSheetState extends State<DocumentPickerBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Load only current user's documents (not all public docs)
    context.read<DocumentBloc>().add(LoadMyDocumentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Chọn tài liệu đính kèm',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.upload_file,
                  color: theme.colorScheme.secondary,
                ),
              ),
              title: const Text(
                'Tải lên tài liệu mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final doc = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDocumentScreen()),
                );
                if (doc != null && doc is Map<String, dynamic>) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(doc);
                }
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: Colors.grey.shade50,
              child: Text(
                'Tài liệu đã tải lên',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<DocumentBloc, DocumentState>(
                builder: (context, state) {
                  if (state is DocumentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DocumentError) {
                    return Center(child: Text('Lỗi: ${state.message}'));
                  } else if (state is DocumentsLoaded) {
                    final docs = state.documents;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Bạn chưa có tài liệu nào.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            doc['title'] ?? 'Tài liệu không tên',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            doc['subject'] ?? 'Khác',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(doc);
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
