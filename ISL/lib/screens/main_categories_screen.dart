

import 'package:flutter/material.dart';
import '/models/category_model.dart';
import '/services/local_api.dart';
import '/screens/sub_categories_screen.dart';
import '/widgets/app_helpers.dart'; 

class MainCategoriesScreen extends StatefulWidget {
  const MainCategoriesScreen({super.key});

  @override
  State<MainCategoriesScreen> createState() => _MainCategoriesScreenState();
}

class _MainCategoriesScreenState extends State<MainCategoriesScreen> {
  List<MainCategory> _mainCategories = [];
  String _errorMessage = '';
  bool _isLoading = true;

  static const String _baseResourceUrl = 'https://www.olabs.edu.in/isl/';

  @override
  void initState() {
    super.initState();
    _fetchMainCategories();
  }

  Future<void> _fetchMainCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final allCategories = await LocalAPI.getAllMainCategories();

      // Filter out "Dictionary" category
      _mainCategories = allCategories
          .where((category) => category.name?.toLowerCase() != 'dictionary')
          .toList();

      debugPrint('API Call: getAllMainCategories() successful. Loaded ${_mainCategories.length} categories.');

    } catch (e) {
      _errorMessage = 'Error loading main categories: ${e.toString()}';
      debugPrint('API Call Error: $_errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // void _handleMainCategoryTap(MainCategory category) {

  //   final String categoryName = category.name ?? 'Untitled Category';
  //   final String? youtubeId = category.youtubeVideoId;

  //   showVideoOverlay(
  //     context: context,
  //     youtubeId: youtubeId,
  //     title: categoryName,
  //     jsonResponse: category,
  //     onEnter: () {
  //       if (category.name != null) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => SubCategoriesScreen(
  //               mainCategoryName: category.name!,
  //               mainCategoryJson: category,
  //             ),
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Cannot navigate: Category name is missing.')),
  //         );
  //       }
  //     },
  //   );
  // }
void _handleMainCategoryTap(MainCategory category) {
  final String categoryName = category.name ?? 'Untitled Category';
  final String? youtubeId = category.youtubeVideoId;

  // Check if YouTube ID is empty or null
  final bool hasVideo = youtubeId != null && youtubeId.isNotEmpty;

  if (!hasVideo) {
    // No video: Navigate directly without overlay
    if (category.name != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubCategoriesScreen(
            mainCategoryName: category.name!,
            mainCategoryJson: category,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot navigate: Category name is missing.')),
      );
    }
  } else {
    // Video exists: Show video overlay
    showVideoOverlay(
      context: context,
      youtubeId: youtubeId,
      title: categoryName,
      jsonResponse: category,
      onEnter: () {
        // Route to subcategory on "Enter"
        if (category.name != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubCategoriesScreen(
                mainCategoryName: category.name!,
                mainCategoryJson: category,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot navigate: Category name is missing.')),
          );
        }
      },
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Categories')),
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
                        itemCount: _mainCategories.length,
                        itemBuilder: (context, index) {
                          final category = _mainCategories[index];
                          
                          // Construct the full Network URL
                          // API returns format: "assets/images/filename.png"
                          // We combine it with: "https://www.olabs.edu.in/isl/"
                          String? fullImageUrl;
                          if (category.image != null && category.image!.isNotEmpty) {
                            // Uri.encodeFull ensures spaces in filenames (like "Alphabets and Words.png") are handled correctly
                            fullImageUrl = Uri.encodeFull('$_baseResourceUrl${category.image}');
                          }

                          return CategoryGridTile(
                            title: category.name ?? 'Untitled',
                            youtubeId: category.youtubeVideoId,
                            imagePath: fullImageUrl, // Passing the HTTP URL now
                            onTap: () => _handleMainCategoryTap(category),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}