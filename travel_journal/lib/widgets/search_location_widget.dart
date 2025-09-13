import 'package:flutter/material.dart';
import 'dart:async';
import '../models/search_result.dart';
import '../services/location_search_service.dart';

class SearchLocationWidget extends StatefulWidget {
  final Function(SearchResult) onLocationSelected;
  
  const SearchLocationWidget({
    super.key,
    required this.onLocationSelected,
  });
  
  @override
  State<SearchLocationWidget> createState() => _SearchLocationWidgetState();
}

class _SearchLocationWidgetState extends State<SearchLocationWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  bool _isSelecting = false;
  Timer? _debounceTimer;
  Timer? _hideResultsTimer;
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideResultsTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (!_focusNode.hasFocus && !_isSelecting) {
      // Hide results after a delay, but only if not currently selecting
      _hideResultsTimer?.cancel();
      _hideResultsTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted && !_isSelecting) {
          setState(() {
            _showResults = false;
          });
        }
      });
    }
  }
  
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showResults = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _showResults = true;
    });
    
    try {
      final results = await LocationSearchService.searchLocation(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }
  
  void _selectResult(SearchResult result) {
    _isSelecting = true;
    _hideResultsTimer?.cancel();
    
    _searchController.text = result.primaryName;
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
    _focusNode.unfocus();
    widget.onLocationSelected(result);
    
    // Reset selection flag after a brief delay
    Timer(const Duration(milliseconds: 100), () {
      _isSelecting = false;
    });
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
  }
  
  IconData _getLocationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'restaurant':
      case 'fast_food':
      case 'cafe':
        return Icons.restaurant;
      case 'hotel':
      case 'motel':
      case 'guest_house':
        return Icons.hotel;
      case 'tourism':
      case 'attraction':
      case 'museum':
        return Icons.attractions;
      case 'airport':
        return Icons.flight;
      case 'railway':
      case 'station':
        return Icons.train;
      case 'hospital':
        return Icons.local_hospital;
      case 'school':
      case 'university':
        return Icons.school;
      case 'shop':
      case 'mall':
        return Icons.shopping_cart;
      default:
        return Icons.place;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Search cities, landmarks, addresses...',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 24,
              ),
              suffixIcon: _isSearching 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: 16,
              ),
            ),
            style: const TextStyle(fontSize: 16),
            onChanged: _onSearchChanged,
            onTap: () {
              if (_searchResults.isNotEmpty) {
                setState(() {
                  _showResults = true;
                });
              }
            },
          ),
        
        // Search results dropdown
        if (_showResults && (_searchResults.isNotEmpty || _isSearching))
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Searching locations...'),
                      ],
                    ),
                  ),
                )
              : _searchResults.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No locations found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return InkWell(
                        onTap: () => _selectResult(result),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getLocationIcon(result.type),
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.primaryName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (result.shortDescription.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        result.shortDescription,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}