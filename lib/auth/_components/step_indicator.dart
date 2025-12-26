import 'package:flutter/material.dart';

class StepMeta {
  final int key;
  final String label;
  final IconData icon;

  const StepMeta({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class StepIndicator extends StatelessWidget {
  final int current;
  final Function(int)? onStepClick;

  const StepIndicator({
    super.key,
    required this.current,
    this.onStepClick,
  });

  static const List<StepMeta> steps = [
    StepMeta(key: 1, label: "Basics", icon: Icons.person),
    StepMeta(key: 2, label: "Profile", icon: Icons.school),
    StepMeta(key: 3, label: "Focus", icon: Icons.track_changes),
    StepMeta(key: 4, label: "Info", icon: Icons.volume_up),
    StepMeta(key: 5, label: "Invite", icon: Icons.people),
  ];

  @override
  Widget build(BuildContext context) {
    final progressPct = ((current - 1) / (steps.length - 1)) * 100;

    return Semantics(
      label: 'Onboarding progress',
      child: Column(
        children: [
          // Progress bar
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: 4,
                  width: MediaQuery.of(context).size.width * (progressPct / 100),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: steps.map((step) {
              final isCompleted = step.key < current;
              final isActive = step.key == current;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step button
                  GestureDetector(
                    onTap: () {
                      if (onStepClick != null && step.key <= current) {
                        onStepClick!(step.key);
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green[200]!
                              : isActive
                                  ? Colors.blue[600]!
                                  : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isCompleted
                            ? Colors.green[50]
                            : isActive
                                ? Colors.blue[600]
                                : Colors.white,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        size: 16,
                        color: isCompleted
                            ? Colors.green[700]
                            : isActive
                                ? Colors.white
                                : Colors.grey[600],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Step label
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.blue[700] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}