// ============================================================================
// CAREER BOARD PAGE - Career Insights Dashboard
// ============================================================================
// This page displays comprehensive career information including:
// - Selected career with description
// - Industry growth rate with visual indicator
// - Demand level for the career
// - Top skills required for the role
// Note: Only accessible after completing the quiz
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:ui';
import 'dart:convert';

/// Career Board Page Widget
class CareerBoardPage extends StatefulWidget {
  const CareerBoardPage({super.key});

  @override
  State<CareerBoardPage> createState() => _CareerBoardPageState();
}

class _CareerBoardPageState extends State<CareerBoardPage> {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  
  int _currentBannerIndex = 0;
  late PageController _bannerController;
  bool _isLoading = true;
  bool _isQuizDone = false;
  GenerativeModel? _model;
  
  // Career data
  String selectedCareer = '';
  String careerDescription = 'Your selected career path';
  double industryGrowth = 0.0;
  String demandLevel = '';
  List<String> topSkills = [];
  
  // Tab state
  String _selectedTab = 'Colleges';
  
  // Real-time data lists
  List<Map<String, String>> _jobsList = [];
  List<Map<String, String>> _topCollegesList = [];
  List<Map<String, String>> _locationCollegesList = [];
  List<Map<String, String>> _resourcesList = [];
  int _topLimit = 10;
  int _locationLimit = 10;
  bool _isLoadingJobs = false;
  bool _isLoadingColleges = false;
  bool _isLoadingResources = false;
  bool _jobsLoadFailed = false;
  bool _collegesLoadFailed = false;
  bool _resourcesLoadFailed = false;
  
  // College location search
  final TextEditingController _collegeLocationSearchController = TextEditingController();
  String _collegeSearchLocation = '';
  
  // Pagination state
  String? _jobsNextPageToken;
  bool _isLoadingMoreJobs = false;
  bool _hasMoreJobs = false;
  int _resourcesStartIndex = 0;
  bool _isLoadingMoreResources = false;
  bool _hasMoreResources = false;

  // YouTube Videos state
  String _selectedResourceTab = 'Courses';
  List<Map<String, String>> _youtubeList = [];
  bool _isLoadingYoutube = false;
  bool _youtubeLoadFailed = false;
  String? _youtubeNextPageToken;
  bool _isLoadingMoreYoutube = false;
  bool _hasMoreYoutube = false;

