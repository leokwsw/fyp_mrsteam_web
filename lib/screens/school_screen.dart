import 'package:flutter/material.dart';
import 'package:fyp_mrsteam_web/constants/colors.dart';
import 'package:fyp_mrsteam_web/core/config/get_it.dart';
import 'package:fyp_mrsteam_web/data/api/api_provider_school.dart';
import 'package:fyp_mrsteam_web/data/model/request/req_school.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_school.dart';
import 'package:fyp_mrsteam_web/screens/create_class_screen.dart'
    show MapPickerDialog, FormUi;
import 'package:fyp_mrsteam_web/services/places_search_service.dart';
import 'package:fyp_mrsteam_web/widgets/app_bar_widget.dart';
import 'package:fyp_mrsteam_web/widgets/custom_button.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final ApiProviderSchool _schoolApi = getIt<ApiProviderSchool>();

  List<SchoolRes> _schools = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await _schoolApi.getSchools(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        limit: 100,
      );
      setState(() {
        _schools = res.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _loadSchools();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _SchoolMapFormDialog(
        onSave: (name, lat, lng, address) async {
          await _schoolApi.createSchool(
            CreateSchoolReq(name, GpsLocation(lat, lng), address: address),
          );
          if (mounted) Navigator.of(context).pop();
          _loadSchools();
          _showSnackBar('School created successfully', Colors.green);
        },
      ),
    );
  }

  void _showEditDialog(SchoolRes school) {
    showDialog(
      context: context,
      builder: (_) => _SchoolMapFormDialog(
        initialName: school.name,
        initialLat: school.gps?.lat,
        initialLng: school.gps?.longitude,
        initialAddress: school.address,
        onSave: (name, lat, lng, address) async {
          await _schoolApi.updateSchool(
            school.id!,
            UpdateSchoolReq(name: name, gps: GpsLocation(lat, lng), address: address),
          );
          if (mounted) Navigator.of(context).pop();
          _loadSchools();
          _showSnackBar('School updated successfully', Colors.green);
        },
      ),
    );
  }

  void _showDeleteDialog(SchoolRes school) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete School',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Text(
            'Are you sure you want to delete "${school.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _schoolApi.deleteSchool(school.id!);
                _loadSchools();
                _showSnackBar('School deleted successfully', Colors.green);
              } catch (e) {
                _showSnackBar('Error: $e', AppColors.statusRed);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBarWidget(currentRoute: '/school'),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'School Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: CustomButton(
                    text: 'New School',
                    onPressed: _showCreateDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search bar
            SizedBox(
              width: 360,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search schools...',
                  hintStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Error: $_errorMessage',
                                  style: const TextStyle(
                                      color: AppColors.statusRed)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _loadSchools,
                                  child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _schools.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No schools found.'
                                    : 'No schools match "$_searchQuery".',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15),
                              ),
                            )
                          : _buildTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(4),
              2: FlexColumnWidth(2),
              3: FixedColumnWidth(120),
            },
            children: [
              TableRow(
                decoration:
                    const BoxDecoration(color: AppColors.cardBackground),
                children: [
                  _headerCell('School Name'),
                  _headerCell('Address'),
                  _headerCell('Created At'),
                  _headerCell('Actions'),
                ],
              ),
              ..._schools.asMap().entries.map((entry) {
                final i = entry.key;
                final school = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color:
                        i.isEven ? Colors.white : const Color(0xFFFAFAFA),
                    border: const Border(
                      bottom: BorderSide(
                          color: AppColors.cardBorder, width: 0.5),
                    ),
                  ),
                  children: [
                    _dataCell(school.name, bold: true),
                    _dataCell(school.address ?? '—'),
                    _dataCell(_formatDate(school.createdAt)),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: AppColors.primary),
                              onPressed: () => _showEditDialog(school),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.statusRed),
                              onPressed: () =>
                                  _showDeleteDialog(school),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String text, {bool bold = false}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── School Form Dialog with Map Picker ─────────────────────────────────────

class _SchoolMapFormDialog extends StatefulWidget {
  final String? initialName;
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;
  final Future<void> Function(String name, double lat, double lng, String? address) onSave;

  const _SchoolMapFormDialog({
    this.initialName,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
    required this.onSave,
  });

  bool get isEditing => initialName != null;

  @override
  State<_SchoolMapFormDialog> createState() => _SchoolMapFormDialogState();
}

class _SchoolMapFormDialogState extends State<_SchoolMapFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  final PlacesSearchService _placesService = PlacesSearchService();

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _locationController = TextEditingController();
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
    _selectedAddress = widget.initialAddress;

    if (_selectedLat != null && _selectedLng != null) {
      _locationController.text =
          'Lat: ${_selectedLat!.toStringAsFixed(6)}, Lng: ${_selectedLng!.toStringAsFixed(6)}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MapPickerDialog(
        initialLat: _selectedLat,
        initialLng: _selectedLng,
      ),
    );

    if (result != null) {
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      final address = result['address'] as String?;
      final street = result['street'] as String?;

      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        _selectedAddress = address;

        if (lat != null && lng != null) {
          _locationController.text =
              'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
        } else {
          _locationController.clear();
        }

        if (street != null && street.trim().isNotEmpty) {
          _addressController.text = street;
        } else if (address != null && address.trim().isNotEmpty) {
          _addressController.text = address;
        }
      });

      // Fallback: if MapPickerDialog didn't return address, do our own reverse geocode
      if ((address == null || address.trim().isEmpty) && lat != null && lng != null) {
        setState(() => _isLoadingAddress = true);
        try {
          final geocoded = await _placesService.reverseGeocode(lat, lng);
          if (mounted && geocoded != null && geocoded.trim().isNotEmpty) {
            setState(() {
              _selectedAddress = geocoded.trim();
              _addressController.text = geocoded.trim();
              _isLoadingAddress = false;
            });
          } else {
            if (mounted) setState(() => _isLoadingAddress = false);
          }
        } catch (_) {
          if (mounted) setState(() => _isLoadingAddress = false);
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter school name');
      return;
    }
    if (_selectedLat == null || _selectedLng == null) {
      setState(() => _errorMessage = 'Please select a location on the map');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final address = _addressController.text.trim().isEmpty
          ? _selectedAddress
          : _addressController.text.trim();
      await widget.onSave(
          _nameController.text.trim(), _selectedLat!, _selectedLng!, address);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isEditing ? 'Edit School' : 'Create New School',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // School name
            const Text(
              'School Name *',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration:
                  FormUi.inputDecoration(hintText: 'Enter school name'),
            ),
            const SizedBox(height: 24),

            // GPS Location
            const Text(
              'GPS Location *',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    readOnly: true,
                    decoration: FormUi.inputDecoration(
                      hintText: 'Click map to select location',
                      prefixIcon: const Icon(Icons.location_on,
                          color: AppColors.textSecondary),
                    ),
                    onTap: _openMapPicker,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map,
                        color: Colors.white, size: 20),
                    label: const Text('Map',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Address
            const Text(
              'Address',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: FormUi.inputDecoration(
                hintText: _isLoadingAddress
                    ? 'Loading address...'
                    : 'Auto-filled after selecting location',
                prefixIcon: _isLoadingAddress
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.place_outlined,
                        color: AppColors.textSecondary),
              ),
            ),

            if (_selectedAddress != null &&
                _selectedAddress!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _selectedAddress!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  height: 44,
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            widget.isEditing
                                ? 'Save Changes'
                                : 'Create School',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
