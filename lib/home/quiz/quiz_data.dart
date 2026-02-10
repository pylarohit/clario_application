import 'package:flutter/foundation.dart';

// Quiz Data Structure
class QuizQuestion {
  final String question;
  final List<String>? options;

  QuizQuestion({
    required this.question,
    this.options,
  });
}

class QuizData {
  static Map<String, dynamic> getQuizData() {
    return {
      "12th student": {
        "choose career paths": {
          "focus_specific": [
            QuizQuestion(
              question: "Which stream are you in?",
              options: ["Medical", "Science", "Commerce", "Arts"],
            ),
            QuizQuestion(
              question: "How confident are you in your chosen stream?",
              options: ["Very confident", "Neutral", "Unsure"],
            ),
            QuizQuestion(
              question: "Why did you choose this stream?",
              options: [
                "Passion",
                "High salary",
                "Social impact",
                "Family influence"
              ],
            ),
            QuizQuestion(
              question:
                  "Along with your stream, what additional skill/interest would you like to build?",
              options: [
                "Technical",
                "Creative",
                "Sports",
                "Entrepreneurship",
                "Others"
              ],
            ),
            QuizQuestion(
              question:
                  "Which type of College do you prefer or are you open to?",
              options: ["Government", "Private", "Any"],
            ),
          ],
          "deep_understanding": [
            QuizQuestion(
              question:
                  "Tell us about your interests and hobbies outside academics.",
            ),
            QuizQuestion(
              question:
                  "What is your biggest confusion about choosing a career path?",
              options: [
                "Finding my strengths",
                "Future growth",
                "Too many choices",
                "Family pressure",
                "Lack of guidance"
              ],
            ),
            QuizQuestion(
              question: "What matters most to you in a career?",
              options: [
                "Job security",
                "High income",
                "Work-life balance",
                "Passion"
              ],
            ),
            QuizQuestion(
              question: "Which type of activities excite you the most?",
              options: [
                "Problem-solving tasks",
                "Creative projects",
                "Helping people",
                "Leadership roles",
                "Making a difference"
              ],
            ),
            QuizQuestion(
              question: "What motivates you the most to work hard?",
              options: [
                "Personal growth",
                "Earning money",
                "Recognition/Respect",
                "Making a difference in society"
              ],
            ),
          ],
        },
        "skill building": {
          "focus_specific": [
            QuizQuestion(
              question: "Which stream are you in?",
              options: ["Medical", "Science", "Commerce", "Arts"],
            ),
            QuizQuestion(
              question: "Which skills are you most interested in building?",
              options: [
                "Technical",
                "Communication",
                "Creative",
                "Leadership",
                "Entrepreneurship"
              ],
            ),
            QuizQuestion(
              question: "Why do you want to build this skill?",
              options: [
                "Career growth",
                "Personal interest",
                "Academic requirement"
              ],
            ),
            QuizQuestion(
              question:
                  "How much time per week can you dedicate to skill-building?",
            ),
          ],
          "learning_style": [
            QuizQuestion(
              question: "Do you learn skills better through practice or theory?",
              options: ["Practice", "Theory", "Both"],
            ),
            QuizQuestion(
              question:
                  "What type of projects/tasks excite you the most while learning?",
            ),
          ],
          "deep_understanding": [
            QuizQuestion(
              question:
                  "Which skills do you feel are most important for your future career?",
            ),
            QuizQuestion(
              question:
                  "What's stopping you right now from improving these skills?",
              options: ["Time", "Resources", "Motivation"],
            ),
          ],
        },
        "crack competitive exams": {
          "focus_specific": [
            QuizQuestion(
              question: "Which stream are you in?",
              options: ["Medical", "Science", "Commerce", "Arts"],
            ),
            QuizQuestion(
              question: "How confident are you in your chosen stream?",
              options: ["Very confident", "Neutral", "Unsure"],
            ),
            QuizQuestion(
              question: "Why did you choose this stream?",
              options: [
                "Passion",
                "High salary",
                "Social impact",
                "Family influence"
              ],
            ),
            QuizQuestion(
              question:
                  "Along with your stream, what additional skill/interest would you like to build?",
              options: [
                "Technical",
                "Creative",
                "Sports",
                "Entrepreneurship",
                "Others"
              ],
            ),
            QuizQuestion(
              question:
                  "Which type of College do you prefer or are you open to?",
              options: ["Government", "Private", "Any"],
            ),
          ],
          "deep_understanding": [
            QuizQuestion(
              question:
                  "Tell us about your interests and hobbies outside academics.",
            ),
            QuizQuestion(
              question:
                  "What is your biggest confusion about choosing a career path?",
              options: [
                "Finding my strengths",
                "Future growth",
                "Too many choices",
                "Family pressure",
                "Lack of guidance"
              ],
            ),
            QuizQuestion(
              question: "What matters most to you in a career?",
              options: [
                "Job security",
                "High income",
                "Work-life balance",
                "Passion"
              ],
            ),
            QuizQuestion(
              question: "Which type of activities excite you the most?",
              options: [
                "Problem-solving tasks",
                "Creative projects",
                "Helping people",
                "Leadership roles",
                "Making a difference"
              ],
            ),
            QuizQuestion(
              question: "What motivates you the most to work hard?",
              options: [
                "Personal growth",
                "Earning money",
                "Recognition/Respect",
                "Making a difference in society"
              ],
            ),
          ],
        },
      },
      "graduate": {
        "choose career paths": {
          "focus_specific": [
            QuizQuestion(
              question: "What is your degree specialization?",
              options: [
                "Engineering",
                "Management",
                "Arts",
                "Science",
                "Commerce",
                "Medical"
              ],
            ),
            QuizQuestion(
              question: "Have you completed your degree or are you pursuing it?",
              options: ["Completed", "Pursuing"],
            ),
            QuizQuestion(
              question: "What are your immediate career goals?",
              options: [
                "Job in my field",
                "Higher studies",
                "Switch fields",
                "Entrepreneurship"
              ],
            ),
            QuizQuestion(
              question: "What matters most in choosing a career path?",
              options: [
                "Salary",
                "Work-life balance",
                "Growth opportunities",
                "Passion"
              ],
            ),
          ],
          "deep_understanding": [
            QuizQuestion(
              question: "Why do you want to pursue this career?",
            ),
            QuizQuestion(
              question: "What is your biggest career-related concern?",
              options: [
                "Lack of opportunities",
                "Salary expectations",
                "Work-life balance",
                "Skills mismatch"
              ],
            ),
            QuizQuestion(
              question: "What motivates you the most?",
              options: [
                "Financial independence",
                "Impact on society",
                "Recognition",
                "Personal growth"
              ],
            ),
          ],
        },
        "skill building": {
          "focus_specific": [
            QuizQuestion(
              question: "What is your current skill level?",
              options: ["Beginner", "Intermediate", "Advanced"],
            ),
            QuizQuestion(
              question: "Which skills do you want to build?",
              options: [
                "Technical skills",
                "Soft skills",
                "Domain knowledge",
                "Leadership"
              ],
            ),
            QuizQuestion(
              question: "Why do you want to build this skill?",
              options: [
                "Career growth",
                "Job requirement",
                "Personal interest",
                "Entrepreneurship"
              ],
            ),
          ],
          "learning_style": [
            QuizQuestion(
              question: "How do you prefer to learn?",
              options: ["Online courses", "Workshops", "Self-study", "Mentorship"],
            ),
            QuizQuestion(
              question: "How much time can you dedicate weekly?",
            ),
          ],
          "deep_understanding": [
            QuizQuestion(
              question:
                  "What is your biggest confusion about choosing a career?",
            ),
            QuizQuestion(
              question: "What matters most to you in a future career?",
              options: [
                "Job security",
                "Passion",
                "Work-life balance",
                "High income"
              ],
            ),
          ],
        },
      },
    };
  }

