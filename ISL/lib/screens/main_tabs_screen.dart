

import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/services/local_api.dart';
import '/screens/sub_tab_content_screen.dart';
import '/widgets/app_helpers.dart';

class MainTabsScreen extends StatefulWidget {
  final String mainCategoryName;
  final String subCategoryName;
  final Object? subCategoryJson;

  const MainTabsScreen({
    super.key,
    required this.mainCategoryName,
    required this.subCategoryName,
    this.subCategoryJson,
  });

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  List<MainTab> _mainTabs = [];
  String _errorMessage = '';
  bool _isLoading = true;

  // Base URL for ISL resources
  static const String _baseResourceUrl = 'https://www.olabs.edu.in/isl/';

  @override
  void initState() {
    super.initState();
    _fetchMainTabs();
  }

  Future<void> _fetchMainTabs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _mainTabs = await LocalAPI.getAllMainTabsForSubCategory(
          widget.mainCategoryName, widget.subCategoryName);
      debugPrint('API Call: getAllMainTabsForSubCategory("${widget.mainCategoryName}", "${widget.subCategoryName}") successful.');
    } catch (e) {
      _errorMessage = 'Error loading main tabs: ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleMainTabTap(MainTab mainTab) {
    final String mainTabName = mainTab.name ?? 'Untitled Tab';
    final String? youtubeId = mainTab.youtubeVideoId;

    showVideoOverlay(
      context: context,
      youtubeId: youtubeId,
      title: mainTabName,
      jsonResponse: mainTab,
      onEnter: () {
        if (mainTab.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubTabContentScreen(
                mainCategoryName: widget.mainCategoryName,
                subCategoryName: widget.subCategoryName,
                mainTabId: mainTab.id!,
                mainTabJson: mainTab,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot navigate: Main tab ID is missing.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subCategoryName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _mainTabs.length,
                        itemBuilder: (context, index) {
                          final mainTab = _mainTabs[index];
                          
                          // 1. Construct API Image URL
                          String? fullImageUrl;
                          // Requires MainTab model to have 'image' field
                          if (mainTab.image != null && mainTab.image!.isNotEmpty) {
                            fullImageUrl = Uri.encodeFull('$_baseResourceUrl${mainTab.image}');
                          }

                          // 2. Fallback to YouTube Thumbnail
                          String? thumbnailUrl;
                          if (mainTab.youtubeVideoId != null && mainTab.youtubeVideoId!.isNotEmpty) {
                            thumbnailUrl = 'https://img.youtube.com/vi/${mainTab.youtubeVideoId}/mqdefault.jpg';
                          }

                          // Prefer API Image, fall back to Thumbnail
                          final String? displayImage = fullImageUrl ?? thumbnailUrl;

                          return CategoryGridTile(
                            title: mainTab.name ?? 'Untitled',
                            youtubeId: mainTab.youtubeVideoId,
                            imagePath: displayImage, 
                            onTap: () => _handleMainTabTap(mainTab),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}