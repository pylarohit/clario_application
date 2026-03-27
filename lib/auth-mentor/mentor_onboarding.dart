import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mentor/dashboard.dart';

class MentorOnboardingPage extends StatefulWidget {
  const MentorOnboardingPage({super.key});

  @override
  State<MentorOnboardingPage> createState() => _MentorOnboardingPageState();
}

class _MentorOnboardingPageState extends State<MentorOnboardingPage> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  bool _isSaving = false;

  // Step 1 Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Step 2 Data
  String? _selectedOccupation;
  final List<String> _occupations = [
    'Teacher', 'College Professor', 'Tutor', 'Academic Researcher', 'Software Engineer',
    'Business Analyst', 'AI Engineer', 'Product Manager', 'Marketing Specialist',
    'HR Professional', 'Finance / Accountant', 'Startup Founder', 'JEE / NEET Mentor',
    'UPSC / Govt Exam Mentor', 'Competitive Exam Coach', 'Entrepreneur', 'Career Coach',
    'DevOps Engineer', 'Cybersecurity Specialist', 'Tech Consultant', 'MBBS Doctor',
    'Nursing Professional'
  ];

  // Step 3 Data
  final List<String> _expertiseAreas = [
    'Career Guidance', 'Skill Building', 'Job Placement', 'Higher Studies',
    'Technical Interviews', 'Resume Review', 'Entrepreneurship', 'Industry Insights',
    'Programming', 'Data Science', 'Design Thinking'
  ];
  final List<String> _selectedExpertise = [];

  Future<void> _nextStep() async {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      await _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No authenticated user found.')));
      return;
    }

    if (_nameController.text.isEmpty || _selectedOccupation == null || _selectedExpertise.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all required fields.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Save Mentor Profile to public.mentors
      await Supabase.instance.client.from('mentors').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': _nameController.text,
        'phone': _phoneController.text,
        'bio': _bioController.text,
        'current_position': _selectedOccupation,
        'expertise': _selectedExpertise,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully! Welcome aboard.')),
        );
        
        // Final transition to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MentorDashboard()),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF), // Soft lavender background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Sparkle Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome! Lets get started by completing your profile',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.show_chart_rounded, color: Colors.black87, size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Step Info & Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $_currentStep of $_totalSteps',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        '${((_currentStep / _totalSteps) * 100).toInt()}%',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _currentStep / _totalSteps,
                      backgroundColor: Colors.grey[100],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)), // Bright Blue
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dynamic Content based on Step
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),

                  const SizedBox(height: 40),

                  // Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      OutlinedButton(
                        onPressed: _currentStep > 1 ? _prevStep : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          side: BorderSide(color: Colors.grey[200]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                      ),

                      // Next / Save Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BA9FF), // Lighter Blue per photo
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentStep == _totalSteps ? 'Save' : 'Next',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full name'),
        _buildTextField(_nameController, hint: 'e.g., Priya Sharma'),
        const SizedBox(height: 20),
        _buildLabel('Phone'),
        _buildTextField(_phoneController, hint: '+91 98765 43210', keyboardType: TextInputType.phone),
        const SizedBox(height: 24),
        _buildLabel('Short bio'),
        _buildTextField(_bioController, hint: 'Tell students about your experience and how you can help.', maxLines: 4),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your current occupation',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select an occupation', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
              value: _selectedOccupation,
              items: _occupations.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedOccupation = val),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the role that best matches your current position.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose expertise areas where you can help students.',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _expertiseAreas.map((area) {
            final isSelected = _selectedExpertise.contains(area);
            return FilterChip(
              label: Text(area, style: GoogleFonts.inter(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedExpertise.length < 3) _selectedExpertise.add(area);
                  } else {
                    _selectedExpertise.remove(area);
                  }
                });
              },
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Select up to 1 to 3 options.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required String hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }
}