  static List<Map<String, dynamic>> getFlattenedQuestions(
    String currentStatus,
    String mainFocus,
  ) {
    final data = getQuizData();
    
    // Debug logging
    debugPrint('Quiz Data - Looking for:');
    debugPrint('  currentStatus: "$currentStatus"');
    debugPrint('  mainFocus: "$mainFocus"');
    debugPrint('Available keys in data:');
    data.forEach((key, value) {
      debugPrint('  Status: "$key"');
      if (value is Map) {
        value.forEach((focusKey, _) {
          debugPrint('    Focus: "$focusKey"');
        });
      }
    });
    
    // Try exact match first
    var quizSet = data[currentStatus]?[mainFocus];
    
    // If no exact match, try case-insensitive match
    if (quizSet == null) {
      final statusLower = currentStatus.toLowerCase().trim();
      final focusLower = mainFocus.toLowerCase().trim();
      
      String? matchedStatus;
      String? matchedFocus;
      
      // Find matching status (case-insensitive)
      for (var statusKey in data.keys) {
        if (statusKey.toLowerCase().trim() == statusLower) {
          matchedStatus = statusKey;
          break;
        }
      }
      
      // Find matching focus (case-insensitive)
      if (matchedStatus != null && data[matchedStatus] is Map) {
        for (var focusKey in (data[matchedStatus] as Map).keys) {
          if (focusKey.toLowerCase().trim() == focusLower) {
            matchedFocus = focusKey;
            break;
          }
        }
      }
      
      if (matchedStatus != null && matchedFocus != null) {
        quizSet = data[matchedStatus]?[matchedFocus];
        debugPrint('Found case-insensitive match: $matchedStatus -> $matchedFocus');
      }
    }

    if (quizSet == null) {
      debugPrint('ERROR: No quiz data found for status="$currentStatus" and focus="$mainFocus"');
      return [];
    }

    List<Map<String, dynamic>> allQuestions = [];

    quizSet.forEach((sectionName, questions) {
      for (var i = 0; i < (questions as List).length; i++) {
        allQuestions.add({
          'section': sectionName,
          'question': questions[i],
          'index': i,
        });
      }
    });
    
    debugPrint('Total questions found: ${allQuestions.length}');

    return allQuestions;
  }
}
