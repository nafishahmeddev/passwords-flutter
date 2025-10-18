import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../data/models/account.dart';
import '../../../../business/services/service_icon_service.dart';
import '../../../../business/services/favicon_service.dart';
import '../../../../business/providers/account_form_provider.dart';
import '../../../widgets/account_logo.dart';

class LogoPickerDialog extends StatefulWidget {
  final Account? account;
  final String? websiteUrl;
  final AccountFormProvider? formProvider; // Add provider to access cached favicons
  final Function(LogoType? logoType, String? logoData) onLogoSelected;

  const LogoPickerDialog({
    super.key,
    this.account,
    this.websiteUrl,
    this.formProvider,
    required this.onLogoSelected,
  });

  @override
  State<LogoPickerDialog> createState() => _LogoPickerDialogState();
}

class _LogoPickerDialogState extends State<LogoPickerDialog> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImageFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        widget.onLogoSelected(LogoType.file, image.path);
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickFileFromSystem() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        widget.onLogoSelected(LogoType.file, result.files.single.path!);
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  void _useServiceIcon(KnownServiceIcon service) {
    widget.onLogoSelected(LogoType.icon, service.name);
    Navigator.pop(context);
  }

  void _removeCurrentLogo() {
    widget.onLogoSelected(null, null);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect known service automatically
    String? firstWebsiteUrl;
    if (widget.formProvider != null) {
      final websiteUrls = widget.formProvider!.getWebsiteUrls();
      firstWebsiteUrl = websiteUrls.isNotEmpty ? websiteUrls.first : null;
    }
    
    final detectedService = ServiceIconService.findServiceIcon(
      widget.account?.name,
      firstWebsiteUrl ?? widget.websiteUrl,
    );

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.image,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choose Account Logo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Current logo preview
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Current Logo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 8),
                  AccountLogo(
                    account: widget.account,
                    websiteUrl: widget.websiteUrl,
                    size: 64,
                  ),
                  SizedBox(height: 8),
                  if (widget.account?.logo != null)
                    TextButton.icon(
                      onPressed: _removeCurrentLogo,
                      icon: Icon(Icons.delete_outline, size: 16),
                      label: Text('Remove Logo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-detected service section
                    if (detectedService != null) ...[
                      _buildDetectedServiceSection(detectedService),
                      SizedBox(height: 24),
                    ],

                    // Cached favicons section
                    if (widget.formProvider != null) ...[
                      _buildCachedFaviconsSection(),
                      SizedBox(height: 24),
                    ],

                    // Manual options section
                    _buildManualOptionsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedServiceSection(KnownServiceIcon service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_fix_high,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Detected Service',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: service.color ?? Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                service.icon,
                color: service.color != null 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            title: Text(
              service.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text('Use ${service.name} icon'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _useServiceIcon(service),
          ),
        ),
      ],
    );
  }

  Widget _buildManualOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_search,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Custom Image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Custom image options
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(
                  'Pick from Gallery',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('Choose image from photo gallery'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickImageFile,
              ),
              Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                  child: Icon(
                    Icons.file_upload,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                title: Text(
                  'Pick from Files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('Choose image file from device'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickFileFromSystem,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCachedFaviconsSection() {
    final formProvider = widget.formProvider!;
    final websiteUrls = formProvider.getWebsiteUrls();
    final cachedFavicons = formProvider.cachedFavicons;
    
    // Filter URLs that have cached favicons (successful fetches)
    final availableFavicons = websiteUrls
        .where((url) => cachedFavicons.containsKey(url) && cachedFavicons[url] != null)
        .toList();

    if (availableFavicons.isEmpty) {
      return SizedBox.shrink(); // Don't show section if no favicons
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.web,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Website Favicons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Card(
          child: Column(
            children: availableFavicons.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              final domain = FaviconService.extractDomain(url) ?? url;
              
              return Column(
                children: [
                  if (index > 0) Divider(height: 1),
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: cachedFavicons[url] != null
                            ? Image.memory(
                                cachedFavicons[url]!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.language,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  );
                                },
                              )
                            : Icon(
                                Icons.language,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                      ),
                    ),
                    title: Text(
                      domain,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('Fetched from website'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      widget.onLogoSelected(LogoType.url, url);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}