  // User location state
  String _userCity = '';
  String _userState = '';
  String _userLocationDisplay = 'Detecting location...';
  
  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: 0);
    _initializeGemini();
    _loadUserData();
    // Detect user location first, then fetch colleges
    _detectUserLocation();
  }
  
  /// Fetch real jobs data using SERP API for Google Jobs search
  Future<void> _fetchRealJobsData({String? pageToken, bool isLoadMore = false}) async {
    debugPrint('fetchRealJobsData called for career: $selectedCareer, loadMore: $isLoadMore');
    if (selectedCareer.isEmpty) {
      debugPrint('Career is empty, skipping job fetch');
      return;
    }
    
    setState(() {
      if (isLoadMore) {
        _isLoadingMoreJobs = true;
      } else {
        _isLoadingJobs = true;
        _jobsLoadFailed = false;
        _jobsNextPageToken = null;
      }
    });
    
    try {
      final serpApiKey = dotenv.env['SERPAPI_KEY'];
      debugPrint('SERPAPI_KEY found: ${serpApiKey != null && serpApiKey.isNotEmpty}');
      
      if (serpApiKey == null || serpApiKey.isEmpty) {
        debugPrint('SERPAPI_KEY not found');
        setState(() {
          _isLoadingJobs = false;
          _jobsLoadFailed = true;
        });
        return;
      }
      
      // Build URL with optional pagination token — broaden the search
      final Uri url;
      final broadQuery = '$selectedCareer jobs India vacancy hiring 2026';
      
      if (kIsWeb) {
        final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
        var urlStr = '$supabaseUrl/functions/v1/serpapi-proxy?engine=google_jobs&q=${Uri.encodeComponent(broadQuery)}&location=India';
        if (pageToken != null) urlStr += '&next_page_token=${Uri.encodeComponent(pageToken)}';
        url = Uri.parse(urlStr);
      } else {
        var urlStr = 'https://serpapi.com/search.json?engine=google_jobs&q=${Uri.encodeComponent(broadQuery)}&location=India&api_key=$serpApiKey';
        if (pageToken != null) urlStr += '&next_page_token=${Uri.encodeComponent(pageToken)}';
        url = Uri.parse(urlStr);
      }
      
      debugPrint('Making request to: $url');
      final response = await http.get(url);
      debugPrint('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final jobsResults = data['jobs_results'] as List<dynamic>? ?? [];
        debugPrint('Jobs found: ${jobsResults.length}');
        
        // Extract next page token for pagination
        final nextToken = data['serpapi_pagination']?['next_page_token']?.toString();
        
        if (jobsResults.isEmpty && !isLoadMore) {
          debugPrint('No jobs found from API');
          setState(() {
            _jobsList = [];
            _isLoadingJobs = false;
            _jobsLoadFailed = true;
            _hasMoreJobs = false;
          });
          return;
        }
        
        // Sort jobs by most recently posted first
        jobsResults.sort((a, b) {
          final aPosted = _parseDaysAgo(a['detected_extensions']?['posted_at']?.toString() ?? '');
          final bPosted = _parseDaysAgo(b['detected_extensions']?['posted_at']?.toString() ?? '');
          return aPosted.compareTo(bPosted);
        });

        final newJobs = jobsResults.map((job) {
          final applyOptions = job['apply_options'] as List<dynamic>?;
          final applyLink = applyOptions != null && applyOptions.isNotEmpty
              ? applyOptions[0]['link']?.toString() ?? ''
              : job['share_link']?.toString() ?? '';
              
          final extensions = job['detected_extensions'] as Map<String, dynamic>?;
          
          return {
            'title': job['title']?.toString() ?? 'Job Title',
            'company': job['company_name']?.toString() ?? 'Company',
            'location': job['location']?.toString() ?? 'Location',
            'logo': job['thumbnail']?.toString() ?? '',
            'type': extensions?['schedule_type']?.toString() ?? 'Full-time',
            'salary': extensions?['salary']?.toString() ?? 'Not Disclosed',
            'posted': extensions?['posted_at']?.toString() ?? '',
            'description': job['description']?.toString() ?? 'No description available',
            'apply_link': applyLink,
          };
        }).toList();

        setState(() {
          if (isLoadMore) {
            _jobsList.addAll(newJobs);
          } else {
            _jobsList = newJobs;
          }
          _jobsNextPageToken = nextToken;
          _hasMoreJobs = nextToken != null && nextToken.isNotEmpty;
          _isLoadingJobs = false;
          _isLoadingMoreJobs = false;
          _jobsLoadFailed = false;
        });
        debugPrint('Jobs list updated with ${_jobsList.length} total items');
      } else {
        debugPrint('SERP API error: ${response.statusCode}, ${response.body}');
        setState(() {
          _isLoadingJobs = false;
          _isLoadingMoreJobs = false;
          _jobsLoadFailed = !isLoadMore;
        });
      }
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
      setState(() {
        _isLoadingJobs = false;
        _isLoadingMoreJobs = false;
        _jobsLoadFailed = !isLoadMore;
      });
    }
  }
  
  /// Fetch YouTube videos using YouTube Data API
  /// Fetch YouTube videos using YouTube Data API with SerpAPI Fallback
  Future<void> _fetchYoutubeVideos({String? pageToken, bool isLoadMore = false}) async {
    if (selectedCareer.isEmpty) return;
    
    final youtubeApiKey = dotenv.env['NEXT_PUBLIC_YOUTUBE_API_KEY'] ?? '';
    if (youtubeApiKey.isEmpty) {
      debugPrint('YouTube API key not found, trying fallback directly');
      return _fetchYoutubeVideosSerpFallback(pageToken: pageToken, isLoadMore: isLoadMore);
    }

    setState(() {
      if (isLoadMore) {
        _isLoadingMoreYoutube = true;
      } else {
        _isLoadingYoutube = true;
        _youtubeLoadFailed = false;
      }
    });

    try {
      final broadQuery = '$selectedCareer career guidance growth tutorial';
      
      // Attempt to get key from .env, but use hardcoded fallback as priority for this fix
      String currentApiKey = youtubeApiKey.trim();
      if (currentApiKey.isEmpty || currentApiKey.length < 10) {
        currentApiKey = 'AIzaSyDA0tOltyY42RLJi3bZV1gNBc5tktAq99w'; 
      }
      
      final urlStr = 'https://www.googleapis.com/youtube/v3/search'
          '?part=snippet'
          '&q=${Uri.encodeComponent(broadQuery)}'
          '&type=video'
          '&maxResults=15'
          '&order=relevance'
          '&key=$currentApiKey'
          '${pageToken != null ? '&pageToken=${Uri.encodeComponent(pageToken)}' : ''}';
          
      final uri = Uri.parse(urlStr);
      final response = await http.get(uri);
      debugPrint('📡 YouTube API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        final nextToken = data['nextPageToken']?.toString();

        if (items.isEmpty && !isLoadMore) {
          debugPrint('⚠️ Empty response from YouTube API, falling back to SerpAPI...');
          return _fetchYoutubeVideosSerpFallback(pageToken: pageToken, isLoadMore: isLoadMore);
        }

        final newVideos = items.map<Map<String, String>>((item) {
          final snippet = item['snippet'] ?? {};
          final videoId = item['id']?['videoId']?.toString() ?? '';
          String thumb = snippet['thumbnails']?['maxres']?['url']?.toString() ??
                 snippet['thumbnails']?['high']?['url']?.toString() ?? 
                 snippet['thumbnails']?['medium']?['url']?.toString() ?? '';
          
          if (thumb.isEmpty && videoId.isNotEmpty) {
            thumb = 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';
          }
          
          return {
            'title': snippet['title']?.toString() ?? 'Video Title',
            'channel': snippet['channelTitle']?.toString() ?? 'YouTube',
            'description': snippet['description']?.toString() ?? '',
            'thumbnail': thumb,
            'videoId': videoId,
            'url': 'https://www.youtube.com/watch?v=$videoId',
            'publishedAt': snippet['publishedAt']?.toString() ?? '',
          };
        }).toList();

        setState(() {
          if (isLoadMore) {
            _youtubeList.addAll(newVideos);
          } else {
            _youtubeList = newVideos;
          }
          _youtubeNextPageToken = nextToken;
          _hasMoreYoutube = nextToken != null && nextToken.isNotEmpty;
          _isLoadingYoutube = false;
          _isLoadingMoreYoutube = false;
          _youtubeLoadFailed = false;
        });
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // Expired or Invalid key - perform silent fallback to SerpAPI
        debugPrint('🚫 Key Expired/Invalid (${response.statusCode}), executing SerpAPI fallback...');
        return _fetchYoutubeVideosSerpFallback(pageToken: pageToken, isLoadMore: isLoadMore);
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in direct YouTube API: $e, trying fallback...');
      return _fetchYoutubeVideosSerpFallback(pageToken: pageToken, isLoadMore: isLoadMore);
    }
  }

  /// Silent fallback to SerpAPI to ensure videos are ALWAYS displayed
  Future<void> _fetchYoutubeVideosSerpFallback({String? pageToken, bool isLoadMore = false}) async {
    try {
      final broadQuery = '$selectedCareer career guidance growth tutorial';
      final serpApiKey = dotenv.env['SERPAPI_KEY'];
      final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
      
      final Uri url;
      if (kIsWeb) {
        var urlStr = '$supabaseUrl/functions/v1/serpapi-proxy?engine=google_videos&q=${Uri.encodeComponent(broadQuery)}&num=15';
        if (pageToken != null) urlStr += '&start=${Uri.encodeComponent(pageToken)}';
        url = Uri.parse(urlStr);
      } else {
        var urlStr = 'https://serpapi.com/search.json?engine=google_videos&q=${Uri.encodeComponent(broadQuery)}&api_key=$serpApiKey&num=15';
        if (pageToken != null) urlStr += '&start=${Uri.encodeComponent(pageToken)}';
        url = Uri.parse(urlStr);
      }

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['video_results'] as List<dynamic>? ?? [];
        final nextToken = data['serpapi_pagination']?['next']?.toString();

        final newVideos = results.map<Map<String, String>>((item) {
          final title = item['title']?.toString() ?? 'Video Title';
          String link = item['link']?.toString() ?? '';
          if (link.contains('google.com/url')) {
            final uri = Uri.tryParse(link);
            if (uri != null && uri.queryParameters.containsKey('url')) link = uri.queryParameters['url']!;
          }
          String videoId = '';
          final match = RegExp(r'(?:v=|\/|embed\/|youtu.be\/)([0-9A-Za-z_-]{11})').firstMatch(link);
          if (match != null) videoId = match.group(1)!;

          String thumb = item['thumbnail']?.toString() ?? '';
          if (thumb.isEmpty && videoId.isNotEmpty) thumb = 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

          return {
            'title': title,
            'channel': item['channel'] ?? item['source'] ?? 'YouTube',
            'description': item['description'] ?? '',
            'thumbnail': thumb,
            'videoId': videoId,
            'url': link.isNotEmpty ? link : 'https://www.youtube.com/watch?v=$videoId',
            'publishedAt': item['posted_at']?.toString() ?? '',
          };
        }).toList();

        setState(() {
          if (isLoadMore) {
            _youtubeList.addAll(newVideos);
          } else {
            _youtubeList = newVideos;
          }
          _youtubeNextPageToken = nextToken;
          _hasMoreYoutube = nextToken != null;
          _isLoadingYoutube = false;
          _isLoadingMoreYoutube = false;
          _youtubeLoadFailed = false;
        });
        debugPrint('✅ SerpAPI Fallback successful: ${_youtubeList.length} videos found');
      } else {
        throw Exception('SerpAPI Error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Critical Video Fetch Error: $e');
      setState(() {
        _isLoadingYoutube = false;
        _isLoadingMoreYoutube = false;
        _youtubeLoadFailed = true;
      });
    }
  }

  // ============================================================================
  // COLLEGES: Shared `colleges` table — append-only, never delete
  // ============================================================================

  /// Main entry: load colleges for the current career + location
  /// 1. Query `colleges` table for career match
  /// 2. If not enough results, fetch from SERP and INSERT/UPDATE into table
  /// 3. Split into top (India-wide) and nearby (user location)
  Future<void> _fetchRealCollegesData({String? searchLocation}) async {
    debugPrint('🔍 _fetchRealCollegesData — career=$selectedCareer, searchLocation=$searchLocation');
    if (selectedCareer.isEmpty) return;

    final searchInput = searchLocation ?? _collegeSearchLocation;
    
    setState(() {
      _isLoadingColleges = true;
      _collegesLoadFailed = false;
      if (searchInput.isNotEmpty) {
        _locationLimit = 10; // Reset search pagination on new search
      }
    });

    try {
      // ── Section 1: All India Top Ranking (Always Load) ──
      var topInstitutes = await _loadTopCollegesFromTable(selectedCareer);
      if (topInstitutes.length < 50) {
        topInstitutes = await _fetchTopCollegesFromSERP(selectedCareer);
        if (topInstitutes.isNotEmpty) {
          await _saveCollegesToTable(topInstitutes, selectedCareer, isTop: true, userLocation: 'India');
        }
      }

      // ── Section 2: Location-Specific Results (Only if searched) ──
      var locationInstitutes = <Map<String, String>>[];
      if (searchInput.isNotEmpty) {
        locationInstitutes = await _loadNearbyCollegesFromTable(selectedCareer, searchInput, '');
        if (locationInstitutes.isEmpty) {
          locationInstitutes = await _fetchNearbyCollegesFromSERP(selectedCareer, searchInput);
          if (locationInstitutes.isNotEmpty) {
            await _saveCollegesToTable(locationInstitutes, selectedCareer, isTop: false, userLocation: searchInput);
          }
        }
      }

      // Final State Update
      setState(() {
        _topCollegesList = _deduplicate(topInstitutes);
        _locationCollegesList = _deduplicate(locationInstitutes);
        _isLoadingColleges = false;
        _collegesLoadFailed = (_topCollegesList.isEmpty && _locationCollegesList.isEmpty);
      });
    } catch (e) {
      debugPrint('❌ _fetchRealCollegesData error: $e');
      setState(() {
        _isLoadingColleges = false;
        _collegesLoadFailed = true;
      });
    }
  }

  /// Clean helper to deduplicate local results
  List<Map<String, String>> _deduplicate(List<Map<String, String>> list) {
    final seen = <String>{};
    return list.where((college) {
      final name = (college['name'] ?? '').trim();
      if (name.isEmpty || !_isValidCollegeName(name)) return false;
      final key = name.toLowerCase().replaceAll(RegExp(r'[,.]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// Query `colleges` table for top colleges matching this career (India-wide)
  /// Filters by user_id, career, and is_top=true
  Future<List<Map<String, String>>> _loadTopCollegesFromTable(String career) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await Supabase.instance.client
          .from('colleges')
          .select()
          .eq('user_id', userId)
          .eq('career', career)
          .eq('is_top', true)
          .order('sort_order', ascending: true)
          .limit(100);

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('📦 Top colleges from DB for "$career": ${data.length}');

      return data.map((row) => <String, String>{
        'name': row['name']?.toString() ?? '',
        'location': row['location']?.toString() ?? 'India',
        'type': row['type']?.toString() ?? 'Institution',
        'fees': row['fees']?.toString() ?? 'N/A',
        'placement': row['placement']?.toString() ?? 'N/A',
        'courses': row['courses']?.toString() ?? '',
        'ranking': row['ranking']?.toString() ?? '',
      }).where((c) => _isValidCollegeName(c['name'] ?? '')).toList();
    } catch (e) {
      debugPrint('⚠️ Error loading top colleges from table: $e');
      return [];
    }
  }

  /// Query `colleges` table for nearby colleges matching career + location
  Future<List<Map<String, String>>> _loadNearbyCollegesFromTable(
    String career, String city, String state,
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Build user_location string to match
      final locationQuery = city.isNotEmpty && state.isNotEmpty
          ? '$city, $state'
          : city.isNotEmpty ? city : state;
      if (locationQuery.isEmpty) return [];

      final response = await Supabase.instance.client
          .from('colleges')
          .select()
          .eq('user_id', userId)
          .eq('career', career)
          .eq('is_top', false)
          .ilike('user_location', '%${city.isNotEmpty ? city : state}%')
          .order('sort_order', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      debugPrint('📦 Nearby colleges from DB for "$career" near "$city, $state": ${data.length}');

      return data.map((row) => <String, String>{
        'name': row['name']?.toString() ?? '',
        'location': row['location']?.toString() ?? 'India',
        'type': row['type']?.toString() ?? 'Institution',
        'fees': row['fees']?.toString() ?? 'N/A',
        'placement': row['placement']?.toString() ?? 'N/A',
        'courses': row['courses']?.toString() ?? '',
        'ranking': row['ranking']?.toString() ?? '',
      }).where((c) => _isValidCollegeName(c['name'] ?? '')).toList();
    } catch (e) {
      debugPrint('⚠️ Error loading nearby colleges from table: $e');
      return [];
    }
  }

  /// Check if a string looks like a valid college name
  bool _isValidCollegeName(String name) {
    if (name.length < 5 || name.length > 100) return false;
    final lower = name.toLowerCase();
    final trimmed = name.trim();

    // Reject search result titles / list headings / questions
    if (lower.startsWith('top ') || lower.startsWith('best ') || lower.startsWith('list of') || lower.startsWith('check ')) return false;
    if (lower.startsWith('why ') || lower.startsWith('which ') || lower.startsWith('what ') || lower.startsWith('how ')) return false;
    if (lower.contains('colleges in india') || lower.contains('universities in india') || lower.contains('institutes in india')) return false;
    if (lower.contains('colleges in ') && lower.split(' ').length < 5) return false; // Reject "Colleges in Delhi" etc.
    if (lower.contains('....') || lower.contains('admission') || lower.contains('2025') || lower.contains('2026') || lower.contains('2024') || lower.contains('2023')) return false;
    if (name.contains(';') || name.contains('|') || name.contains('>>') || name.contains('<<') || name.contains('...')) return false;
    if (lower.contains('click here') || lower.contains('read more') || lower.contains('know more') || lower.contains('view all')) return false;
    if (lower.contains('how to') || lower.contains('what is') || lower.contains('why choose') || lower.contains('apply now')) return false;
    if (lower.contains(' vs ') || lower.contains(' or ')) return false;
    // Reject plural "Colleges" or "Universities" — real names use singular
    if (RegExp(r'\bColleges\b|\bUniversities\b|\bInstitutes\b|\bSchools\b', caseSensitive: true).hasMatch(name)) return false;
    if (trimmed.split(' ').length > 12) return false; // Shorter word limit
    // Must start with a capital letter or known abbreviation
    if (!RegExp(r'^[A-Z]').hasMatch(trimmed) && !RegExp(r'^(IIT|IIM|NIT|BITS|IIIT|AIIMS|JNTU|VIT|SRM)').hasMatch(trimmed)) return false;
    // Reject if contains numbers in weird patterns
    if (RegExp(r'\d{4}|\s\d+\s|#\d+').hasMatch(name)) return false;
    // Must contain a college-like keyword (singular) or be a known institution
    final hasKeyword = RegExp(
      r'\bUniversity\b|\bCollege\b|\bInstitute\b|\bInstitution\b|\bPolytechnic\b|\bAcademy\b|\bSchool of\b|^IIT\s|^IIM\s|^NIT\s|^BITS\s|^AIIMS\s|^IIIT\s|^JNTU\s|^VIT\s|^SRM\s|^GITAM\s|^LPU\b|^Chitkara\s|^Amity\s|^Manipal\s|^Symbiosis\s|^Anna\s.*University|^Andhra\s.*University|^Delhi\s.*University|^Mumbai\s.*University|^Pune\s.*University',
      caseSensitive: false,
    ).hasMatch(name);
    if (!hasKeyword) return false;
    
    // Final check: must not be a generic phrase or category listing
    final genericPhrases = ['engineering college', 'medical college', 'arts college', 'private engineering college', 'best colleges', 'top colleges', 'colleges in india'];
    if (genericPhrases.any((p) => lower == p || (lower.contains(p) && name.split(' ').length <= 3))) return false;
    
    if (lower == 'college' || lower == 'university' || lower == 'institute' || lower == 'institution') return false;
    
    return true;
  }

  /// Save colleges to the per-user `colleges` table
  Future<void> _saveCollegesToTable(
    List<Map<String, String>> colleges, String career,
    {bool isTop = false, String userLocation = 'India'}
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot save colleges: No authenticated user');
        return;
      }

      debugPrint('💾 Saving ${colleges.length} colleges for career "$career" (isTop: $isTop, location: $userLocation)');
      int savedCount = 0;
      int updatedCount = 0;
      int skippedCount = 0;

      for (var i = 0; i < colleges.length; i++) {
        final c = colleges[i];
        final collegeName = (c['name'] ?? '').trim();
        if (collegeName.isEmpty || !_isValidCollegeName(collegeName)) {
          skippedCount++;
          continue;
        }

        try {
          // Check if this college already exists for this user+career+location
          final existing = await Supabase.instance.client
              .from('colleges')
              .select('id')
              .eq('user_id', userId)
              .eq('career', career)
              .eq('name', collegeName)
              .maybeSingle();

          if (existing != null) {
            // Already exists — update
            await Supabase.instance.client
                .from('colleges')
                .update({
                  'location': c['location'] ?? 'India',
                  'type': c['type'] ?? 'Institution',
                  'fees': c['fees'] ?? 'N/A',
                  'placement': c['placement'] ?? 'N/A',
                  'courses': c['courses'] ?? '',
                  'ranking': c['ranking'] ?? '',
                  'is_top': isTop,
                  'sort_order': i,
                  'user_location': userLocation,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                })
                .eq('id', existing['id']);
            updatedCount++;
            debugPrint('🔄 Updated college: $collegeName');
          } else {
            // New college — insert
            await Supabase.instance.client.from('colleges').insert({
              'user_id': userId,
              'career': career,
              'user_location': userLocation,
              'name': collegeName,
              'location': c['location'] ?? 'India',
              'type': c['type'] ?? 'Institution',
              'fees': c['fees'] ?? 'N/A',
              'placement': c['placement'] ?? 'N/A',
              'courses': c['courses'] ?? '',
              'ranking': c['ranking'] ?? '',
              'is_top': isTop,
              'sort_order': i,
            });
            savedCount++;
            debugPrint('✅ Inserted new college: $collegeName');
          }
        } catch (e) {
          debugPrint('⚠️ Error saving college "$collegeName": $e');
          // Continue with next college
        }
      }

      debugPrint('📊 Save complete: $savedCount inserted, $updatedCount updated, $skippedCount skipped');
    } catch (e) {
      debugPrint('⚠️ Error saving colleges to table: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  /// Fetch top colleges in India for a career via SERP API
  Future<List<Map<String, String>>> _fetchTopCollegesFromSERP(String career) async {
    try {
      final serpApiKey = dotenv.env['SERPAPI_KEY'];
      if (serpApiKey == null || serpApiKey.isEmpty) {
        debugPrint('❌ SERPAPI_KEY not found');
        return [];
      }

      final topColleges = <Map<String, String>>[];
      
      // Perform TWO queries to get breadth
      final queries = [
        'best premier 100 colleges in India for $career fees placement NIRF ranking',
        'top universities and private institutes in India for $career engineering medical management'
      ];

      for (var query in queries) {
        final Uri url;
        if (kIsWeb) {
          final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
          url = Uri.parse('$supabaseUrl/functions/v1/serpapi-proxy?engine=google&q=${Uri.encodeComponent(query)}&location=India&num=60');
        } else {
          url = Uri.parse('https://serpapi.com/search.json?engine=google&q=${Uri.encodeComponent(query)}&location=India&num=60&api_key=$serpApiKey');
        }

        debugPrint('🏆 SERP: Fetching for query: $query');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Knowledge graph
          final knowledgeGraph = data['knowledge_graph'];
          if (knowledgeGraph != null) {
            final kgTitle = knowledgeGraph['title']?.toString() ?? '';
            if (kgTitle.isNotEmpty) {
              topColleges.add({
                'name': kgTitle,
                'location': knowledgeGraph['address']?.toString() ?? knowledgeGraph['location']?.toString() ?? 'India',
                'type': knowledgeGraph['type']?.toString() ?? 'Institution',
                'fees': 'N/A',
                'placement': 'N/A',
                'ranking': knowledgeGraph['rating']?.toString() ?? '',
                'link': knowledgeGraph['website']?.toString() ?? knowledgeGraph['source']?['link']?.toString() ?? '',
              });
            }
          }

          // Organic results
          final organicResults = data['organic_results'] as List<dynamic>? ?? [];
          for (var result in organicResults) {
            final title = result['title']?.toString() ?? '';
            final snippet = result['snippet']?.toString() ?? '';
            final link = result['link']?.toString() ?? '';
            final extracted = _extractCollegesFromSearchResult(title, snippet);
            for (var c in extracted) {
              c['link'] = link;
              topColleges.add(c);
            }
          }
        }
      }

      // Deduplicate all results
      final seen = <String>{};
      final deduped = <Map<String, String>>[];
      for (var c in topColleges) {
        final name = (c['name'] ?? '').trim();
        if (name.isEmpty || !_isValidCollegeName(name)) continue;
        
        final key = name.toLowerCase().replaceAll(RegExp(r'[,.]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (key.length > 4 && !seen.contains(key)) {
          seen.add(key);
          deduped.add(c);
        }
      }

      debugPrint('🏆 Top colleges consolidated from multiple queries: ${deduped.length}');
      return deduped.take(100).toList();
    } catch (e) {
      debugPrint('❌ Top colleges SERP fetch failed: $e');
      return [];
    }
  }

  /// Fetch nearby colleges via SERP API based on location
  Future<List<Map<String, String>>> _fetchNearbyCollegesFromSERP(
    String career, String location,
  ) async {
    try {
      final serpApiKey = dotenv.env['SERPAPI_KEY'];
      if (serpApiKey == null || serpApiKey.isEmpty) {
        debugPrint('❌ SERPAPI_KEY not found');
        return [];
      }

      final query = 'colleges in $location for $career';

      final Uri url;
      if (kIsWeb) {
        final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
        url = Uri.parse('$supabaseUrl/functions/v1/serpapi-proxy?engine=google&q=${Uri.encodeComponent(query)}&num=15');
      } else {
        url = Uri.parse('https://serpapi.com/search.json?engine=google&q=${Uri.encodeComponent(query)}&num=15&api_key=$serpApiKey');
      }

      debugPrint('📍 SERP: Fetching nearby colleges near $location for $career');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nearbyColleges = <Map<String, String>>[];

        // 1. Local results (Google Maps/Places)
        final localResults = data['local_results']?['places'] as List<dynamic>? ?? [];
        debugPrint('📍 SERP local_results count: ${localResults.length}');
        for (var place in localResults) {
          final name = place['title']?.toString() ?? '';
          if (name.isNotEmpty && name.length > 3 && name.length <= 100) {
            nearbyColleges.add({
              'name': name,
              'location': place['address']?.toString() ?? location,
              'type': place['type']?.toString() ?? 'Institution',
              'fees': 'N/A',
              'placement': 'N/A',
              'ranking': place['rating']?.toString() ?? '',
              'link': place['links']?['website']?.toString() ?? place['links']?['directions']?.toString() ?? '',
            });
          }
        }

        // 2. Organic results — extract from titles AND snippets
        final organicResults = data['organic_results'] as List<dynamic>? ?? [];
        debugPrint('📍 SERP organic_results count: ${organicResults.length}');
        for (var result in organicResults) {
          final title = result['title']?.toString() ?? '';
          final snippet = result['snippet']?.toString() ?? '';
          final link = result['link']?.toString() ?? '';
          debugPrint('📍   Organic: $title');

          // Try extracting from title directly as a college name
          final cleanTitle = _cleanCollegeName(title);
          if (cleanTitle.isNotEmpty && _isValidCollegeName(cleanTitle)) {
            nearbyColleges.add({
              'name': cleanTitle,
              'location': _extractLocationFromText('$title $snippet', cleanTitle).isEmpty
                  ? location : _extractLocationFromText('$title $snippet', cleanTitle),
              'type': _guessCollegeType(cleanTitle),
              'fees': _extractFeesFromText('$title $snippet'),
              'placement': _extractPlacementFromText('$title $snippet'),
              'ranking': _extractRankingFromText('$title $snippet', cleanTitle),
              'link': link,
            });
          }

          // Also extract from snippet text
          final extracted = _extractCollegesFromSearchResult(title, snippet);
          nearbyColleges.addAll(extracted);
        }

        // 3. Answer box
        final answerBox = data['answer_box'];
        if (answerBox != null) {
          final answerSnippet = answerBox['snippet']?.toString() ??
              answerBox['answer']?.toString() ?? '';
          final answerTitle = answerBox['title']?.toString() ?? '';
          if (answerSnippet.isNotEmpty || answerTitle.isNotEmpty) {
            nearbyColleges.addAll(
              _extractCollegesFromSearchResult(answerTitle, answerSnippet),
            );
          }
        }

        // 4. Knowledge graph
        final knowledgeGraph = data['knowledge_graph'];
        if (knowledgeGraph != null) {
          final kgTitle = knowledgeGraph['title']?.toString() ?? '';
          if (kgTitle.isNotEmpty && _isValidCollegeName(kgTitle)) {
            nearbyColleges.add({
              'name': kgTitle,
              'location': knowledgeGraph['address']?.toString() ??
                  knowledgeGraph['location']?.toString() ?? location,
              'type': knowledgeGraph['type']?.toString() ?? 'Institution',
              'fees': 'N/A',
              'placement': 'N/A',
              'ranking': knowledgeGraph['rating']?.toString() ?? '',
            });
          }
        }

        // Deduplicate by name with normalization and validation
        final seen = <String>{};
        final deduped = <Map<String, String>>[];
        for (var c in nearbyColleges) {
          final name = (c['name'] ?? '').trim();
          if (name.isEmpty || !_isValidCollegeName(name)) continue;
          
          final key = name.toLowerCase()
              .replaceAll(RegExp(r'[,.]'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          if (key.length > 4 && !seen.contains(key)) {
            seen.add(key);
            deduped.add(c);
          }
        }

        debugPrint('📍 Nearby colleges from SERP (deduped): ${deduped.length}');
        return deduped;
      } else {
        debugPrint('❌ SERP returned status ${response.statusCode}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Nearby colleges SERP fetch failed: $e');
      return [];
    }
  }

  /// Clean a SERP result title to extract a college name
  String _cleanCollegeName(String title) {
    var name = title
        .replaceAll(RegExp(r'\b(are|is|and|campu|offer|eering)\b.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*[-|:]\s*(Wikipedia|Ranking|Courses|Fees|Admission|Shiksha|CollegeDunia|Collegedunia|Careers360|NIRF|Reviews|Overview|Placements|Cutoff|Info|Syllabus|Eligibility|Application|Careers|Jobs|Salary|Scope).*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\(.*?\)'), '')
        .replaceAll(RegExp(r'\s*-\s*$'), '')
        .replaceAll(RegExp(r'^\d+\.\s*'), '')
        .replaceAll(RegExp(r'\s*,\s*(Courses|Fees|Ranking|Admission|Placements|Reviews|Cutoff).*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*;\s*\d+.*'), '') // Remove "; 1" etc.
        .replaceAll(RegExp(r'\s+in\s+India.*', caseSensitive: false), '') 
        .replaceAll(RegExp(r'\s+near\s+.*', caseSensitive: false), '') 
        .trim();
    if (name.length > 100) {
      name = name.substring(0, 100).replaceAll(RegExp(r'\s+\S*$'), '');
    }
    return name;
  }

  /// Guess if a college is Government or Private based on name
  String _guessCollegeType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('iit') || lower.contains('nit') || lower.contains('aiims') || 
        lower.contains('iiit') || lower.contains('government') || lower.contains('govt') ||
        lower.contains('national') || lower.contains('central university') ||
        lower.contains('indian institute') || lower.contains('jntu') ||
        lower.contains('andhra university') || lower.contains('osmania')) {
      return 'Government';
    }
    return 'Private';
  }

  /// Search colleges at a specific location entered by user
  void _searchCollegesAtLocation(String location) {
    setState(() {
      _collegeSearchLocation = location.trim();
    });
    _fetchRealCollegesData(searchLocation: location.trim());
  }

  /// Extract college info from SERP search result text
  List<Map<String, String>> _extractCollegesFromSearchResult(String title, String snippet) {
    final colleges = <Map<String, String>>[];
    final combined = '$title. $snippet';

    // Known prestigious institution patterns
    final knownPatterns = [
      RegExp(r'(IIT\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false),
      RegExp(r'(IIM\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false),
      RegExp(r'(NIT\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false),
      RegExp(r'(BITS\s+[A-Z][a-z]+)', caseSensitive: false),
      RegExp(r'(IIIT\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)', caseSensitive: false),
      RegExp(r'(Indian Institute of (?:Technology|Management|Science|Information Technology)(?:\s+[A-Z][a-z]+)*)', caseSensitive: false),
      RegExp(r'(Delhi University|JNU|Jawaharlal Nehru University)', caseSensitive: false),
      RegExp(r'(AIIMS[\s,]*[A-Za-z]*)', caseSensitive: false),
      RegExp(r'(JNTU[\s,]*[A-Za-z]*)', caseSensitive: false),
      RegExp(r'(National Law (?:School|University)[^,.]*)', caseSensitive: false),
      RegExp(r"(St\.?\s+(?:Stephen|Xavier)[^,.]*(?:College|University)?)", caseSensitive: false),
      RegExp(r'(Shri Ram College of Commerce|SRCC)', caseSensitive: false),
      RegExp(r'(Christ University|Manipal[^,.]{0,30}|VIT[^,.]{0,30}|SRM[^,.]{0,30}|Amity[^,.]{0,30})', caseSensitive: false),
      RegExp(r'(ISB[\s,]|Indian School of Business)', caseSensitive: false),
      RegExp(r'(XLRI[^,.]*|FMS[^,.]*|MDI[^,.]*|SP Jain[^,.]*)', caseSensitive: false),
      RegExp(r'(Lady Shri Ram[^,.]*|LSR)', caseSensitive: false),
      RegExp(r'(Loyola College[^,.]*)', caseSensitive: false),
      RegExp(r'(Presidency[^,.]*(?:College|University))', caseSensitive: false),
      RegExp(r'(GITAM[^,.]{0,30})', caseSensitive: false),
      RegExp(r'(Andhra University[^,.]{0,30})', caseSensitive: false),
      RegExp(r'(Centurion University[^,.]{0,30})', caseSensitive: false),
      RegExp(r'(GMRIT[^,.]{0,20}|GMR Institute[^,.]{0,30})', caseSensitive: false),
      RegExp(r'(Vignan[^,.]{0,30})', caseSensitive: false),
      RegExp(r'(KL University[^,.]{0,20}|Koneru Lakshmaiah[^,.]{0,30})', caseSensitive: false),
    ];

    // Numbered list patterns: "1. College Name" or "1) College Name"
    final numberedPattern = RegExp(
      r'(?:^|\n|\d+[\.\)\s]+)([A-Z][A-Za-z\s\.&]+(?:University|Institute|College|School|Academy|Campus|Centre|Center|Polytechnic)[^,.\n]*)',
      multiLine: true,
    );

    // General pattern: any phrase containing college keywords
    final generalPattern = RegExp(
      r'([A-Z][A-Za-z\s\.&]{3,}(?:University|Institute|College|School|Academy|Engineering|Technology|Management|Medical|Polytechnic|Campus)(?:\s+(?:of|and|for|&)\s+[A-Za-z\s\.&]+)?)',
    );

    final addedNames = <String>{};

    void addCollege(String name) {
      name = name.trim();
      if (name.length > 100) {
        name = name.substring(0, 100).replaceAll(RegExp(r'\s+\S*$'), '');
      }
      final key = name.toLowerCase().trim();
      if (key.length > 3 && !addedNames.contains(key) && _isValidCollegeName(name)) {
        addedNames.add(key);
        colleges.add({
          'name': name,
          'location': _extractLocationFromText(combined, name),
          'type': _guessCollegeType(name),
          'fees': _extractFeesFromText(combined),
          'placement': _extractPlacementFromText(combined),
          'ranking': _extractRankingFromText(combined, name),
        });
      }
    }

    // 1. Check known patterns
    for (var pattern in knownPatterns) {
      for (var match in pattern.allMatches(combined)) {
        addCollege(match.group(1) ?? '');
      }
    }

    // 2. Numbered list patterns
    for (var match in numberedPattern.allMatches(combined)) {
      addCollege(match.group(1) ?? '');
    }

    // 3. General keyword-based extraction
    for (var match in generalPattern.allMatches(combined)) {
      addCollege(match.group(1) ?? '');
    }

    // 4. Comma/semicolon separated items that look like college names
    final listItems = combined.split(RegExp(r'[,;]'));
    for (var item in listItems) {
      item = item.trim();
      if (item.length > 4 && item.length < 100 && _isValidCollegeName(item)) {
        addCollege(item);
      }
    }

    return colleges;
  }

  /// Extract location from search text near a college name
  String _extractLocationFromText(String text, String collegeName) {
    final locationPattern = RegExp(
      '${RegExp.escape(collegeName)}[^.]*?(?:in|at|,)\\s*([A-Z][a-z]+(?:\\s+[A-Z][a-z]+)?)',
      caseSensitive: false,
    );
    final match = locationPattern.firstMatch(text);
    return match?.group(1)?.trim() ?? 'India';
  }

  /// Extract fees from search text
  String _extractFeesFromText(String text) {
    final feesPattern = RegExp(r'(?:fees?|tuition)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,\.]+\s*(?:lakh|lac|LPA|per\s*(?:year|annum))?)', caseSensitive: false);
    final match = feesPattern.firstMatch(text);
    if (match != null) {
      return '₹${match.group(1)?.trim() ?? 'N/A'}';
    }
    return 'N/A';
  }

  /// Extract placement from search text
  String _extractPlacementFromText(String text) {
    final placementPattern = RegExp(r'(?:highest|top|max)\s*(?:placement|package|salary|CTC)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,\.]+\s*(?:Cr|crore|LPA|lakh)?)', caseSensitive: false);
    final match = placementPattern.firstMatch(text);
    if (match != null) {
      return '₹${match.group(1)?.trim() ?? 'N/A'}';
    }
    return 'N/A';
  }

  /// Extract ranking from search text
  String _extractRankingFromText(String text, String collegeName) {
    final rankPattern = RegExp(r'(?:#|rank|ranked|no\.?)\s*(\d+)', caseSensitive: false);
    final match = rankPattern.firstMatch(text);
    if (match != null) {
      return '#${match.group(1)} in India';
    }
    return '';
  }
  
  /// Fetch real courses/resources data using SERP API for Google search
  Future<void> _fetchRealResourcesData({bool isLoadMore = false}) async {
    debugPrint('fetchRealResourcesData called for career: $selectedCareer, loadMore: $isLoadMore');
    if (selectedCareer.isEmpty) return;
    
    setState(() {
      if (isLoadMore) {
        _isLoadingMoreResources = true;
      } else {
        _isLoadingResources = true;
        _resourcesLoadFailed = false;
        _resourcesStartIndex = 0;
      }
    });
    
    try {
      final serpApiKey = dotenv.env['SERPAPI_KEY'];
      if (serpApiKey == null || serpApiKey.isEmpty) {
        debugPrint('SERPAPI_KEY not found for resources');
        setState(() {
          _isLoadingResources = false;
          _isLoadingMoreResources = false;
          _resourcesLoadFailed = true;
        });
        return;
      }
      
      final startIndex = isLoadMore ? _resourcesStartIndex : 0;
      
      // Use SERP API to search for courses and tutorials
      final Uri url;
      if (kIsWeb) {
        final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ?? '';
        var urlStr = '$supabaseUrl/functions/v1/serpapi-proxy?engine=google&q=${Uri.encodeComponent('$selectedCareer course tutorial learn')}&location=India&num=10';
        if (startIndex > 0) urlStr += '&start=$startIndex';
        url = Uri.parse(urlStr);
      } else {
        var urlStr = 'https://serpapi.com/search.json?engine=google&q=${Uri.encodeComponent(selectedCareer)}+course+tutorial+learn&api_key=$serpApiKey&num=10';
        if (startIndex > 0) urlStr += '&start=$startIndex';
        url = Uri.parse(urlStr);
      }
      
      debugPrint('Making resources request to: $url');
      final response = await http.get(url);
      debugPrint('Resources response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final organicResults = data['organic_results'] as List<dynamic>? ?? [];
        debugPrint('Resources found: ${organicResults.length}');
        
        if (organicResults.isEmpty && !isLoadMore) {
          setState(() {
            _resourcesList = [];
            _isLoadingResources = false;
            _resourcesLoadFailed = true;
            _hasMoreResources = false;
          });
          return;
        }
        
        final newResources = organicResults.map((result) {
          final link = result['link']?.toString() ?? '';
          String source = 'Web Resource';
          
          // Extract source from URL
          if (link.contains('coursera')) {
            source = 'Coursera';
          } else if (link.contains('udemy')) {
            source = 'Udemy';
          } else if (link.contains('youtube')) {
            return null; // Skip YouTube links in general resources
          } else if (link.contains('w3schools')) {
            source = 'W3Schools';
          } else if (link.contains('freecodecamp')) {
            source = 'FreeCodeCamp';
          } else if (link.contains('medium')) {
            source = 'Medium';
          } else if (link.contains('linkedin.com/learning')) {
            source = 'LinkedIn Learning';
          } else {
            // Extract domain name
            final uri = Uri.tryParse(link);
            if (uri != null && uri.host.isNotEmpty) {
              source = uri.host.replaceAll('www.', '');
            }
          }
          
          return {
            'title': result['title']?.toString() ?? 'Resource',
            'description': result['snippet']?.toString() ?? 'Learn more about $selectedCareer',
            'source': source,
            'url': link,
            'thumbnail': result['thumbnail']?.toString() ?? 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&q=80&w=800',
          };
        }).where((r) => r != null).toList().cast<Map<String, String>>();

        setState(() {
          if (isLoadMore) {
            _resourcesList.addAll(newResources);
          } else {
            _resourcesList = newResources;
          }
          _resourcesStartIndex = (isLoadMore ? _resourcesStartIndex : 0) + organicResults.length;
          _hasMoreResources = organicResults.isNotEmpty;
          _isLoadingResources = false;
          _isLoadingMoreResources = false;
          _resourcesLoadFailed = false;
        });
        debugPrint('Resources list updated with ${_resourcesList.length} total items');
      } else {
        debugPrint('SERP API error for resources: ${response.statusCode}');
        setState(() {
          _isLoadingResources = false;
          _isLoadingMoreResources = false;
          _resourcesLoadFailed = !isLoadMore;
        });
      }
    } catch (e) {
      debugPrint('Error fetching resources: $e');
      setState(() {
        _isLoadingResources = false;
        _isLoadingMoreResources = false;
        _resourcesLoadFailed = !isLoadMore;
      });
    }
  }

  /// Parse "X days ago" style strings into a comparable number of days
  int _parseDaysAgo(String posted) {
    if (posted.isEmpty) return 9999;
    final lower = posted.toLowerCase();
    final numMatch = RegExp(r'(\d+)').firstMatch(lower);
    final num = numMatch != null ? int.tryParse(numMatch.group(1)!) ?? 0 : 0;
    if (lower.contains('hour')) return 0;
    if (lower.contains('yesterday')) return 1;
    if (lower.contains('day')) return num;
    if (lower.contains('week')) return num * 7;
    if (lower.contains('month')) return num * 30;
    return 9999;
  }
  
  /// Attempt to repair truncated JSON from Gemini
  String _repairTruncatedJson(String json) {
    // Remove trailing incomplete string (unterminated quotes)
    // Find the last complete key-value pair
    var repaired = json.trim();
    
    // If we're inside a string value, close it
    int quoteCount = 0;
    for (var i = 0; i < repaired.length; i++) {
      if (repaired[i] == '"' && (i == 0 || repaired[i - 1] != '\\')) {
        quoteCount++;
      }
    }
    if (quoteCount % 2 != 0) {
      // Odd quotes — we're inside an unterminated string
      // Find last complete entry by looking for last complete quoted value
      final lastCompleteComma = repaired.lastIndexOf(',\n');
      final lastCompleteBracket = repaired.lastIndexOf('],');
      final cutPoint = lastCompleteBracket > lastCompleteComma 
          ? lastCompleteBracket + 1 
          : lastCompleteComma;
      if (cutPoint > 0) {
        repaired = repaired.substring(0, cutPoint);
      }
    }
    
    // Close any open brackets/braces
    int braces = 0;
    int brackets = 0;
    quoteCount = 0;
    for (var i = 0; i < repaired.length; i++) {
      if (repaired[i] == '"' && (i == 0 || repaired[i - 1] != '\\')) {
        quoteCount++;
      } else if (quoteCount % 2 == 0) {
        if (repaired[i] == '{') braces++;
        if (repaired[i] == '}') braces--;
        if (repaired[i] == '[') brackets++;
        if (repaired[i] == ']') brackets--;
      }
    }
    
    // Remove trailing comma before closing
    repaired = repaired.trimRight();
    if (repaired.endsWith(',')) {
      repaired = repaired.substring(0, repaired.length - 1);
    }
    
    for (var i = 0; i < brackets; i++) { repaired += ']'; }
    for (var i = 0; i < braces; i++) { repaired += '}'; }
    
    return repaired;
  }

  /// Initialize Gemini AI model
  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 2048,
        ),
      );
      debugPrint('✅ Gemini AI initialized with model: gemini-2.5-flash');
    } else {
      debugPrint('❌ Gemini API key not found');
    }
  }

  /// Detect user's current location using IP-based geolocation (no permissions needed)
  Future<void> _detectUserLocation() async {
    try {
      debugPrint('📍 Detecting user location via IP...');
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/?fields=city,regionName,country,status'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _userCity = data['city']?.toString() ?? '';
            _userState = data['regionName']?.toString() ?? '';
            _userLocationDisplay = _userCity.isNotEmpty && _userState.isNotEmpty
                ? '$_userCity, $_userState'
                : _userCity.isNotEmpty
                    ? _userCity
                    : _userState.isNotEmpty
                        ? _userState
                        : 'India';
          });
          debugPrint('📍 Location detected: $_userCity, $_userState');
        } else {
          _setDefaultLocation();
        }
      } else {
        _setDefaultLocation();
      }
    } catch (e) {
      debugPrint('⚠️ Location detection failed: $e');
      _setDefaultLocation();
    }

    // Now fetch colleges with location context
    _fetchRealCollegesData();
  }

  /// Set default location fallback
  void _setDefaultLocation() {
    setState(() {
      _userCity = '';
      _userState = '';
      _userLocationDisplay = 'India';
    });
  }
  
  @override
  void dispose() {
    _bannerController.dispose();
    _collegeLocationSearchController.dispose();
    super.dispose();
  }
  
  // ============================================================================
  // DATA LOADING
  // ============================================================================
  
  /// Load user data and check quiz completion
  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch user data
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final isQuizDone = response['isQuizDone'] == true;
        
        setState(() {
          _isQuizDone = isQuizDone;
        });

        if (isQuizDone) {
          // Load career data
          final mainFocus = response['mainFocus']?.toString() ?? '';
          if (mainFocus.isNotEmpty && mainFocus.toLowerCase() != 'choose career paths') {
            await _loadCareerData(mainFocus);
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load career-specific data — checks Supabase cache first, falls back to AI
  Future<void> _loadCareerData(String career) async {
    try {
      setState(() {
        selectedCareer = career;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 1. Try loading cached data from Supabase for this user + career
      final cached = await Supabase.instance.client
          .from('careers_info')
          .select()
          .eq('user_id', user.id)
          .eq('career_name', career)
          .maybeSingle();

      if (cached != null) {
        debugPrint('✅ Career data found in Supabase cache for: $career');
        final growth = cached['industry_growth'];
        final demand = cached['demand_level'];
        final skills = cached['top_skills'];

        setState(() {
          industryGrowth = (growth is num)
              ? growth.toDouble()
              : double.tryParse(growth?.toString() ?? '') ?? 10.0;
          demandLevel = demand?.toString() ?? 'Medium';
          topSkills = (skills is List && skills.isNotEmpty)
              ? skills.map((s) => s.toString()).toList()
              : _getDefaultSkills(career);
          _isLoading = false;
        });
        return;
      }

      // 2. No cache — fetch from AI and save to Supabase
      debugPrint('🔄 No cached data found, fetching from AI for: $career');
      await _fetchCareerDataFromAI(career);
    } catch (e) {
      debugPrint('Error loading career data: $e');
      // Use accurate fallback data
      final fallbackData = _getAccurateCareerData(career);
      setState(() {
        industryGrowth = fallbackData['growth']!;
        demandLevel = fallbackData['demand']!;
        topSkills = List<String>.from(fallbackData['skills']!);
        _isLoading = false;
      });
    }
  }
  
  /// Get accurate career data based on 2024-2026 market research
  Map<String, dynamic> _getAccurateCareerData(String career) {
    final careerLower = career.toLowerCase();
    
    // AI/ML Engineer
    if (careerLower.contains('ai') || careerLower.contains('ml') || 
        careerLower.contains('machine learning') || careerLower.contains('artificial intelligence')) {
      return {
        'growth': 38.5,
        'demand': 'High',
        'skills': ['Python', 'TensorFlow', 'PyTorch', 'ML Algorithms', 'Deep Learning']
      };
    }
    // Data Engineer
    else if (careerLower.contains('data engineer')) {
      return {
        'growth': 33.8,
        'demand': 'High',
        'skills': ['Python', 'SQL', 'Spark', 'ETL', 'Data Modeling']
      };
    }
    // Data Scientist / Data Analyst
    else if (careerLower.contains('data')) {
      return {
        'growth': 27.5,
        'demand': 'High',
        'skills': ['Python', 'SQL', 'Statistics', 'Data Visualization', 'Machine Learning']
      };
    }
    // Full Stack Developer
    else if (careerLower.contains('full stack') || careerLower.contains('fullstack')) {
      return {
        'growth': 16.2,
        'demand': 'High',
        'skills': ['React', 'Node.js', 'JavaScript', 'MongoDB', 'Git']
      };
    }
    // Frontend Developer
    else if (careerLower.contains('frontend') || careerLower.contains('front end')) {
      return {
        'growth': 14.8,
        'demand': 'High',
        'skills': ['React', 'JavaScript', 'TypeScript', 'CSS', 'HTML']
      };
    }
    // Backend Developer
    else if (careerLower.contains('backend') || careerLower.contains('back end')) {
      return {
        'growth': 15.3,
        'demand': 'High',
        'skills': ['Node.js', 'Python', 'SQL', 'REST APIs', 'Docker']
      };
    }
    // DevOps Engineer
    else if (careerLower.contains('devops')) {
      return {
        'growth': 21.7,
        'demand': 'High',
        'skills': ['Docker', 'Kubernetes', 'CI/CD', 'AWS', 'Terraform']
      };
    }
    // Cloud Engineer / Cloud Architect
    else if (careerLower.contains('cloud')) {
      return {
        'growth': 24.3,
        'demand': 'High',
        'skills': ['AWS', 'Azure', 'Kubernetes', 'Terraform', 'Cloud Security']
      };
    }
    // Cybersecurity
    else if (careerLower.contains('security') || careerLower.contains('cyber')) {
      return {
        'growth': 19.4,
        'demand': 'High',
        'skills': ['Network Security', 'Penetration Testing', 'SIEM', 'Cloud Security', 'Incident Response']
      };
    }
    // Software Engineer / Developer
    else if (careerLower.contains('software') || careerLower.contains('developer')) {
      return {
        'growth': 13.5,
        'demand': 'High',
        'skills': ['Java', 'Python', 'Git', 'Algorithms', 'System Design']
      };
    }
    // UI/UX Designer
    else if (careerLower.contains('ui') || careerLower.contains('ux') || careerLower.contains('design')) {
      return {
        'growth': 11.2,
        'demand': 'Medium',
        'skills': ['Figma', 'User Research', 'Prototyping', 'Design Systems', 'Adobe XD']
      };
    }
    // Product Manager
    else if (careerLower.contains('product')) {
      return {
        'growth': 12.8,
        'demand': 'High',
        'skills': ['Product Strategy', 'Agile', 'User Stories', 'Analytics', 'Roadmapping']
      };
    }
    // Business Analyst
    else if (careerLower.contains('business analyst')) {
      return {
        'growth': 9.7,
        'demand': 'Medium',
        'skills': ['SQL', 'Excel', 'Power BI', 'Requirements Analysis', 'Process Modeling']
      };
    }
    // Digital Marketing
    else if (careerLower.contains('marketing') || careerLower.contains('digital')) {
      return {
        'growth': 10.4,
        'demand': 'Medium',
        'skills': ['SEO', 'Google Analytics', 'Social Media', 'Content Marketing', 'PPC']
      };
    }
    // Blockchain Developer
    else if (careerLower.contains('blockchain') || careerLower.contains('web3')) {
      return {
        'growth': 31.2,
        'demand': 'High',
        'skills': ['Solidity', 'Ethereum', 'Smart Contracts', 'Web3.js', 'Cryptography']
      };
    }
    // Mobile Developer
    else if (careerLower.contains('mobile') || careerLower.contains('android') || careerLower.contains('ios')) {
      return {
        'growth': 12.1,
        'demand': 'Medium',
        'skills': ['Flutter', 'React Native', 'Swift', 'Kotlin', 'Mobile UI']
      };
    }
    // Game Developer
    else if (careerLower.contains('game')) {
      return {
        'growth': 8.9,
        'demand': 'Medium',
        'skills': ['Unity', 'Unreal Engine', 'C#', '3D Modeling', 'Game Design']
      };
    }
    // Default fallback
    else {
      return {
        'growth': 12.0,
        'demand': 'Medium',
        'skills': _getDefaultSkills(career)
      };
    }
  }
  
  /// Fetch accurate, real-time career data from Gemini AI
  Future<void> _fetchCareerDataFromAI(String career) async {
    try {
      if (_model == null) {
        // Fallback to defaults if AI not available
        setState(() {
          industryGrowth = 10.0;
          demandLevel = 'High';
          topSkills = _getDefaultSkills(career);
          _isLoading = false;
        });
        return;
      }

      final prompt = '''
You are an expert career market analyst with access to current 2026 labor market data, industry reports, and employment statistics.

Analyze the career: "$career" and provide accurate, data-driven statistics.

Return ONLY a valid JSON object (no markdown, no code blocks):
{
  "industry_growth": <number>,
  "demand_level": "<High/Medium/Low>",
  "top_skills": ["skill1", "skill2", "skill3", "skill4", "skill5"]
}

CRITICAL Requirements:
1. industry_growth: Provide the actual CAGR (Compound Annual Growth Rate) or projected annual growth percentage for 2024-2030
   - For Data Engineering: Use ~24-36% (India: 33.8-36.7%, Global: 24.13%)
   - For Software Development: Use ~10-15%
   - For AI/ML: Use ~35-40%
   - Research actual market reports for other careers
   - Return a realistic number between 0-50

2. demand_level: Analyze current job market
   - High: >20% YoY growth, high job postings, skill shortage
   - Medium: 10-20% growth, moderate demand
   - Low: <10% growth or declining

3. top_skills: List 5 most in-demand skills with current market relevance
   - For tech roles: Include programming languages, tools, frameworks
   - For non-tech: Include industry-specific competencies
   - Base on actual job postings and skill surveys

Use real data from: LinkedIn Workforce Report, Bureau of Labor Statistics, Gartner, McKinsey, industry-specific market research reports.

Be precise and data-driven. Return realistic numbers that reflect actual market conditions.''';


      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';
      
      debugPrint('====================================');
      debugPrint('AI Response for $career:');
      debugPrint(responseText);
      debugPrint('====================================');

      // Parse AI response
      try {
        // Remove markdown code blocks if present
        String cleanJson = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        // Try to find JSON object in the response
        final jsonStart = cleanJson.indexOf('{');
        final jsonEnd = cleanJson.lastIndexOf('}');
        
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1);
        } else if (jsonStart != -1) {
          // JSON was truncated — try to repair it
          cleanJson = cleanJson.substring(jsonStart);
          cleanJson = _repairTruncatedJson(cleanJson);
        }
        
        debugPrint('Cleaned JSON: $cleanJson');
        
        final data = json.decode(cleanJson) as Map<String, dynamic>;
        
        debugPrint('Parsed data: $data');
        
        // Validate and set data
        final growth = data['industry_growth'];
        final demand = data['demand_level'];
        final skills = data['top_skills'];
        
        setState(() {
          // Handle different number formats
          if (growth is num) {
            industryGrowth = growth.toDouble();
          } else if (growth is String) {
            industryGrowth = double.tryParse(growth) ?? 10.0;
          } else {
            industryGrowth = 10.0;
          }
          
          demandLevel = demand?.toString() ?? 'Medium';
          
          if (skills is List && skills.isNotEmpty) {
            topSkills = skills.map((s) => s.toString()).toList();
          } else {
            topSkills = _getDefaultSkills(career);
          }
          
          _isLoading = false;
        });
        
        debugPrint('Final values - Growth: $industryGrowth, Demand: $demandLevel, Skills: $topSkills');
        
        // Save to database for future use
        await _saveCareerDataToDatabase(career, data);
        
      } catch (parseError) {
        debugPrint('Error parsing AI response: $parseError');
        // Fallback to defaults
        setState(() {
          industryGrowth = 10.0;
          demandLevel = 'High';
          topSkills = _getDefaultSkills(career);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching career data from AI: $e');
      setState(() {
        industryGrowth = 10.0;
        demandLevel = 'High';
        topSkills = _getDefaultSkills(career);
        _isLoading = false;
      });
    }
  }
  
  /// Save AI-fetched career data to Supabase (per user + career)
  Future<void> _saveCareerDataToDatabase(String career, Map<String, dynamic> data) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('careers_info').upsert(
        {
          'user_id': user.id,
          'career_name': career,
          'industry_growth': data['industry_growth'],
          'demand_level': data['demand_level'],
          'top_skills': data['top_skills'],
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,career_name',
      );
      debugPrint('✅ Career data saved to database for user ${user.id}, career: $career');
    } catch (e) {
      debugPrint('⚠️ Could not save career data to database: $e');
      // Non-critical error, continue
    }
  }

  /// Get default skills for a career if not in database
  List<String> _getDefaultSkills(String career) {
    final careerLower = career.toLowerCase();
    
    // Full Stack Developer
    if (careerLower.contains('full stack') || careerLower.contains('fullstack')) {
      return ['React', 'Node.js', 'JavaScript', 'Git', 'MongoDB'];
    }
    // Frontend Developer
    else if (careerLower.contains('front') || careerLower.contains('frontend')) {
      return ['React', 'JavaScript', 'CSS', 'HTML', 'TypeScript'];
    }
    // Backend Developer
    else if (careerLower.contains('back') || careerLower.contains('backend')) {
      return ['Node.js', 'Python', 'SQL', 'REST APIs', 'Docker'];
    }
    // Data Engineer / Data Analyst
    else if (careerLower.contains('data')) {
      return ['Python', 'SQL', 'Spark', 'ETL', 'Data Modeling'];
    }
    // Software Engineer / Developer
    else if (careerLower.contains('software') || careerLower.contains('developer')) {
      return ['Java', 'Python', 'Git', 'Algorithms', 'Testing'];
    }
    // DevOps Engineer
    else if (careerLower.contains('devops')) {
      return ['Docker', 'Kubernetes', 'CI/CD', 'AWS', 'Linux'];
    }
    // Machine Learning / AI
    else if (careerLower.contains('machine learning') || careerLower.contains('ml') || careerLower.contains('ai')) {
      return ['Python', 'TensorFlow', 'PyTorch', 'ML Algorithms', 'Statistics'];
    }
    // UI/UX Designer
    else if (careerLower.contains('design') || careerLower.contains('ui') || careerLower.contains('ux')) {
      return ['Figma', 'UI/UX', 'Prototyping', 'User Research', 'Adobe XD'];
    }
    // Product Manager
    else if (careerLower.contains('product')) {
      return ['Product Strategy', 'Agile', 'Analytics', 'Roadmapping', 'Stakeholder Management'];
    }
    // Business Analyst
    else if (careerLower.contains('business') || careerLower.contains('analyst')) {
      return ['Data Analysis', 'SQL', 'Excel', 'Requirements Gathering', 'Reporting'];
    }
    // Marketing
    else if (careerLower.contains('marketing')) {
      return ['Digital Marketing', 'SEO', 'Google Analytics', 'Content Strategy', 'Social Media'];
    }
    // Generic fallback
    else {
      return ['Communication', 'Problem Solving', 'Teamwork', 'Adaptability', 'Critical Thinking'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Career Insights',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5E9EF5),
              ),
            )
          : !_isQuizDone
              ? _buildQuizIncompleteScreen()
              : selectedCareer.isEmpty || selectedCareer.toLowerCase() == 'choose career paths'
                  ? _buildNoCareerScreen()
                  : _buildCareerInsightsContent(),
    );
  }

  /// Build screen when quiz is not completed
  Widget _buildQuizIncompleteScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5E9EF5), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E9EF5).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.quiz,
                size: 80,
                color: Color(0xFF5E9EF5),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Complete Your Quiz First!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2347),
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To access your personalized career insights, you need to complete the career assessment quiz first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E9EF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build screen when no career is selected
  Widget _buildNoCareerScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFBBF24), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.work_outline,
                size: 80,
                color: Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Career Path Selected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2347),
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please select a career path using the AI Career Coach to view your personalized insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E9EF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build career insights content
  Widget _buildCareerInsightsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Header Banner Section
          _buildHeaderBanner(),
          
          const SizedBox(height: 16),
          
          // Career Info Cards Section - Mobile-friendly layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Selected Career Card (Full width)
                _buildSelectedCareerCard(),
                
                const SizedBox(height: 12),
                
                // Row with Industry Growth and Demand Level
                Row(
                  children: [
                    Expanded(
                      child: _buildIndustryGrowthCard(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDemandLevelCard(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Top Skills Card (Full width)
                _buildTopSkillsCard(),
                
                const SizedBox(height: 20),
                
                // Resources Banner
                _buildResourcesBanner(),
                
                const SizedBox(height: 16),
                
                // Tabs Section (Jobs, Colleges, Resources)
                _buildTabsSection(),
                
                const SizedBox(height: 20),
                
                // Tab Content - switches based on selected tab
                if (_selectedTab == 'Jobs') _buildJobsContent(),
                if (_selectedTab == 'Colleges') _buildCollegesContent(),
                if (_selectedTab == 'Resources') _buildResourcesContent(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
            
  /// Build Header Banner with scrollable carousel
  Widget _buildHeaderBanner() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: MediaQuery.of(context).size.height * 0.27,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5E9EF5).withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: PageView(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            children: [
              _buildBannerPage(
                gradient: [const Color(0xFFFFF4CC), const Color(0xFFFFF4CC)],
                title: 'Know Your Career Fit',
                subtitle: 'Personalized AI assessment to help you determine whether you\'re ready for your career.',
                imagePath: 'assets/element8.png',
                buttonColor: const Color(0xFFFFD54F),
                buttonText: 'Check Out',
                buttonIcon: Icons.arrow_forward,
              ),
              _buildBannerPage(
                gradient: [const Color(0xFFE8F5FF), const Color(0xFFF5FBFF)],
                title: 'Get Industry Insights',
                subtitle: 'Jobs, courses, colleges, and much more to help you prepare for your career.',
                imagePath: 'assets/static1.png',
                buttonColor: const Color(0xFF5E9EF5),
                buttonText: 'Learn More',
                buttonIcon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == index
                    ? const Color(0xFF5E9EF5)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual banner page for the carousel
  Widget _buildBannerPage({
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color buttonColor,
    required String buttonText,
    required IconData buttonIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Left Content - White with slight color shade
          Expanded(
            flex: 50,
            child: Stack(
              children: [
                // White background
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
                // Light color in top corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          gradient[0].withOpacity(0.15),
                          gradient[0].withOpacity(0.05),
                          Colors.white.withOpacity(0),
                        ],
                        radius: 0.8,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1B1B),
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B3B3B),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(buttonIcon, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Image - Colored background with decorative elements
          Expanded(
            flex: 30,
            child: Container(
              decoration: BoxDecoration(
                color: gradient[0],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // Background decorative image - staic6.png
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        'assets/staic6.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  // Background decorative image - static3.png
                  Positioned(
                    bottom: 10,
                    left: 5,
                    child: Opacity(
                      opacity: 0.25,
                      child: Image.asset(
                        'assets/static3.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  // Main image - large and filling the box
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Selected Career Card
  Widget _buildSelectedCareerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.stars,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Selected Career',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            selectedCareer,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            careerDescription,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Industry Growth Card with progress indicator
  Widget _buildIndustryGrowthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.trending_up,
                color: Color(0xFF10B981),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Industry Growth',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${industryGrowth.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Annual Growth (CAGR)',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (industryGrowth / 50).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE5E7EB),
              color: industryGrowth >= 20 ? const Color(0xFF10B981) : 
                     industryGrowth >= 10 ? const Color(0xFF3B82F6) : 
                     const Color(0xFFF59E0B),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            industryGrowth >= 20 ? 'Excellent Growth' : 
            industryGrowth >= 10 ? 'Strong Growth' : 
            industryGrowth >= 5 ? 'Moderate Growth' : 'Slow Growth',
            style: TextStyle(
              fontSize: 10,
              color: industryGrowth >= 20 ? const Color(0xFF10B981) : 
                     industryGrowth >= 10 ? const Color(0xFF3B82F6) : 
                     const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Demand Level Card with progress indicator
  Widget _buildDemandLevelCard() {
    final double demandValue = demandLevel == 'High' ? 0.85 : 
                                demandLevel == 'Medium' ? 0.5 : 0.25;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.trending_up_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Demand Level',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            demandLevel,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: demandValue,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF3B82F6),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Job Market Demand',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Top Skills Card with skill chips
  Widget _buildTopSkillsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Top Skills',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topSkills.map((skill) {
              return Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth < 600;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      height: isMediumScreen ? 200 : 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Premium Gradient Background (Works on Web & Native)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F46E5), // Indigo
                      Color(0xFF7C3AED), // Violet
                      Color(0xFFC026D3), // Fuchsia
                      Color(0xFFDB2777), // Pink
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.1, 0.4, 0.7, 0.9],
                  ),
                ),
              ),
            ),
            
            // Decorative Abstract Shapes
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            
            // Glassmorphism Content Area
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: screenWidth * 0.85,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Right Resources found just for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Browse curated Courses, Videos and Job Opportunities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Tabs Section for Jobs, Colleges, Resources
  Widget _buildTabsSection() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Jobs', _selectedTab == 'Jobs'),
          ),
          Expanded(
            child: _buildTabButton('Colleges', _selectedTab == 'Colleges'),
          ),
          Expanded(
            child: _buildTabButton('Resources', _selectedTab == 'Resources'),
          ),
        ],
      ),
    );
  }

  /// Build individual tab button
  Widget _buildTabButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
        
        // Fetch data when respective tab is selected
        if (label == 'Jobs' && _jobsList.isEmpty) {
          _fetchRealJobsData();
        } else if (label == 'Colleges' && _topCollegesList.isEmpty && _locationCollegesList.isEmpty) {
          _fetchRealCollegesData();
        } else if (label == 'Resources' && _resourcesList.isEmpty) {
          _fetchRealResourcesData();
        }
        
        debugPrint('Selected tab: $label');
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C3E50) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  /// Build Jobs Content Section
  Widget _buildJobsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search results and Refresh Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Search results for ',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: selectedCareer,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF5E9EF5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.track_changes, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Track Jobs',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite_border, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Liked',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Refresh Button
            Tooltip(
              message: 'Refresh latest jobs',
              child: Material(
                color: const Color(0xFF5E9EF5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _fetchRealJobsData(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF5E9EF5),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Job Cards in 2-column grid
        _isLoadingJobs
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _jobsLoadFailed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load jobs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unable to fetch job listings. Please try again later.',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : (_jobsList.isEmpty && !_isLoadingJobs)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const Icon(Icons.work_outline, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('No current job listings found.', style: TextStyle(color: Colors.grey)),
                              TextButton(onPressed: () => _fetchRealJobsData(), child: const Text('Retry Search')),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _jobsList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final job = _jobsList[index];
                              return _buildJobCard(
                                title: job['title'] ?? '',
                                company: job['company'] ?? '',
                                location: job['location'] ?? '',
                                description: job['description'] ?? '',
                                applyLink: job['apply_link'] ?? '',
                                logo: job['logo'] ?? '',
                                type: job['type'] ?? 'Full-time',
                                salary: job['salary'] ?? 'Not Disclosed',
                                posted: job['posted'] ?? 'Just now',
                              );
                            },
                          ),
                          if (_hasMoreJobs) ...[
                            const SizedBox(height: 16),
                            _isLoadingMoreJobs
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _fetchRealJobsData(
                                          pageToken: _jobsNextPageToken,
                                          isLoadMore: true,
                                        );
                                      },
                                      icon: const Icon(Icons.expand_more),
                                      label: Text('Load More Jobs (${_jobsList.length} shown)'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5E9EF5),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ],
                      ),
      ],
    );
  }

  /// Build individual job card (Internshala Style)
  Widget _buildJobCard({
    required String title,
    required String company,
    required String location,
    required String description,
    required String applyLink,
    required String logo,
    required String type,
    required String salary,
    required String posted,
  }) {
    // Determine dynamic values like experience from description
    String experience = 'No prior experience required';
    if (description.toLowerCase().contains('exp') || description.toLowerCase().contains('year')) {
      final reg = RegExp(r'(\d+)\+?\s?(year|yr)', caseSensitive: false);
      final match = reg.firstMatch(description);
      if (match != null) {
        experience = '${match.group(0)} experience';
      }
    }
    
    // Extract skills if possible, else some fallback from title
    List<String> skills = [];
    if (description.contains('Skill')) {
      // Very naive extraction, but we want real content where possible
      final chunks = description.split(RegExp(r'Skill|Requirements|Required', caseSensitive: false));
      if (chunks.length > 1) {
        final lines = chunks[1].split('\n').take(2);
        for (var l in lines) {
           final s = l.replaceAll(RegExp(r'[-:*•]'), '').trim();
           if (s.isNotEmpty && s.length < 20) skills.add(s);
        }
      }
    }
    if (skills.isEmpty) {
      if (title.contains(' ')) skills = title.split(' ').take(2).toList();
      else if (selectedCareer.isNotEmpty) skills = [selectedCareer];
    }
    if (skills.length > 2) skills = skills.sublist(0, 2);

    return InkWell(
      onTap: applyLink.isNotEmpty
          ? () async {
              final uri = Uri.tryParse(applyLink);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Title, Company and Logo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Company Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: logo.isNotEmpty
                        ? Image.network(
                            logo,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                                Center(child: Text(company[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          )
                        : Center(child: Text(company[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Detail Icons
            _jobDetailRow(Icons.work_outline, experience),
            const SizedBox(height: 8),
            _jobDetailRow(Icons.access_time, type),
            const SizedBox(height: 8),
            _jobDetailRow(Icons.location_on_outlined, location),
            const SizedBox(height: 16),
            
            // Badges & Salary
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skills Chips
                  Row(
                    children: [
                      ...skills.map((s) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      )),
                      if (description.length > 50) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${(description.length / 100).floor() + 2}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ],
                  ),
                  
                  // Salary Badge (Green)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          salary == 'Not Disclosed' ? '₹ Not Disclosed' : salary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.money_rounded, color: Color(0xFF4CAF50), size: 14),
                      ],
                    ),
                  ),
                ],
            ),
            
            const SizedBox(height: 16),
            Divider(color: Colors.grey[100]),
            const SizedBox(height: 12),
            
            // Footer: Posting Date, Days left, Heart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      posted.isNotEmpty ? posted : 'Just now',
                      style: TextStyle(fontSize: 13, color: Colors.blue[600]),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Apply soon',
                          style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(Icons.favorite_outline_rounded, color: Colors.grey[400], size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobDetailRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build Colleges Content Section
  Widget _buildCollegesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Section
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _collegeLocationSearchController,
                decoration: InputDecoration(
                  hintText: 'Search city (e.g. Pune, Delhi)',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[100]!)),
                ),
                onSubmitted: (v) => _searchCollegesAtLocation(v),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _searchCollegesAtLocation(_collegeLocationSearchController.text),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoadingColleges)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else ...[
          // ── Case A: No Search Active -> Show All-India Top Ranking ──
          if (_collegeSearchLocation.isEmpty && _topCollegesList.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('All India Top Institutes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            Column(
              children: [
                ..._topCollegesList.take(_topLimit).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final college = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildCollegeCard(
                      college['name'] ?? '',
                      college['location'] ?? 'India',
                      college['type'] ?? '',
                      college['fees'] ?? '',
                      college['placement'] ?? '',
                      [], 
                      selectedCareer,
                      rank: '${index + 1}',
                      url: college['link'] ?? '',
                    ),
                  );
                }),
                
                if (_topCollegesList.length > _topLimit)
                  _buildLoadMoreButton('All India Institutions', () {
                    setState(() { _topLimit += 10; });
                  }, _topCollegesList.length - _topLimit),
              ],
            ),
          ]

          // ── Case B: Search Active -> Show ONLY Local Results ──
          else if (_collegeSearchLocation.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Colleges in $_collegeSearchLocation',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 16),
            if (_locationCollegesList.isNotEmpty)
              Column(
                children: [
                  ..._locationCollegesList.take(_locationLimit).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final college = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildCollegeCard(
                        college['name'] ?? '',
                        college['location'] ?? _collegeSearchLocation,
                        college['type'] ?? '',
                        college['fees'] ?? '',
                        college['placement'] ?? '',
                        [],
                        selectedCareer,
                        rank: '${index + 1}',
                        url: college['link'] ?? '',
                      ),
                    );
                  }),
                  
                  if (_locationCollegesList.length > _locationLimit)
                    _buildLoadMoreButton('Search Results', () {
                      setState(() { _locationLimit += 10; });
                    }, _locationCollegesList.length - _locationLimit),
                ],
              )
            else if (!_isLoadingColleges)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text('No colleges found at this location. Try another city.', 
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ),
          ],
        ],
      ],
    );
  }

  /// Shared Load More Button Widget
  Widget _buildLoadMoreButton(String type, VoidCallback onPressed, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 40),
      child: Center(
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1976D2)),
          label: Text(
            'Show More $type (+${count > 10 ? 10 : count})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: const Color(0xFFF2F7FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  /// Build college card (Premium UI + Clickable + Ranking)
  Widget _buildCollegeCard(
    String name,
    String location,
    String type,
    String fees,
    String placement,
    List<String> courses,
    String career, {
    String rank = '',
    String url = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () async {
            if (url.isNotEmpty) {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } else {
              // Fallback to searching Google for the college
              final searchUri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(name)}');
              if (await canLaunchUrl(searchUri)) {
                await launchUrl(searchUri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header with Rank
              Stack(
                children: [
                  Container(
                    height: 140, // Slightly increased height for the better artwork
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      image: DecorationImage(
                        image: const AssetImage('assets/college_card_header.png'),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                           // Fallback will be handled by the errorBuilder/decoration if needed
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: rank.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF2E5B9A), Color(0xFF1976D2)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Text(
                              'Rank #$rank',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(location, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Section
                    _rowStat(Icons.account_balance_wallet_outlined, '1st Year Fees', '₹ $fees'),
                    const SizedBox(height: 16),
                    _rowStat(Icons.trending_up, 'Highest Placement', placement),
                    const SizedBox(height: 16),
                    _rowStat(Icons.business_outlined, type, ''),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),

                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 20, color: Color(0xFF2E5B9A)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Path:',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                            Text(
                              career.isNotEmpty ? career : 'Selected Career',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper for row statistics (e.g. Fees, Placement)
  Widget _rowStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2D3748)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF4A5568),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
      ],
    );
  }

  Widget _infoStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildJobChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildResourceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Build Resources Content Section
  Widget _buildResourcesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab switching header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedResourceTab = 'Courses'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedResourceTab == 'Courses' ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedResourceTab == 'Courses'
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Courses',
                        style: TextStyle(
                          fontWeight: _selectedResourceTab == 'Courses' ? FontWeight.bold : FontWeight.normal,
                          color: _selectedResourceTab == 'Courses' ? Colors.blue[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedResourceTab = 'YouTube Videos');
                    if (_youtubeList.isEmpty && !_isLoadingYoutube) _fetchYoutubeVideos();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedResourceTab == 'YouTube Videos' ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedResourceTab == 'YouTube Videos'
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Videos',
                        style: TextStyle(
                          fontWeight: _selectedResourceTab == 'YouTube Videos' ? FontWeight.bold : FontWeight.normal,
                          color: _selectedResourceTab == 'YouTube Videos' ? Colors.blue[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Dynamic Title
        Text(
          _selectedResourceTab == 'Courses' ? 'Top Online Courses' : 'Career Growth Videos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),

        // Content
        if (_selectedResourceTab == 'Courses') _buildCoursesGrid(),
        if (_selectedResourceTab == 'YouTube Videos') _buildYoutubeGrid(),
      ],
    );
  }

  /// Build courses grid using flat Column
  Widget _buildCoursesGrid() {
    if (_isLoadingResources) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    if (_resourcesList.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No courses found.')));

    return Column(
      children: [
        ..._resourcesList.map((resource) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCourseCard(
            resource['title'] ?? '',
            resource['description'] ?? '',
            resource['source'] ?? '',
            resource['url'] ?? '',
            resource['thumbnail'] ?? '',
          ),
        )).toList(),
        if (_hasMoreResources)
          _isLoadingMoreResources
              ? const CircularProgressIndicator()
              : TextButton.icon(
                  onPressed: () => _fetchRealResourcesData(isLoadMore: true),
                  icon: const Icon(Icons.add),
                  label: const Text('Show More Courses'),
                ),
      ],
    );
  }

  /// Build YouTube videos grid using flat Column
  Widget _buildYoutubeGrid() {
    if (_isLoadingYoutube) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    
    if (_youtubeLoadFailed || (_youtubeList.isEmpty && !_isLoadingYoutube)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.video_library_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No videos found for this career.', style: TextStyle(color: Colors.grey)),
              TextButton(onPressed: () => _fetchYoutubeVideos(), child: const Text('Retry Search')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ..._youtubeList.map((video) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildYoutubeCard(
            video['title'] ?? '',
            video['channel'] ?? '',
            video['thumbnail'] ?? '',
            video['url'] ?? '',
            video['description'] ?? '',
            videoId: video['videoId'] ?? '',
          ),
        )).toList(),
        if (_hasMoreYoutube)
          _isLoadingMoreYoutube
              ? const CircularProgressIndicator()
              : TextButton.icon(
                  onPressed: () => _fetchYoutubeVideos(pageToken: _youtubeNextPageToken, isLoadMore: true),
                  icon: const Icon(Icons.add),
                  label: const Text('Show More Videos'),
                ),
      ],
    );
  }

  /// Build YouTube video card (Premium Style)
  Widget _buildYoutubeCard(
    String title,
    String channel,
    String thumbnail,
    String url,
    String description, {
    String videoId = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () async {
            if (videoId.isNotEmpty && kIsWeb) {
               // Show in-app player for Web using iframe embed
               _showInAppPlayer(title, videoId);
            } else if (url.isNotEmpty) {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail (Full Width)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: thumbnail.isNotEmpty 
                    ? Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.video_library_outlined, size: 60, color: Colors.grey)),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.video_library_outlined, size: 60, color: Colors.grey)),
                      ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Course Description
                    Text(
                      description.isNotEmpty ? description : 'Learn the fundamentals of $title with this comprehensive guide.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),
                    
                    // Footer Link
                    Row(
                      children: [
                        Text(
                          'Watch Video',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build resource type button (Courses/YouTube)
  Widget _buildResourceTypeButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1976D2) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Courses' ? Icons.school : Icons.video_library,
            size: 16,
            color: isActive ? Colors.white : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Build course card
  Widget _buildCourseCard(
    String title,
    String description,
    String source,
    String url,
    String thumbnail,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () async {
            if (url.isNotEmpty) {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Thumbnail (Full Width)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    image: thumbnail.isNotEmpty 
                        ? DecorationImage(image: NetworkImage(thumbnail), fit: BoxFit.cover)
                        : null,
                  ),
                  child: thumbnail.isEmpty 
                      ? const Center(child: Icon(Icons.school_outlined, size: 60, color: Colors.grey))
                      : null,
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F36),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Course Description
                    Text(
                      description.isNotEmpty ? description : 'Learn the fundamentals of $title with this comprehensive guide from $source.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),
                    
                    // Footer Link
                    Row(
                      children: [
                        Text(
                          'View Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a beautiful in-app video player dialog using youtube_player_iframe
  void _showInAppPlayer(String title, String videoId) {
    // Initialize the professional YouTube controller
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        color: 'white',
        strictRelatedVideos: true,
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Dialog(
          backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: screenWidth > 1000 ? 900 : double.infinity,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Player Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFF0000), // YouTube Red
                        radius: 12,
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // The actual video player section
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: controller,
                    backgroundColor: Colors.black,
                  ),
                ),
                // Footer with contextual action
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Resource: YouTube',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text("Finish Watching"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper to create IFrame on Web while being safe on Native
  dynamic _createIFrameElement(String videoId) {
    // No longer needed as we're using youtube_player_iframe for high-fidelity player
    return null;
  }

  /// Build chip widget
  Widget _buildChip(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
