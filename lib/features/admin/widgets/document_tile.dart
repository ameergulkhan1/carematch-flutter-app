import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentTile extends StatelessWidget {
  final String docName;
  final String docUrl;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final bool showCheckbox;

  const DocumentTile({
    Key? key,
    required this.docName,
    required this.docUrl,
    this.isSelected = false,
    this.onSelected,
    this.showCheckbox = false,
  }) : super(key: key);

  String _getDocumentDisplayName(String name) {
    switch (name) {
      case 'nationalId':
        return 'National ID';
      case 'criminalRecord':
        return 'Criminal Record Check';
      case 'healthCertificate':
        return 'Health Certificate';
      case 'proofOfAddress':
        return 'Proof of Address';
      case 'professionalCertificate':
        return 'Professional Certificate';
      default:
        return name.replaceAll('_', ' ').split(' ').map((word) {
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }

  IconData _getDocumentIcon(String name) {
    if (name.contains('certificate') || name.contains('Certificate')) {
      return Icons.workspace_premium;
    } else if (name.contains('id') || name.contains('Id') || name.contains('ID')) {
      return Icons.badge;
    } else if (name.contains('address')) {
      return Icons.home;
    } else if (name.contains('criminal') || name.contains('record')) {
      return Icons.policy;
    } else if (name.contains('health')) {
      return Icons.health_and_safety;
    }
    return Icons.description;
  }

  Future<void> _openDocument(BuildContext context) async {
    // Copy URL to clipboard and show message
    await Clipboard.setData(ClipboardData(text: docUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document URL copied to clipboard: $docUrl'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: showCheckbox
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => onSelected?.call(value ?? false),
              )
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(docName),
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
        title: Text(
          _getDocumentDisplayName(docName),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: const Text(
          'Click to copy URL',
          style: TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _openDocument(context),
          tooltip: 'Copy document URL',
        ),
        onTap: showCheckbox
            ? () => onSelected?.call(!isSelected)
            : () => _openDocument(context),
      ),
    );
  }
}
