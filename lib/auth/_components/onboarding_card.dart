import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'step_indicator.dart';

// Types
enum Profession { twelfthStudent, diploma, graduate, workingProfessional }

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
  String? referralSource;

  FormData({
    this.name,
    this.dob = '',
    this.phone = '',
    this.institution = '',
    this.profession,
    this.focus,
    this.referralSource,
  });

  FormData copyWith({
    String? name,
    String? dob,
    String? phone,
    String? institution,
    Profession? profession,
    String? focus,
    String? referralSource,
  }) {
    return FormData(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      phone: phone ?? this.phone,
      institution: institution ?? this.institution,
      profession: profession ?? this.profession,
      focus: focus ?? this.focus,
      referralSource: referralSource ?? this.referralSource,
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
  String? referralLink;

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
    _generateReferralLink();
    // Check if user signed up with email/password
    final user = Supabase.instance.client.auth.currentUser;
    isEmailProvider = user?.appMetadata['provider'] == 'email' || true;
  }

  void _generateReferralLink() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Generate unique referral code
      final random = Random();
      final code =
          user.id.substring(0, 8) +
          random.nextInt(9999).toString().padLeft(4, '0');
      setState(() {
        referralLink = 'https://clario.app/invite/$code';
      });
    }
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
    setState(() => loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final userName = data.name?.trim() ?? user.email?.split('@')[0] ?? 'User';

      // Save to users table (matching your schema)
      final userData = {
        'id': user.id,
        'userName': userName,
        'userEmail': user.email,
        'userPhone': data.phone.trim(),
        'institutionName': data.institution.trim(),
        'current_status': data.profession?.displayName,
        'mainFocus': data.focus?.trim(),
        'invite_link': referralLink,
        'totalCredits': 100,
        'remainingCredits': 100,
        'is_verified': false,
        'isQuizDone': false,
        'isPro': false,
      };

      await Supabase.instance.client.from('users').upsert(userData);

      // Navigate to home
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      margin: EdgeInsets.all(isMobile ? 8 : 16),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Let's personalize your journey",
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete the steps to get tailored guidance for your goals.',
                style: GoogleFonts.raleway(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Step Indicator
              StepIndicator(
                current: step,
                onStepClick: (s) => setState(() => step = s),
              ),
              const SizedBox(height: 32),

              // Step Content
              _buildStepContent(),

              // Navigation Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step indicator text
                  Text(
                    'Step $step of 5',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  // Buttons
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (step > 1)
                          TextButton.icon(
                            onPressed: prevStep,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        if (step > 1) const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: step == 5
                                ? finish
                                : (canProceed ? nextStep : null),
                            icon: loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    step == 5
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    size: 18,
                                  ),
                            label: Text(
                              step == 5 ? 'Complete Setup' : 'Continue',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E9EF5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            onChanged: (value) =>
                setState(() => data = data.copyWith(name: value)),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            hintText: 'YYYY-MM-DD',
          ),
          onChanged: (value) =>
              setState(() => data = data.copyWith(dob: value)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+91 90005 xxxxx',
          ),
          onChanged: (value) =>
              setState(() => data = data.copyWith(phone: value)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Current school/college',
            hintText: 'e.g., Delhi Public School',
          ),
          onChanged: (value) =>
              setState(() => data = data.copyWith(institution: value)),
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
          'What best describes you Currently?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Profession>(
          decoration: InputDecoration(
            hintText: 'Select your current status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          value: data.profession,
          items: Profession.values.map((profession) {
            return DropdownMenuItem<Profession>(
              value: profession,
              child: Row(
                children: [
                  if (profession == Profession.twelfthStudent)
                    const Icon(Icons.star, color: Color(0xFF5E9EF5), size: 18),
                  if (profession == Profession.twelfthStudent)
                    const SizedBox(width: 8),
                  Text(profession.displayName),
                  if (profession == Profession.twelfthStudent)
                    const SizedBox(width: 8),
                  if (profession == Profession.twelfthStudent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E9EF5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          color: Color(0xFF5E9EF5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) =>
              setState(() => data = data.copyWith(profession: value)),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Based on your profile, what\'s your main focus right now?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: focusOptions.map((focus) {
            final isSelected = data.focus == focus;
            return InkWell(
              onTap: () => setState(() => data = data.copyWith(focus: focus)),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5E9EF5).withValues(alpha: 0.1)
                      : Colors.grey[50],
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5E9EF5)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  focus,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF5E9EF5)
                        : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where did you find Reskill?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us how you found out about Reskill',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            hintText: 'Eg: blogs...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) =>
              setState(() => data = data.copyWith(referralSource: value)),
        ),
        const SizedBox(height: 16),
        Text(
          'Note: This step is optional and can be skipped.',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invite by email',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'friend@example.com',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => emailInput = value),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                if (emailInput.isNotEmpty && emailInput.contains('@')) {
                  // TODO: Send invite email
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invite sent to $emailInput')),
                  );
                  setState(() => emailInput = '');
                }
              },
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E9EF5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Or share a referral link',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              // Mobile: Stack vertically
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            referralLink ?? 'Generating...',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (referralLink != null) {
                              Clipboard.setData(
                                ClipboardData(text: referralLink!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Referral link copied!'),
                                ),
                              );
                            }
                          },
                          tooltip: 'Copy referral link',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (referralLink != null) {
                          Clipboard.setData(ClipboardData(text: referralLink!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Link copied! Share it with friends',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E9EF5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Desktop: Row layout
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              referralLink ?? 'Generating...',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              if (referralLink != null) {
                                Clipboard.setData(
                                  ClipboardData(text: referralLink!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Referral link copied!'),
                                  ),
                                );
                              }
                            },
                            tooltip: 'Copy referral link',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (referralLink != null) {
                        Clipboard.setData(ClipboardData(text: referralLink!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link copied! Share it with friends'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E9EF5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Friends who join with your link may unlock bonus resources for you.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
