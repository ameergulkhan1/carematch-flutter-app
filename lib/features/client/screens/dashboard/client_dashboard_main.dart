import 'package:flutter/material.dart';
import 'client_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'pages/dashboard_home_page.dart';
import '../search_caregivers_screen.dart';
import '../client_bookings_screen.dart';
import '../saved_caregivers_screen.dart';
import '../client_profile_screen.dart';
import '../client_billing_screen.dart';
import '../client_reviews_screen.dart';
import '../client_incidents_screen.dart';
import '../../../chat/screens/chat_list_screen.dart';
import '../../../../shared/utils/responsive_utils.dart';

class ClientDashboardMain extends StatefulWidget {
  const ClientDashboardMain({super.key});

  @override
  State<ClientDashboardMain> createState() => _ClientDashboardMainState();
}

class _ClientDashboardMainState extends State<ClientDashboardMain> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-collapse sidebar on tablet
    if (ResponsiveUtils.shouldAutoCollapseSidebar(context)) {
      _isSidebarExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ClientColors.background,
      // Mobile drawer
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Builder(
        builder: (context) {
          return Row(
            children: [
              // Desktop/Tablet Sidebar
              if (!isMobile)
                ClientSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  isExpanded: _isSidebarExpanded,
                  onToggle: () {
                    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                  },
                ),

              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Top bar
                    ClientTopBar(
                      title: _getPageTitle(),
                      showSearch: _selectedIndex == 1,
                      onMenuTap: isMobile
                          ? () {
                              Scaffold.of(context).openDrawer();
                            }
                          : null,
                    ),

                    // Page content
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
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ClientSidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop(); // Close drawer
        },
        isExpanded: true,
        onToggle: () {
          Navigator.of(context).pop(); // Close drawer
        },
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Find Caregivers';
      case 2:
        return 'My Bookings';
      case 3:
        return 'Favorites';
      case 4:
        return 'Messages';
      case 5:
        return 'My Reviews';
      case 6:
        return 'Incidents';
      case 7:
        return 'Billing';
      case 8:
        return 'Profile';
      case 9:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHomePage();
      case 1:
        return const SearchCaregiversScreen();
      case 2:
        return const ClientBookingsScreen();
      case 3:
        return const SavedCaregiversScreen();
      case 4:
        return const ChatListScreen();
      case 5:
        return const ClientReviewsScreen();
      case 6:
        return const ClientIncidentsScreen();
      case 7:
        return const ClientBillingScreen();
      case 8:
        return const ClientProfileScreen();
      case 9:
        return const Center(
          child: Text('Settings - Coming Soon'),
        );
      default:
        return const DashboardHomePage();
    }
  }
}
