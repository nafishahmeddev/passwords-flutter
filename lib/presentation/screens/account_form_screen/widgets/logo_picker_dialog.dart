import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/account.dart';
import '../../../../business/services/service_icon_service.dart';
import '../../../../business/services/favicon_service.dart';
import '../../../widgets/account_logo.dart';

enum LogoSelectionType { auto, favicon, service, systemIcon, customFile }

class LogoPickerDialog extends StatefulWidget {
  final Account? account;
  final String? websiteUrl;
  final Function(LogoType? logoType, String? logoData) onLogoSelected;

  const LogoPickerDialog({
    super.key,
    this.account,
    this.websiteUrl,
    required this.onLogoSelected,
  });

  @override
  State<LogoPickerDialog> createState() => _LogoPickerDialogState();
}

class _LogoPickerDialogState extends State<LogoPickerDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<KnownServiceIcon> _filteredServices = [];
  bool _isLoadingFavicon = false;

  @override
  void initState() {
    super.initState();
    _filteredServices = ServiceIconService.getAllServices();

    // Pre-fill URL if we have a website
    if (widget.websiteUrl != null) {
      _urlController.text = widget.websiteUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredServices = ServiceIconService.searchServices(query);
    });
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

  Future<void> _useFaviconUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !FaviconService.isValidUrl(url)) {
      _showError('Please enter a valid URL');
      return;
    }

    setState(() {
      _isLoadingFavicon = true;
    });

    try {
      // Test if favicon can be loaded
      final faviconData = await FaviconService.fetchFavicon(url);
      setState(() {
        _isLoadingFavicon = false;
      });

      if (faviconData != null) {
        widget.onLogoSelected(LogoType.url, url);
        Navigator.pop(context);
      } else {
        _showError('No favicon found at this URL');
      }
    } catch (e) {
      setState(() {
        _isLoadingFavicon = false;
      });
      _showError('Failed to load favicon: $e');
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
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

            // Content with grouped buttons
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAutomaticDetectionSection(),
                    SizedBox(height: 24),
                    _buildCustomSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomaticDetectionSection() {
    final knownService = ServiceIconService.findServiceIcon(
      widget.account?.name,
      widget.websiteUrl,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic Detection',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),

        // Website Favicon Button
        if (widget.websiteUrl != null &&
            FaviconService.isValidUrl(widget.websiteUrl!))
          Card(
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: _isLoadingFavicon
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
              ),
              title: Text(
                'Website Favicon',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _isLoadingFavicon
                    ? 'Loading favicon...'
                    : FaviconService.extractDomain(widget.websiteUrl!) ??
                          'From website',
              ),
              trailing: _isLoadingFavicon
                  ? null
                  : Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isLoadingFavicon
                  ? null
                  : () {
                      _urlController.text = widget.websiteUrl!;
                      _useFaviconUrl();
                    },
            ),
          )
        else
          // Show manual website favicon option
          Card(
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                'Website Favicon',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Enter website URL to fetch favicon'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showWebsiteFaviconBottomSheet(),
            ),
          ),

        if (widget.websiteUrl != null &&
            FaviconService.isValidUrl(widget.websiteUrl!))
          SizedBox(height: 12),

        // Icon Detected Button
        if (knownService != null)
          Card(
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      knownService.color?.withOpacity(0.1) ??
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Icon(
                  knownService.icon,
                  color:
                      knownService.color ??
                      Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(
                'Icon Detected',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${knownService.name} - Detected from account name',
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _useServiceIcon(knownService),
            ),
          ),

        // Show message if no automatic options available
        if (knownService == null &&
            (widget.websiteUrl == null ||
                !FaviconService.isValidUrl(widget.websiteUrl!)))
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 8),
                Text(
                  'No automatic options available',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Use the custom options below to select a logo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),

        // Services Button
        Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.tertiaryContainer,
              ),
              child: Icon(
                Icons.apps,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            title: Text(
              'Services',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Browse popular service icons'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showServicesBottomSheet(),
          ),
        ),

        SizedBox(height: 12),

        // Icons Button
        Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: Icon(
                Icons.category,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            title: Text(
              'Icons',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Choose from system icons'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSystemIconsBottomSheet(),
          ),
        ),

        SizedBox(height: 12),

        // Choose from Gallery Button
        Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              'Choose from Gallery',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Select an image from your photo gallery'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickImageFile,
          ),
        ),

        SizedBox(height: 12),

        // Choose Files Button
        Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: Icon(
                Icons.folder_open,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(
              'Choose Files',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Select an image file from your device'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _pickFileFromSystem,
          ),
        ),
      ],
    );
  }

  void _showWebsiteFaviconBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Website Favicon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingFavicon
                    ? null
                    : () {
                        Navigator.pop(context);
                        _useFaviconUrl();
                      },
                icon: _isLoadingFavicon
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.download),
                label: Text(_isLoadingFavicon ? 'Loading...' : 'Fetch Favicon'),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This will automatically download the website\'s favicon as your account logo.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Services', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Services',
                  hintText: 'Google, Facebook, etc.',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = _filteredServices[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color:
                                service.color?.withOpacity(0.1) ??
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child: Icon(
                            service.icon,
                            color:
                                service.color ??
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(service.name),
                        subtitle: Text(service.keywords.take(3).join(', ')),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          _useServiceIcon(service);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSystemIconsBottomSheet() {
    final iconData = [
      Icons.account_circle,
      Icons.person,
      Icons.business,
      Icons.work,
      Icons.home,
      Icons.school,
      Icons.shopping_cart,
      Icons.restaurant,
      Icons.local_hospital,
      Icons.local_gas_station,
      Icons.fitness_center,
      Icons.music_note,
      Icons.movie,
      Icons.sports_esports,
      Icons.camera_alt,
      Icons.phone,
      Icons.email,
      Icons.message,
      Icons.favorite,
      Icons.star,
      Icons.bookmark,
      Icons.lightbulb,
      Icons.build,
      Icons.security,
      Icons.vpn_key,
      Icons.credit_card,
      Icons.account_balance,
      Icons.local_atm,
      Icons.flight,
      Icons.hotel,
      Icons.directions_car,
      Icons.train,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'System Icons',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: iconData.length,
                  itemBuilder: (context, index) {
                    final icon = iconData[index];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onLogoSelected(
                            LogoType.icon,
                            icon.codePoint.toString(),
                          );
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
