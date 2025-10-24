import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'database_helper.dart';

@HiveType(typeId: 0)
class CommunityPost extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userName;
  @HiveField(2)
  final String plantName;
  @HiveField(3)
  final String disease;
  @HiveField(4)
  final double confidence;
  @HiveField(5)
  final String imageUrl;
  @HiveField(6)
  final List<String> recommendations;
  @HiveField(7)
  final DateTime timestamp;

  CommunityPost({
    required this.id,
    required this.userName,
    required this.plantName,
    required this.disease,
    required this.confidence,
    required this.imageUrl,
    required this.recommendations,
    required this.timestamp,
  });
}

class CommunityPostAdapter extends TypeAdapter<CommunityPost> {
  @override
  final int typeId = 0;

  @override
  CommunityPost read(BinaryReader reader) {
    return CommunityPost(
      id: reader.read(),
      userName: reader.read(),
      plantName: reader.read(),
      disease: reader.read(),
      confidence: reader.read(),
      imageUrl: reader.read(),
      recommendations: List<String>.from(reader.read()),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, CommunityPost obj) {
    writer.write(obj.id);
    writer.write(obj.userName);
    writer.write(obj.plantName);
    writer.write(obj.disease);
    writer.write(obj.confidence);
    writer.write(obj.imageUrl);
    writer.write(obj.recommendations);
    writer.write(obj.timestamp.millisecondsSinceEpoch);
  }
}

class CommunityForumScreen extends StatefulWidget {
  final Map<String, dynamic>? preFilledData;
  const CommunityForumScreen({super.key, this.preFilledData});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Uuid _uuid = const Uuid();
  late Box<CommunityPost> _postsBox;
  bool _isLoading = true;
  String _searchQuery = '';
  final translator = GoogleTranslator();
  String _selectedLanguage = 'en';

  // Translation function
  Future<String> _translate(String text, {String? to}) async {
    if (_selectedLanguage == 'en') return text;
    try {
      final translation = await translator.translate(
        text,
        to: to ?? _selectedLanguage,
      );
      return translation.text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  @override
  void initState() {
    super.initState();
    _initDatabase();
    if (widget.preFilledData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreatePostDialog(preFilled: widget.preFilledData!);
      });
    }
  }

  Future<void> _initDatabase() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CommunityPostAdapter());
      }
      _postsBox = await Hive.openBox<CommunityPost>('communityPostsBox');
    } catch (e) {
      debugPrint('Database error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String id) async {
    await _postsBox.delete(id);
    setState(() {});
  }

  void _showCreatePostDialog({Map<String, dynamic>? preFilled}) async {
    final plantNameController = TextEditingController(
      text: preFilled?['plantName'] ?? '',
    );
    final diseaseController = TextEditingController(
      text: preFilled?['disease'] ?? '',
    );
    final recommendationsController = TextEditingController(
      text: preFilled?['recommendations'] is List
          ? (preFilled?['recommendations'] as List).join(', ')
          : preFilled?['recommendations'] ?? '',
    );
    final imageUrlController = TextEditingController(
      text: preFilled?['imageUrl'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: FutureBuilder<String>(
          future: _translate('Create New Post'),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Create New Post');
          },
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plantNameController,
                decoration: InputDecoration(
                  labelText: _translate('Plant Name').toString(),
                  hintText: _translate('e.g., Tomato, Rose, Apple').toString(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: diseaseController,
                decoration: InputDecoration(
                  labelText: _translate('Disease').toString(),
                  hintText: _translate(
                    'e.g., Early Blight, Black Spot',
                  ).toString(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: recommendationsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _translate(
                    'Recommendations (comma separated)',
                  ).toString(),
                  hintText: _translate(
                    'Remove affected leaves, Apply fungicide...',
                  ).toString(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: _translate('Image URL').toString(),
                  hintText: _translate(
                    'https://example.com/plant.jpg',
                  ).toString(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: FutureBuilder<String>(
              future: _translate('Cancel'),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Cancel');
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final recommendations = recommendationsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final newPost = CommunityPost(
                id: _uuid.v4(),
                userName:
                    'User_${DateTime.now().millisecondsSinceEpoch % 10000}',
                plantName: plantNameController.text,
                disease: diseaseController.text,
                confidence: preFilled?['confidence'] ?? 0.85,
                imageUrl: imageUrlController.text,
                recommendations: recommendations,
                timestamp: DateTime.now(),
              );

              await _postsBox.put(newPost.id, newPost);
              if (mounted) setState(() {});
              if (mounted) Navigator.pop(context);
            },
            child: FutureBuilder<String>(
              future: _translate('Post'),
              builder: (context, snapshot) {
                return Text(snapshot.data ?? 'Post');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(post.userName),
            subtitle: Text(
              DateFormat('MMM d, y - h:mm a').format(post.timestamp),
            ),
            trailing: Chip(
              label: Text('${(post.confidence * 100).toStringAsFixed(0)}%'),
              backgroundColor: post.confidence > 0.8
                  ? Colors.green[100]
                  : post.confidence > 0.6
                  ? Colors.orange[100]
                  : Colors.red[100],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _translate('Plant'),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 'Plant'}: ${post.plantName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                FutureBuilder<String>(
                  future: _translate('Diagnosis'),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 'Diagnosis'}: ${post.disease}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: post.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.photo)),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _translate('Recommendations'),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 'Recommendations'}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                ...post.recommendations.map(
                  (rec) => ListTile(
                    leading: const Icon(Icons.arrow_right, size: 16),
                    title: Text(rec),
                    minLeadingWidth: 8,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
          ButtonBar(
            children: [
              IconButton(
                icon: const Icon(Icons.thumb_up),
                tooltip: 'Like',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.comment),
                tooltip: 'Comment',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () => _deletePost(post.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: FutureBuilder<String>(
            future: _translate('Community Forum'),
            builder: (context, snapshot) {
              return Text(snapshot.data ?? 'Community Forum');
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _translate('Community Forum'),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Community Forum');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePostDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _changeLanguage,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _translate('Search posts...').toString(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _postsBox.listenable(),
              builder: (context, Box<CommunityPost> box, _) {
                final posts = box.values.toList().reversed.toList();
                final filteredPosts = _searchQuery.isEmpty
                    ? posts
                    : posts
                          .where(
                            (post) =>
                                post.plantName.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                post.disease.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                post.userName.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();

                return filteredPosts.isEmpty
                    ? Center(
                        child: FutureBuilder<String>(
                          future: _translate('No posts found'),
                          builder: (context, snapshot) {
                            return Text(snapshot.data ?? 'No posts found');
                          },
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) =>
                            _buildPostCard(filteredPosts[index]),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: FutureBuilder<String>(
          future: _translate('Select Language'),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Select Language');
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('en', 'English'),
            _buildLanguageOption('es', 'Español'),
            _buildLanguageOption('fr', 'Français'),
            _buildLanguageOption('de', 'Deutsch'),
            _buildLanguageOption('hi', 'हिन्दी'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    return ListTile(
      title: Text(name),
      leading: Radio(
        value: code,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedLanguage = value);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
