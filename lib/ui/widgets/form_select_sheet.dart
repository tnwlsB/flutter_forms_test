import 'package:flutter/material.dart';
import '../../models/form_result.dart';

Future<String?> showFormSelectSheet(
    BuildContext context, {
      FormResult? forms,
      FormResult? gas,
    }) {
  final items = <FormResult>[];
  if (forms != null) items.add(forms);
  if (gas != null) items.add(gas);

  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택할 폼이 없습니다. 먼저 A안 또는 B안으로 생성하세요.')),
    );
    return Future.value(null);
  }

  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(
          title: Text('응답 조회할 폼 선택'),
          subtitle: Text('A안(GAS) / B안(Forms API) 중 선택'),
        ),
        for (final r in items)
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(r.sourceLabel),
            subtitle: Text(
              r.liveUrl ?? 'formId: ${r.formId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.pop(context, r.formId),
          ),
      ]),
    ),
  );
}
