import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../providers/user_provider.dart';
import 'events_screen.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          FeedTab(),
          ExploreTab(),
          EventsScreen(),
          MessagesTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // TODO: Replace with actual posts
      itemBuilder: (context, index) {
        return const PostCard();
      },
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://placeholder.com/150'),
            ),
            title: const Text('User Name'),
            subtitle: const Text('2 hours ago'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Implement post options
              },
            ),
          ),
          if (true) // TODO: Check if post has image
            Image.network(
              'https://placeholder.com/600x400',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post content goes here...',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        // TODO: Implement like functionality
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {
                        // TODO: Implement comment functionality
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  Stream<List<UserModel>>? _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _usersStream = null);
      return;
    }

    final userProvider = Provider.of<UserService>(context, listen: false);
    setState(() => _usersStream = userProvider.searchUsers(query));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),
        Expanded(
          child: _usersStream == null
              ? const Center(
                  child: Text('Start typing to search for users'),
                )
              : StreamBuilder<List<UserModel>>(
                  stream: _usersStream,
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
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final users = snapshot.data!;
                    if (users.isEmpty) {
                      return const Center(
                        child: Text('No users found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserListItem(user: user);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UserListItem extends StatelessWidget {
  final UserModel user;

  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final isCurrentUser = currentUser?.id == user.id;
    final isFollowing = currentUser?.following.contains(user.id) ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profileImage != null
            ? NetworkImage(user.profileImage!)
            : null,
        child: user.profileImage == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.userType.toString().split('.').last),
      trailing: isCurrentUser
          ? null
          : TextButton(
              onPressed: () {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                if (isFollowing) {
                  userProvider.unfollowUser(user.id);
                } else {
                  userProvider.followUser(user.id);
                }
              },
              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
            ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(user: user),
          ),
        );
      },
    );
  }
}

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10, // TODO: Replace with actual conversations
      itemBuilder: (context, index) {
        return const MessageListItem();
      },
    );
  }
}

class MessageListItem extends StatelessWidget {
  const MessageListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundImage: NetworkImage('https://placeholder.com/150'),
      ),
      title: const Text('User Name'),
      subtitle: const Text('Last message...'),
      trailing: const Text('2h ago'),
      onTap: () {
        // TODO: Navigate to chat screen
      },
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isRefreshing = false;

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUserData();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _signOut() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (userProvider.isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProvider.error != null && user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${userProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                userProvider.clearError();
                _refreshProfile();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (user == null) {
      return const Center(child: Text('No user data available'));
    }

    return UserProfileScreen(user: user);
  }
} 