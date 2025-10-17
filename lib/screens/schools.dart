import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance/utils/colors.dart';
import 'package:attendance/controllers/school.controller.dart';
import 'package:attendance/controllers/sms.controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/school.model.dart';
import '../routes/routes.names.dart';
import '../utils/reference.key.dart';

class SchoolManagement extends StatefulWidget {
  const SchoolManagement({super.key});

  @override
  State<SchoolManagement> createState() => _SchoolManagementState();
}

class _SchoolManagementState extends State<SchoolManagement>
    with SingleTickerProviderStateMixin {
  final SchoolController _schoolController = Get.put(SchoolController());
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation after initial loading
    _schoolController.isInitialLoading.listen((isLoading) {
      if (!isLoading) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to logout?',
              style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface))),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Get.toNamed(splash);
                }
              },
              child: Text('Logout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  void _showAddEditSchoolBottomSheet({SchoolData? school}) {
    final TextEditingController nameController =
        TextEditingController(text: school?.name ?? '');
    final TextEditingController addressController =
        TextEditingController(text: school?.email ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: school?.phone ?? '');
    final TextEditingController emailController =
        TextEditingController(text: school?.email ?? '');
    final TextEditingController websiteController =
        TextEditingController(text: school?.slogan ?? '');
    final TextEditingController principalController =
        TextEditingController(text: school?.logo ?? '');
    final RxString logoUrl = (school?.logo ?? '').obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      school == null ? 'Add New School' : 'Edit School',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: whiteColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school == null
                          ? 'Fill in the school details below'
                          : 'Update the school information',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: whiteColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          label: 'School Name *',
                          icon: Icons.school,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: websiteController,
                          label: 'Slogan',
                          icon: Icons.web,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 24),
                        Obx(() => _schoolController.isLoading.value
                            ? Center(
                                child: SpinKitDoubleBounce(
                                    color: primaryColor, size: 40.0))
                            : _buildSubmitButton(
                                context,
                                school,
                                nameController,
                                addressController,
                                phoneController,
                                emailController,
                                websiteController,
                                principalController,
                              )),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: greyColor1),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: blackColor),
      validator: isRequired
          ? (value) => value?.isEmpty ?? true ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    SchoolData? school,
    TextEditingController nameController,
    TextEditingController addressController,
    TextEditingController phoneController,
    TextEditingController emailController,
    TextEditingController websiteController,
    TextEditingController principalController,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      onPressed: () async {
        if (nameController.text.trim().isEmpty) {
          Get.snackbar(
            'Error',
            'School name is required',
            backgroundColor: Colors.red,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }

        final schoolData = SchoolData(
          id: school?.id,
          name: nameController.text.trim(),
          email: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          phone: phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
          slogan: websiteController.text.trim().isEmpty
              ? null
              : websiteController.text.trim(),
          logo:
              "https://t3.ftcdn.net/jpg/02/67/87/74/360_F_267877423_zFJTSVjvOX8zsFvx8tMLMTkukaBxsx3h.jpg",
          status: 'ACTIVE',
        );

        bool success;
        if (school == null) {
          success = await _schoolController.createSchool(schoolData);
        } else {
          success = await _schoolController.updateSchool(schoolData);
        }

        if (success) {
          Navigator.pop(context);
          Get.snackbar(
            'Success',
            school == null
                ? 'School added successfully'
                : 'School updated successfully',
            backgroundColor: Colors.green,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
        } else {
          Get.snackbar(
            'Error',
            _schoolController.errorMessage.value,
            backgroundColor: Colors.red,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      child: Text(
        school == null ? 'Add School' : 'Update School',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(SchoolData school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete School',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: blackColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${school.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: greyColor1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: greyColor1,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await _schoolController.deleteSchool(school.id!);
              if (success) {
                Get.snackbar(
                  'Success',
                  'School deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: whiteColor,
                  snackPosition: SnackPosition.TOP,
                );
              } else {
                Get.snackbar(
                  'Error',
                  _schoolController.errorMessage.value,
                  backgroundColor: Colors.red,
                  colorText: whiteColor,
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(SchoolData school) {
    return InkWell(
      onTap: () {
        SchoolInfoBottomSheet.show(context, school);
      }, child: Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [whiteColor, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: greyColor1.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        school.logo != null && school.logo!.isNotEmpty
                            ? school.logo!
                            : 'https://t3.ftcdn.net/jpg/02/67/87/74/360_F_267877423_zFJTSVjvOX8zsFvx8tMLMTkukaBxsx3h.jpg',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.school,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school.name!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (school.slogan != null && school.slogan!.isNotEmpty)
                          Text(
                            school.slogan!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: greyColor1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showAddEditSchoolBottomSheet(school: school);
                          break;
                        case 'delete':
                          _showDeleteConfirmationDialog(school);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit,
                                size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: blackColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      color: greyColor1,
                    ),
                  ),
                ],
              ),
              if (school.phone != null || school.email != null)
                const SizedBox(height: 12),
              if (school.phone != null && school.phone!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: greyColor1),
                    const SizedBox(width: 8),
                    Text(
                      school.phone!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: greyColor1,
                      ),
                    ),
                  ],
                ),
              if (school.email != null && school.email!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: greyColor1),
                    const SizedBox(width: 8),
                    Text(
                      school.email!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: greyColor1,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Management',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: whiteColor,
              ),
            ),
            Obx(() => Text(
                  'Total schools: ${_schoolController.schools.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: whiteColor.withOpacity(0.8),
                  ),
                )),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: whiteColor, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: whiteColor),
              onPressed: () => _schoolController.refreshSchools(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 24),
              onPressed: () => _handleLogout(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSchoolBottomSheet(),
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        icon: const Icon(Icons.add),
        label: Text(
          'Add School',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Obx(() => _schoolController.isInitialLoading.value
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitDoubleBounce(color: primaryColor, size: 50.0),
                  const SizedBox(height: 20),
                  Text(
                    'Loading schools...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _schoolController.refreshSchools,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: greyColor1.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search schools...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: greyColor1,
                                ),
                                prefixIcon:
                                    const Icon(Icons.search, color: greyColor1),
                                suffixIcon: Obx(() => _schoolController
                                        .searchQuery.value.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: greyColor1),
                                        onPressed: () {
                                          _searchController.clear();
                                          _schoolController.clearSearch();
                                        },
                                      )
                                    : const SizedBox.shrink()),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: blackColor,
                              ),
                              onChanged: _schoolController.searchSchools,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Schools List
                          Text(
                            'Schools',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Obx(() {
                            final filteredSchools =
                                _schoolController.filteredSchools;

                            if (_schoolController.isLoading.value &&
                                !_schoolController.isInitialLoading.value) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: SpinKitDoubleBounce(
                                      color: primaryColor, size: 40.0),
                                ),
                              );
                            } else if (filteredSchools.isNotEmpty) {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredSchools.length,
                                itemBuilder: (context, index) {
                                  final school = filteredSchools[index];
                                  return _buildSchoolCard(school);
                                },
                              );
                            } else if (_schoolController
                                .searchQuery.value.isNotEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: greyColor1, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: const Icon(Icons.search_off,
                                          size: 48, color: greyColor1),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No schools found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: blackColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search terms',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: greyColor1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: greyColor1, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: const Icon(Icons.school,
                                          size: 48, color: greyColor1),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No schools found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: blackColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add your first school to get started',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: greyColor1,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAddEditSchoolBottomSheet(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: whiteColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: Text(
                                        'Add School',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }),

                          // Add some bottom padding to account for FAB
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )),
    );
  }
}


