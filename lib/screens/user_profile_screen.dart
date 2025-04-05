import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../providers/user_provider.dart';
import '../providers/post_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isRefreshing = false;
  Stream<List<PostModel>>? _userPostsStream;
  final TextEditingController _achievementController = TextEditingController();
  final TextEditingController _certificationController = TextEditingController();
  final TextEditingController _sportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  @override
  void dispose() {
    _achievementController.dispose();
    _certificationController.dispose();
    _sportController.dispose();
    super.dispose();
  }

  void _loadUserPosts() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    setState(() {
      _userPostsStream = postProvider.getUserPosts(widget.user.id);
    });
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUserData();
      _loadUserPosts();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _showAddDialog(String title, TextEditingController controller, Function(String) onAdd) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
                controller.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final isCurrentUser = currentUser?.id == widget.user.id;
    final isFollowing = currentUser?.following.contains(widget.user.id) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          if (!isCurrentUser)
            IconButton(
              icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
              onPressed: () {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                if (isFollowing) {
                  userProvider.unfollowUser(widget.user.id);
                } else {
                  userProvider.followUser(widget.user.id);
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const Divider(),
              if (isCurrentUser) _buildEditSection(),
              _buildAchievementsSection(),
              _buildCertificationsSection(),
              _buildSportsSection(),
              const Divider(),
              _buildPostsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userProvider = Provider.of<UserProvider>(context);
    final isCurrentUser = userProvider.currentUser?.id == widget.user.id;
    final isFollowing = userProvider.currentUser?.following.contains(widget.user.id) ?? false;
    final isConnected = userProvider.currentUser?.connections.contains(widget.user.id) ?? false;

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.user.profileImage != null
                  ? NetworkImage(widget.user.profileImage!)
                  : null,
              child: widget.user.profileImage == null
                  ? Text(
                      widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.userType.toString().split('.').last,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (widget.user.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.user.bio!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!isCurrentUser) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isFollowing) {
                      userProvider.unfollowUser(widget.user.id);
                    } else {
                      userProvider.followUser(widget.user.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
                    foregroundColor: isFollowing ? Colors.black : Colors.white,
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isConnected) {
                      userProvider.disconnectFromUser(widget.user.id);
                    } else {
                      userProvider.connectWithUser(widget.user.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.grey[300] : Colors.green,
                    foregroundColor: isConnected ? Colors.black : Colors.white,
                  ),
                  child: Text(isConnected ? 'Disconnect' : 'Connect'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEditSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to edit profile screen
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildAddButton(
                'Achievement',
                Icons.emoji_events,
                () => _showAddDialog(
                  'Achievement',
                  _achievementController,
                  (achievement) {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    userProvider.addAchievement(achievement);
                  },
                ),
              ),
              _buildAddButton(
                'Certification',
                Icons.card_membership,
                () => _showAddDialog(
                  'Certification',
                  _certificationController,
                  (certification) {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    userProvider.addCertification(certification);
                  },
                ),
              ),
              _buildAddButton(
                'Sport',
                Icons.sports,
                () => _showAddDialog(
                  'Sport',
                  _sportController,
                  (sport) {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    userProvider.updateProfile(
                      sports: [...widget.user.sports, sport],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        'Add $label',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    if (widget.user.achievements.isEmpty) return const SizedBox.shrink();
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final isCurrentUser = currentUser?.id == widget.user.id;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditListDialog(
                    'Achievements',
                    widget.user.achievements,
                    (achievements) {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      userProvider.updateProfile(achievements: achievements);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.user.achievements.map((achievement) {
              return Chip(
                label: Text(
                  achievement,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                avatar: const Icon(Icons.emoji_events, size: 16),
                onDeleted: isCurrentUser ? () {
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final updatedAchievements = List<String>.from(widget.user.achievements)
                    ..remove(achievement);
                  userProvider.updateProfile(achievements: updatedAchievements);
                } : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection() {
    if (widget.user.certifications.isEmpty) return const SizedBox.shrink();
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final isCurrentUser = currentUser?.id == widget.user.id;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Certifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditListDialog(
                    'Certifications',
                    widget.user.certifications,
                    (certifications) {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      userProvider.updateProfile(certifications: certifications);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.user.certifications.map((certification) {
              return Chip(
                label: Text(
                  certification,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                avatar: const Icon(Icons.card_membership, size: 16),
                onDeleted: isCurrentUser ? () {
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final updatedCertifications = List<String>.from(widget.user.certifications)
                    ..remove(certification);
                  userProvider.updateProfile(certifications: updatedCertifications);
                } : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsSection() {
    if (widget.user.sports.isEmpty) return const SizedBox.shrink();
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final isCurrentUser = currentUser?.id == widget.user.id;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sports',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditListDialog(
                    'Sports',
                    widget.user.sports,
                    (sports) {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      userProvider.updateProfile(sports: sports);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.user.sports.map((sport) {
              return Chip(
                label: Text(
                  sport,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                avatar: const Icon(Icons.sports, size: 16),
                onDeleted: isCurrentUser ? () {
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final updatedSports = List<String>.from(widget.user.sports)
                    ..remove(sport);
                  userProvider.updateProfile(sports: updatedSports);
                } : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (_userPostsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<PostModel>>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No posts yet'),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                // TODO: Navigate to post detail screen
              },
              child: post.images.isNotEmpty
                  ? Image.network(
                      post.images.first,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
            );
          },
        );
      },
    );
  }

  void _showEditListDialog(String title, List<String> items, Function(List<String>) onSave) {
    final TextEditingController controller = TextEditingController();
    List<String> editedItems = List.from(items);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit $title'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Add new $title',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            editedItems.add(controller.text);
                            controller.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: editedItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(editedItems[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              editedItems.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(editedItems);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
} 