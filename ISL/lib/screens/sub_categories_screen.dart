import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/services/local_api.dart';
import '/screens/main_tabs_screen.dart';
import '/widgets/app_helpers.dart'; 
import '/screens/sub_tab_content_screen.dart';

class SubCategoriesScreen extends StatefulWidget {
  final String mainCategoryName;
  final Object? mainCategoryJson;

  const SubCategoriesScreen({
    super.key,
    required this.mainCategoryName,
    this.mainCategoryJson,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  List<SubCategory> _subCategories = [];
  String _errorMessage = '';
  bool _isLoading = true;

  // Base URL for ISL resources
  static const String _baseResourceUrl = 'https://www.olabs.edu.in/isl/';

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _subCategories = await LocalAPI.getAllSubCategoriesForMainCategory(widget.mainCategoryName);
      debugPrint('API Call: getAllSubCategoriesForMainCategory("${widget.mainCategoryName}") successful.');
    } catch (e) {
      _errorMessage = 'Error loading subcategories: ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // void _handleSubCategoryTap(SubCategory subCategory) {
  //   setState(() {
  //     _lastSelectedSubCategoryJson = subCategory;
  //   });

  //   final String subCategoryName = subCategory.name ?? 'Untitled Subcategory';
  //   final String? youtubeId = subCategory.youtubeVideoId;

  //   showVideoOverlay(
  //     context: context,
  //     youtubeId: youtubeId,
  //     title: subCategoryName,
  //     jsonResponse: subCategory,
  //     onEnter: () {
  //       if (subCategory.name != null) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => MainTabsScreen(
  //               mainCategoryName: widget.mainCategoryName,
  //               subCategoryName: subCategory.name!,
  //               subCategoryJson: subCategory,
  //             ),
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Cannot navigate: Subcategory name is missing.')),
  //         );
  //       }
  //     },
  //   );
  // }



void _handleSubCategoryTap(SubCategory subCategory) async {  // ✅ Added async
  final String subCategoryName = subCategory.name ?? 'Untitled Subcategory';
  final String? youtubeId = subCategory.youtubeVideoId;
  
  // Check if YouTube ID is empty or null
  final bool hasVideo = youtubeId != null && youtubeId.isNotEmpty;

  // Check how many main tabs exist for this subcategory
  List<MainTab> mainTabs = [];
  try {
    mainTabs = await LocalAPI.getAllMainTabsForSubCategory(
      widget.mainCategoryName, 
      subCategoryName
    );
  } catch (e) {
    debugPrint('Error fetching main tabs: $e');
  }

  // Function to navigate based on main tabs count
  void navigateToContent() {
    if (mainTabs.length == 1) {
      // Skip MainTabsScreen, go directly to SubTabContentScreen
      final mainTab = mainTabs.first;
      if (mainTab.id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubTabContentScreen(
              mainCategoryName: widget.mainCategoryName,
              subCategoryName: subCategoryName,
              mainTabId: mainTab.id!,
              mainTabJson: mainTab,
            ),
          ),
        );
      }
    } else {
      // Multiple main tabs, show MainTabsScreen as normal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainTabsScreen(
            mainCategoryName: widget.mainCategoryName,
            subCategoryName: subCategoryName,
            subCategoryJson: subCategory,
          ),
        ),
      );
    }
  }

  // Handle video overlay or direct navigation
  if (!hasVideo) {
    navigateToContent();  
  } else {
    showVideoOverlay(
      context: context,
      youtubeId: youtubeId,
      title: subCategoryName,
      jsonResponse: subCategory,
      onEnter: navigateToContent,  
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mainCategoryName)),
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
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = _subCategories[index];
                          
                          // Construct the full Network URL for the sub-category image
                          String? fullImageUrl;
                          if (subCategory.image != null && subCategory.image!.isNotEmpty) {
                            fullImageUrl = Uri.encodeFull('$_baseResourceUrl${subCategory.image}');
                          }

                          return CategoryGridTile(
                            title: subCategory.name ?? 'Untitled',
                            youtubeId: subCategory.youtubeVideoId,
                            imagePath: fullImageUrl, // Pass the constructed URL
                            onTap: () => _handleSubCategoryTap(subCategory),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}