
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

class _LogoPickerDialogState extends State<LogoPickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<KnownServiceIcon> _filteredServices = [];
  bool _isLoadingFavicon = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _filteredServices = ServiceIconService.getAllServices();
    
    // Pre-fill URL if we have a website
    if (widget.websiteUrl != null) {
      _urlController.text = widget.websiteUrl!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: 'Auto'),
                Tab(text: 'Website'),
                Tab(text: 'Services'),
                Tab(text: 'Icons'),
                Tab(text: 'File'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAutoTab(),
                  _buildWebsiteTab(),
                  _buildServicesTab(),
                  _buildSystemIconsTab(),
                  _buildFileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoTab() {
    final knownService = ServiceIconService.findServiceIcon(
      widget.account?.name,
      widget.websiteUrl,
    );

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automatic Detection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          
          if (knownService != null) ...[
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: knownService.color?.withOpacity(0.1) ??
                           Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    knownService.icon,
                    color: knownService.color ?? 
                           Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(knownService.name),
                subtitle: Text('Detected from account name'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _useServiceIcon(knownService),
              ),
            ),
            SizedBox(height: 16),
          ],

          if (widget.websiteUrl != null && FaviconService.isValidUrl(widget.websiteUrl!)) ...[
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(Icons.language),
                ),
                title: Text('Website Favicon'),
                subtitle: Text(FaviconService.extractDomain(widget.websiteUrl!) ?? 'From website'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _urlController.text = widget.websiteUrl!;
                  _useFaviconUrl();
                },
              ),
            ),
          ],

          if (knownService == null && (widget.websiteUrl == null || !FaviconService.isValidUrl(widget.websiteUrl!))) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No automatic options available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try the other tabs to manually select a logo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebsiteTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fetch from Website',
            style: Theme.of(context).textTheme.titleMedium,
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
              onPressed: _isLoadingFavicon ? null : _useFaviconUrl,
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
          SizedBox(height: 16),
          Text(
            'This will automatically download the website\'s favicon as your account logo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Services',
              hintText: 'Google, Facebook, etc.',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
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
                      color: service.color?.withOpacity(0.1) ??
                             Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      service.icon,
                      color: service.color ?? 
                             Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(service.name),
                  subtitle: Text(service.keywords.take(3).join(', ')),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _useServiceIcon(service),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSystemIconsTab() {
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

    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
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
                widget.onLogoSelected(LogoType.icon, icon.codePoint.toString());
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
    );
  }

  Widget _buildFileTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Custom Image',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          
          Card(
            child: ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              subtitle: Text('Select an image from your photo gallery'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _pickImageFile,
            ),
          ),
          
          SizedBox(height: 8),
          
          Card(
            child: ListTile(
              leading: Icon(Icons.folder_open),
              title: Text('Choose File'),
              subtitle: Text('Select an image file from your device'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _pickFileFromSystem,
            ),
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Supported formats: PNG, JPEG, GIF, WebP\nRecommended size: 512x512px or smaller',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}