import 'package:flutter/material.dart';

class LocationPickerBottomSheet extends StatefulWidget {
  final String? initialLocation;

  const LocationPickerBottomSheet({super.key, this.initialLocation});

  @override
  State<LocationPickerBottomSheet> createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<LocationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _suggestions = [
    'Hà Nội',
    'Thành phố Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Quán Cafe',
    'Trường Đại học',
    'Thư viện',
    'Nhà',
    'Công ty',
  ];

  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialLocation ?? '';
    _filteredSuggestions = List.from(_suggestions);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSuggestions = List.from(_suggestions);
      } else {
        _filteredSuggestions = _suggestions
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectLocation(String location) {
    Navigator.pop(context, location);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Check-in địa điểm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.initialLocation != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context, ''), // Trả về chuỗi rỗng để xoá
                    child: const Text('Gỡ bỏ', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm địa điểm...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final customLocation = _searchController.text.trim();
                    if (customLocation.isNotEmpty) {
                      _selectLocation(customLocation);
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final loc = _filteredSuggestions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.redAccent),
                  ),
                  title: Text(loc, style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () => _selectLocation(loc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
