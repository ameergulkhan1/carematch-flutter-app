import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/auth_service.dart';
import 'caregiver_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'pages/dashboard_page.dart';
import 'pages/bookings_page.dart';
import 'pages/availability_page.dart';
import 'pages/profile_page.dart';
import 'pages/reviews_page.dart';
import 'pages/settings_page.dart';
import '../../../chat/screens/chat_list_screen.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  Map<String, dynamic>? _caregiverData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaregiverData();
  }

  Future<void> _loadCaregiverData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _caregiverData = doc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading caregiver data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: CaregiverColors.primary,
          ),
        ),
      );
    }

    final caregiverName = _caregiverData?['fullName'] ?? 'Caregiver';

    return Scaffold(
      backgroundColor: CaregiverColors.lightGray,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          
          return Row(
            children: [
              // Sidebar - hide on mobile, show collapsed on tablet
              if (!isMobile)
                CaregiverSidebar(
                  isExpanded: !isTablet && _isSidebarExpanded,
                  selectedIndex: _selectedIndex,
                  onMenuItemTapped: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  onToggle: () {
                    setState(() {
                      _isSidebarExpanded = !_isSidebarExpanded;
                    });
                  },
                  caregiverName: caregiverName,
                ),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    CaregiverTopBar(
                      title: _getPageTitle(),
                      showSearch: _selectedIndex == 0,
                      onLogout: () async {
                        await _auth.signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      },
                    ),

                    // Page Content
                    Expanded(
                      child: _getSelectedPage(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Mobile drawer
      drawer: MediaQuery.of(context).size.width < 768
          ? Drawer(
              child: CaregiverSidebar(
                isExpanded: true,
                selectedIndex: _selectedIndex,
                onMenuItemTapped: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context);
                },
                onToggle: () {},
                caregiverName: caregiverName,
              ),
            )
          : null,
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Bookings';
      case 2:
        return 'Messages';
      case 3:
        return 'Availability';
      case 4:
        return 'My Profile';
      case 5:
        return 'Reviews';
      case 6:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(
          caregiverName: _caregiverData?['fullName'] ?? 'Caregiver',
        );
      case 1:
        return const BookingsPage();
      case 2:
        return const ChatListScreen();
      case 3:
        return const AvailabilityPage();
      case 4:
        return ProfilePage(caregiverData: _caregiverData);
      case 5:
        return const ReviewsPage();
      case 6:
        return const SettingsPage();
      default:
        return DashboardPage(
          caregiverName: _caregiverData?['fullName'] ?? 'Caregiver',
        );
    }
  }
}
