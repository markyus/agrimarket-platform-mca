import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'all';
  bool _showVerifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading users: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approveFarmer(int farmerId) async {
    final result = await ApiService.approveFarmer(farmerId);
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Farmer approved'),
              backgroundColor: Colors.green),
        );
        _loadUsers();
      }
    }
  }

  List<dynamic> get _filteredUsers {
    return _users.where((user) {
      final matchesRole =
          _selectedRole == 'all' || user['role'] == _selectedRole;
      final matchesVerified = !_showVerifiedOnly || user['is_verified'] == true;
      final matchesSearch = _searchQuery.isEmpty ||
          user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['phone'].contains(_searchQuery);
      return matchesRole && matchesVerified && matchesSearch;
    }).toList();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'farmer':
        return Colors.green;
      case 'buyer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return '👑';
      case 'farmer':
        return '🌾';
      case 'buyer':
        return '🛒';
      default:
        return '👤';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, or phone...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Roles')),
                          DropdownMenuItem(
                              value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                              value: 'farmer', child: Text('Farmer')),
                          DropdownMenuItem(
                              value: 'buyer', child: Text('Buyer')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _showVerifiedOnly,
                          onChanged: (value) {
                            setState(() {
                              _showVerifiedOnly = value ?? false;
                            });
                          },
                        ),
                        const Text('Show verified only'),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${_filteredUsers.length} users',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No users found',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isPendingFarmer = user['role'] == 'farmer' &&
                              user['is_verified'] == false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role'])
                                    .withValues(alpha: 0.2),
                                child: Text(
                                  _getRoleIcon(user['role']),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user['role'])
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getRoleColor(user['role']),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      user['role'].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getRoleColor(user['role']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isPendingFarmer)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.orange, width: 0.5),
                                      ),
                                      child: const Text(
                                        'PENDING',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.email,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(user['email'] ?? 'No email',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(user['phone'] ?? 'No phone',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    if (user['location'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(user['location'],
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: isPendingFarmer
                                  ? ElevatedButton.icon(
                                      icon: const Icon(Icons.check_circle,
                                          size: 18),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () => _approveFarmer(
                                          user['user_id'] ?? user['id']),
                                    )
                                  : Icon(
                                      user['is_verified'] == true
                                          ? Icons.verified
                                          : Icons.pending,
                                      color: user['is_verified'] == true
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
