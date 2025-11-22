import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_constants.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import 'profile_screen.dart';
import 'results_screen.dart';
import 'plans_screen.dart';
import 'my_plans_screen.dart';
import 'premium_request_screen.dart';
import 'otp_login_screen.dart';

class HomeScreen extends StatefulWidget {
  final StudentModel currentStudent;
  final String batch;

  const HomeScreen({
    super.key,
    required this.currentStudent,
    required this.batch,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  String? _selectedSection;
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fetchStudents();
    _searchController.addListener(_filterStudents);
    
    // Check for updates after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        UpdateService().checkForUpdates(context);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/data/students'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final students = (data['data'] as List)
              .map((json) => StudentModel.fromJson(json))
              .toList();
          
          // Extract unique sections
          final sections = students
              .map((s) => s.studentSection?.toUpperCase())
              .where((s) => s != null && s.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
          sections.sort();
          
          setState(() {
            _students = students;
            _filteredStudents = students;
            _sections = ['All', ...sections];
            _selectedSection = 'All';
            _isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load students';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load students';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      var filtered = _students;
      
      // Apply section filter
      if (_selectedSection != null && _selectedSection != 'All') {
        filtered = filtered.where((student) {
          return student.studentSection?.toUpperCase() == _selectedSection;
        }).toList();
      }
      
      // Apply search filter
      if (query.isEmpty) {
        _filteredStudents = filtered;
      } else {
        _filteredStudents = filtered.where((student) {
          return student.studentName.toLowerCase().contains(query) ||
              student.rollNo.toLowerCase().contains(query) ||
              student.branch.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _logout() async {
    try {
      final apiService = ApiService();
      await apiService.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OtpLoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFFAFAFA),
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B00), Color(0xFFFF8F3D)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: ApiConstants.getStudentPhotoUrl(widget.currentStudent.rollNo),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white,
                          child: const Icon(Icons.person, size: 40, color: Color(0xFFFF6B00)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white,
                          child: const Icon(Icons.person, size: 40, color: Color(0xFFFF6B00)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.currentStudent.studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentStudent.rollNo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            student: widget.currentStudent,
                            batch: widget.batch,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.assessment_outlined,
                    title: 'My Results',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultsScreen(
                            student: widget.currentStudent,
                            batch: widget.batch,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.card_membership,
                    title: 'My Plans',
                    textColor: const Color(0xFFFF6B00),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPlansScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.workspace_premium,
                    title: 'Buy Plans',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlansScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.support_agent,
                    title: 'Premium Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PremiumRequestScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About JF Foundation',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('About JF Foundation'),
                          content: const Text(
                            'JECRC Foundation (JF) is committed to providing quality education and fostering excellence in technical and professional studies.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Logout at bottom
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF3B30),
                  size: 24,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'JF App v1.0.0',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? const Color(0xFF000000),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? const Color(0xFF000000),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildStudentCard(StudentModel student, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  student: student,
                  batch: widget.batch,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo with better visibility
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: ApiConstants.getStudentPhotoUrl(student.rollNo),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[200]!,
                              Colors.grey[300]!,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFF6B00).withValues(alpha: 0.1),
                              const Color(0xFFFF8F3D).withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 70,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Details with View Results button
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          student.studentName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF000000),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              student.rollNo,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B00), Color(0xFFFF8F3D)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      student.branch,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultsScreen(
                                  student: student,
                                  batch: widget.batch,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000000),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assessment_outlined, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'View Results',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        drawer: _buildDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B00), Color(0xFFFF8F3D)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Menu Button with better touch
                            Builder(
                              builder: (context) => Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.menu_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'JF Students',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 26,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Batch ${widget.batch}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // My Profile Button
                            IconButton(
                              icon: const Icon(Icons.person, color: Colors.white, size: 26),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(
                                      student: widget.currentStudent,
                                      batch: widget.batch,
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'My Profile',
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, roll number, branch...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B00)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                  const SizedBox(height: 12),
            // Section Filter
            if (!_isLoading && _errorMessage == null && _sections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFFFF6B00),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Section:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedSection,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B00)),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF000000),
                          ),
                          items: _sections.map((section) {
                            return DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSection = value;
                              _filterStudents();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Students Count
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredStudents.length} Students',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF000000),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Students Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchStudents,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredStudents.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No students found',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                return _buildStudentCard(_filteredStudents[index], index);
                              },
                            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
