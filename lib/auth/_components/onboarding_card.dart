import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'step_indicator.dart';

// Types
enum Profession {
  twelfthStudent,
  diploma,
  graduate,
  workingProfessional,
}

extension ProfessionExtension on Profession {
  String get displayName {
    switch (this) {
      case Profession.twelfthStudent:
        return '12th Student';
      case Profession.diploma:
        return 'Diploma';
      case Profession.graduate:
        return 'Graduate';
      case Profession.workingProfessional:
        return 'Working professional';
    }
  }

  static Profession fromString(String value) {
    switch (value) {
      case '12th Student':
        return Profession.twelfthStudent;
      case 'Diploma':
        return Profession.diploma;
      case 'Graduate':
        return Profession.graduate;
      case 'Working professional':
        return Profession.workingProfessional;
      default:
        throw ArgumentError('Invalid profession: $value');
    }
  }
}

class FormData {
  String? name;
  String dob;
  String phone;
  String institution;
  Profession? profession;
  String? focus;

  FormData({
    this.name,
    this.dob = '',
    this.phone = '',
    this.institution = '',
    this.profession,
    this.focus,
  });

  FormData copyWith({
    String? name,
    String? dob,
    String? phone,
    String? institution,
    Profession? profession,
    String? focus,
  }) {
    return FormData(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      institution: institution ?? this.institution,
      profession: profession ?? this.profession,
      focus: focus ?? this.focus,
    );
  }
}

class OnBoardingCard extends StatefulWidget {
  const OnBoardingCard({super.key});

  @override
  State<OnBoardingCard> createState() => _OnBoardingCardState();
}

class _OnBoardingCardState extends State<OnBoardingCard> {
  int step = 1;
  bool busy = false;
  String emailInput = '';
  bool loading = false;
  bool isEmailProvider = false;

  late FormData data;

  final Map<Profession, List<String>> focusByProfession = {
    Profession.twelfthStudent: [
      "Crack competitive exams",
      "Choose Career paths",
      "Skill building",
      "Others",
    ],
    Profession.diploma: [
      "Job/Internship opportunities",
      "Career/ Path guidance",
      "Skill building",
      "Others",
    ],
    Profession.graduate: [
      "Job/Internship opportunities",
      "Career/ Path guidance",
      "Skill building",
      "Others",
    ],
    Profession.workingProfessional: [
      "Career growth",
      "Career/ Path guidance",
      "Skill building",
      "Others",
    ],
  };

  @override
  void initState() {
    super.initState();
    data = FormData();
    // Check if email provider (you might need to implement this based on your auth)
    // For now, assume false
  }

  List<String> get focusOptions {
    return data.profession != null ? focusByProfession[data.profession!]! : [];
  }

  bool get canProceed {
    if (busy) return false;
    switch (step) {
      case 1:
        return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data.dob) &&
               RegExp(r'^[0-9()+\-\s]{7,}$').hasMatch(data.phone.trim()) &&
               data.institution.trim().length >= 5;
      case 2:
        return data.profession != null;
      case 3:
        return data.focus != null && data.focus!.isNotEmpty;
      case 4:
        return true;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void nextStep() {
    if (step < 5 && canProceed) {
      setState(() => step++);
    }
  }

  void prevStep() {
    if (step > 1) {
      setState(() => step--);
    }
  }

  Future<void> finish() async {
    // Implement the finish logic similar to the TS version
    // This would update Supabase and navigate
    setState(() => loading = true);
    try {
      // Update user data in Supabase
      final updatePayload = {
        'userPhone': data.phone,
        'institutionName': data.institution.trim().toLowerCase(),
        'mainFocus': data.focus?.trim().toLowerCase(),
        'current_status': data.profession?.displayName.toLowerCase(),
        'is_verified': true,
      };

      if (data.name != null && data.name!.trim().isNotEmpty) {
        updatePayload['userName'] = data.name!.trim();
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update(updatePayload)
            .eq('id', user.id);
      }

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Let's personalize your journey",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete the steps to get tailored guidance for your goals.',
              style: GoogleFonts.raleway(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            // Step Indicator (you'll need to implement this)
            StepIndicator(current: step, onStepClick: (s) => setState(() => step = s)),
            const SizedBox(height: 32),

            // Step Content
            Expanded(
              child: _buildStepContent(),
            ),

            // Navigation Buttons
            const SizedBox(height: 24),
            Row(
              children: [
                if (step > 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: prevStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (step > 1) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: step == 5 ? finish : (canProceed ? nextStep : null),
                    child: loading
                        ? const CircularProgressIndicator()
                        : Text(step == 5 ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEmailProvider) ...[
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'e.g., John Doe',
            ),
            onChanged: (value) => setState(() => data = data.copyWith(name: value)),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            hintText: 'YYYY-MM-DD',
          ),
          onChanged: (value) => setState(() => data = data.copyWith(dob: value)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+91 90005 xxxxx',
          ),
          onChanged: (value) => setState(() => data = data.copyWith(phone: value)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Current school/college',
            hintText: 'e.g., Delhi Public School',
          ),
          onChanged: (value) => setState(() => data = data.copyWith(institution: value)),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure to write full name of your school Institution/school.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your current profession?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...Profession.values.map((profession) => RadioListTile<Profession>(
          title: Text(profession.displayName),
          value: profession,
          groupValue: data.profession,
          onChanged: (value) => setState(() => data = data.copyWith(profession: value)),
        )),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your main focus?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...focusOptions.map((focus) => RadioListTile<String>(
          title: Text(focus),
          value: focus,
          groupValue: data.focus,
          onChanged: (value) => setState(() => data = data.copyWith(focus: value)),
        )),
      ],
    );
  }

  Widget _buildStep4() {
    return const Center(
      child: Text('Step 4 - Additional setup if needed'),
    );
  }

  Widget _buildStep5() {
    return const Center(
      child: Text('Step 5 - Final confirmation'),
    );
  }
}