class SchoolInfoBottomSheet {
  static void show(BuildContext context, SchoolData school) {
    final SMSController smsController = Get.put(SMSController());
    smsController.schoolId = school.id ?? '';
    smsController.getSMSBalance();
    smsController.getSMSHistory();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              school.logo != null && school.logo!.isNotEmpty
                                  ? school.logo!
                                  : 'https://t3.ftcdn.net/jpg/02/67/87/74/360_F_267877423_zFJTSVjvOX8zsFvx8tMLMTkukaBxsx3h.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.school,
                                      color: primaryColor,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                school.name ?? 'School Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: whiteColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (school.slogan != null && school.slogan!.isNotEmpty)
                                Text(
                                  school.slogan!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: whiteColor.withOpacity(0.9),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SMS Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.blue.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SMS Balance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: blackColor,
                                    ),
                                  ),
                                  Icon(
                                    Icons.sms,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Obx(() => smsController.isLoading.value
                                  ? Center(
                                      child: SpinKitThreeBounce(
                                        color: primaryColor,
                                        size: 20.0,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${smsController.smsBalance.value.toStringAsFixed(0)} SMS',
                                              style: GoogleFonts.poppins(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.green,
                                              ),
                                            ),
                                            Text(
                                              'Credits available',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: greyColor1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _showTopUpDialog(context, smsController),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: whiteColor,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: Text(
                                            'Top Up',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                              if (smsController.errorMessage.value.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    smsController.errorMessage.value,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // School Information Section
                        Text(
                          'School Information',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInfoCard(
                          icon: Icons.business,
                          title: 'School Name',
                          value: school.name ?? 'Not provided',
                          color: Colors.blue,
                        ),
                        
                        if (school.email != null && school.email!.isNotEmpty)
                          _buildInfoCard(
                            icon: Icons.email,
                            title: 'Email',
                            value: school.email!,
                            color: Colors.orange,
                          ),
                        
                        if (school.phone != null && school.phone!.isNotEmpty)
                          _buildInfoCard(
                            icon: Icons.phone,
                            title: 'Phone',
                            value: school.phone!,
                            color: Colors.green,
                          ),
                        
                        if (school.slogan != null && school.slogan!.isNotEmpty)
                          _buildInfoCard(
                            icon: Icons.format_quote,
                            title: 'Slogan',
                            value: school.slogan!,
                            color: Colors.purple,
                          ),
                        
                        _buildInfoCard(
                          icon: Icons.check_circle,
                          title: 'Status',
                          value: school.status ?? 'ACTIVE',
                          color: school.status == 'ACTIVE' ? Colors.green : Colors.red,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Recent SMS History
                        Text(
                          'Recent SMS Activity',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Obx(() => smsController.smsHistory.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: greyColor1.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 48,
                                      color: greyColor1,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No SMS activity yet',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: blackColor,
                                      ),
                                    ),
                                    Text(
                                      'SMS transactions will appear here',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: greyColor1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: smsController.smsHistory.length > 5 
                                    ? 5 
                                    : smsController.smsHistory.length,
                                itemBuilder: (context, index) {
                                  final transaction = smsController.smsHistory[index];
                                  return _buildTransactionCard(transaction);
                                },
                              )),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showBulkSMSDialog(context, smsController),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: whiteColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.send, size: 20),
                                label: Text(
                                  'Send SMS',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  smsController.getSMSBalance();
                                  smsController.getSMSHistory();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh, size: 20),
                                label: Text(
                                  'Refresh',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: greyColor1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTransactionCard(dynamic transaction) {
      final isCredit = transaction.amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'SMS Transaction',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(Get.context!).colorScheme.onSurface),
                ),
                Text(
                  transaction.createdAt?.toString() ?? 'Unknown date',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(Get.context!).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${transaction.amount.toStringAsFixed(0)} Credits',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCredit ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }
  
  static void _showTopUpDialog(BuildContext context, SMSController smsController) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController referenceController = TextEditingController();
    // Auto-generate reference code
  final autoReference = ReferenceCodeGenerator.generateBankStyleReference(
    sequentialNumber: 1234567890,
  );
  referenceController.text = autoReference;
    String selectedMethod = 'Mobile Money';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Top Up SMS Balance',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: blackColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (SMS Credits)',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              decoration: InputDecoration(
                labelText: 'Payment Reference',
                prefixIcon: const Icon(Icons.receipt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: greyColor1),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: whiteColor,
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && referenceController.text.isNotEmpty) {
                Navigator.pop(context);
                await smsController.topUpSMS(
                  amount: amount,
                  paymentMethod: selectedMethod,
                  paymentReference: referenceController.text,
                );
              }
            },
            child: Text(
              'Top Up',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }


  static void _showBulkSMSDialog(BuildContext context, SMSController smsController) {
    final TextEditingController messageController = TextEditingController();
    final TextEditingController recipientsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Bulk SMS',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: blackColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: recipientsController,
              decoration: InputDecoration(
                labelText: 'Recipients (comma separated)',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                prefixIcon: const Icon(Icons.message),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: greyColor1),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: whiteColor,
            ),
            onPressed: () async {
              if (messageController.text.isNotEmpty && recipientsController.text.isNotEmpty) {
                final recipients = recipientsController.text.split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                
                Navigator.pop(context);
                await smsController.sendBulkSMS(recipients, messageController.text);
              }
            },
            child: Text(
              'Send SMS',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}