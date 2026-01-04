import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// AI Assistant Screen - Helps users navigate app features
///
/// Features:
/// - Chat-like interface
/// - Quick action buttons for common questions
/// - Context-aware responses based on user role
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final appProvider = context.read<AppProvider>();
    final userName = appProvider.currentUser?.firstName ?? 'there';
    final isDoctor = appProvider.isDoctor || appProvider.isCareProvider;

    String welcomeText;
    if (isDoctor) {
      welcomeText = "Hello Dr. $userName! 👋\n\nI'm your Connect Well assistant. I can help you with:\n\n"
          "• Managing your appointments\n"
          "• Setting up your profile\n"
          "• Understanding consultation features\n"
          "• Navigating the dashboard\n\n"
          "How can I help you today?";
    } else {
      welcomeText = "Hello $userName! 👋\n\nI'm your Connect Well assistant. I can help you with:\n\n"
          "• Finding nearby healthcare\n"
          "• Booking appointments\n"
          "• Self-care resources\n"
          "• Understanding app features\n\n"
          "What would you like to know?";
    }

    _messages.add(ChatMessage(
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI thinking delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: _generateResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateResponse(String query) {
    final lowerQuery = query.toLowerCase();
    final appProvider = context.read<AppProvider>();
    final isDoctor = appProvider.isDoctor || appProvider.isCareProvider;

    // Appointment related
    if (lowerQuery.contains('appointment') || lowerQuery.contains('book') || lowerQuery.contains('schedule')) {
      if (isDoctor) {
        return "📅 **Managing Appointments**\n\n"
            "As a healthcare provider, you can:\n\n"
            "1. **View Schedule** - Check your 'Schedule' tab to see upcoming appointments\n"
            "2. **Accept/Decline** - Manage patient requests from your dashboard\n"
            "3. **Set Availability** - Update your available hours in Profile settings\n\n"
            "Would you like to know more about any of these features?";
      } else {
        return "📅 **Booking Appointments**\n\n"
            "To book an appointment:\n\n"
            "1. Go to **Home** and browse available doctors\n"
            "2. Tap on a doctor to view their profile\n"
            "3. Select a time slot and confirm your booking\n\n"
            "You can view all your appointments in the **Appointments** tab.\n\n"
            "Need help finding a specific type of doctor?";
      }
    }

    // Self-care related
    if (lowerQuery.contains('self-care') || lowerQuery.contains('selfcare') || 
        lowerQuery.contains('meditation') || lowerQuery.contains('wellness')) {
      return "🧘 **Self-Care Hub**\n\n"
          "Access our self-care features by tapping the **Self-Care** button on the home screen:\n\n"
          "• **Meditation** - Guided breathing exercises (4-7-8 technique)\n"
          "• **Exercise** - Quick workout routines\n"
          "• **Nutrition** - Healthy eating tips\n"
          "• **Mental Health** - Stress management resources\n\n"
          "Regular self-care can significantly improve your overall health! 💪";
    }

    // Nearby healthcare
    if (lowerQuery.contains('hospital') || lowerQuery.contains('clinic') || 
        lowerQuery.contains('nearby') || lowerQuery.contains('healthcare')) {
      return "🏥 **Nearby Healthcare**\n\n"
          "On your home screen, scroll down to see **Nearby Healthcare** facilities:\n\n"
          "• Clinics and hospitals sorted by distance\n"
          "• Ratings and reviews from other patients\n"
          "• Real-time availability status\n\n"
          "Make sure location services are enabled for accurate results.\n\n"
          "Looking for a specific specialty or facility?";
    }

    // Profile related
    if (lowerQuery.contains('profile') || lowerQuery.contains('account') || lowerQuery.contains('edit')) {
      if (isDoctor) {
        return "👤 **Your Doctor Profile**\n\n"
            "Your profile is crucial for attracting patients! Update it by:\n\n"
            "1. Tap **Profile** in the bottom navigation\n"
            "2. Edit your specialty, qualifications, and bio\n"
            "3. Add your consultation fees\n"
            "4. Set your available hours\n"
            "5. Upload a professional photo\n\n"
            "A complete profile increases patient trust! ⭐";
      } else {
        return "👤 **Your Profile**\n\n"
            "Keep your profile updated for better care:\n\n"
            "1. Tap **Profile** in the bottom navigation\n"
            "2. Add your medical history and allergies\n"
            "3. Set emergency contacts\n"
            "4. Update your profile picture\n\n"
            "This helps doctors provide better care during consultations.";
      }
    }

    // Settings related
    if (lowerQuery.contains('setting') || lowerQuery.contains('dark') || 
        lowerQuery.contains('notification') || lowerQuery.contains('theme')) {
      return "⚙️ **App Settings**\n\n"
          "Customize your experience in **Settings** (gear icon in Profile):\n\n"
          "• **Dark Mode** - Easy on the eyes at night\n"
          "• **Notifications** - Control appointment reminders\n"
          "• **Language** - Choose English or Nepali\n"
          "• **Privacy** - Manage your data preferences\n\n"
          "Is there a specific setting you'd like to adjust?";
    }

    // Consultation/Video call
    if (lowerQuery.contains('video') || lowerQuery.contains('call') || 
        lowerQuery.contains('consult') || lowerQuery.contains('chat')) {
      return "📹 **Consultations**\n\n"
          "Connect Well Nepal offers multiple consultation types:\n\n"
          "• **Video Call** - Face-to-face virtual consultation\n"
          "• **Voice Call** - Audio-only option for convenience\n"
          "• **Chat** - Text-based consultation\n\n"
          "After booking an appointment, you'll receive a link to join the consultation at the scheduled time.\n\n"
          "Need help with a specific consultation type?";
    }

    // Doctor verification
    if (isDoctor && (lowerQuery.contains('verif') || lowerQuery.contains('credential'))) {
      return "✅ **Doctor Verification**\n\n"
          "Your verification status appears on your dashboard:\n\n"
          "• **Pending** - We're reviewing your credentials\n"
          "• **Verified** - You can accept patient appointments\n\n"
          "Verification typically takes 24-48 hours. Ensure your:\n"
          "• License number is correct\n"
          "• Qualifications are up to date\n"
          "• Profile is complete\n\n"
          "Questions about verification? Contact support@connectwell.np";
    }

    // Help/Support
    if (lowerQuery.contains('help') || lowerQuery.contains('support') || lowerQuery.contains('contact')) {
      return "🆘 **Need More Help?**\n\n"
          "I'm here to assist! You can also:\n\n"
          "• **Email**: support@connectwell.np\n"
          "• **Phone**: +977-1-XXXXXXX\n"
          "• **FAQ**: Check Settings > Help & Support\n\n"
          "Or ask me any specific question about using the app!";
    }

    // Greeting
    if (lowerQuery.contains('hello') || lowerQuery.contains('hi') || lowerQuery.contains('hey')) {
      return "Hello! 👋 Great to chat with you!\n\n"
          "I can help you with:\n"
          "• Booking appointments\n"
          "• Finding nearby healthcare\n"
          "• Self-care tips\n"
          "• App features\n\n"
          "Just ask away!";
    }

    // Thank you
    if (lowerQuery.contains('thank') || lowerQuery.contains('thanks')) {
      return "You're welcome! 😊\n\n"
          "I'm always here to help. Feel free to ask if you have more questions!\n\n"
          "Stay healthy! 💚";
    }

    // Default response
    return "I understand you're asking about \"$query\".\n\n"
        "I can help you with:\n\n"
        "• 📅 Appointments & Booking\n"
        "• 🏥 Nearby Healthcare\n"
        "• 🧘 Self-Care Features\n"
        "• 👤 Profile Management\n"
        "• ⚙️ App Settings\n"
        "• 📹 Video Consultations\n\n"
        "Try asking about any of these topics, or rephrase your question!";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appProvider = context.watch<AppProvider>();
    final isDoctor = appProvider.isDoctor || appProvider.isCareProvider;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1B263B) : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: AppColors.primaryNavyBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Assistant',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primaryNavyBlue,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Powered by AI',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            tooltip: 'New conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip('📅 Appointments', 'How do I book an appointment?'),
                  _buildQuickChip('🏥 Nearby Healthcare', 'Show me nearby hospitals'),
                  _buildQuickChip('🧘 Self-Care', 'Tell me about self-care features'),
                  if (isDoctor) _buildQuickChip('✅ Verification', 'Check my verification status'),
                  _buildQuickChip('⚙️ Settings', 'How do I change settings?'),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                return _buildMessageBubble(_messages[index], isDark);
              },
            ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.backgroundOffWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavyBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String query) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : AppColors.primaryNavyBlue,
          ),
        ),
        backgroundColor: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.primaryNavyBlue.withValues(alpha: 0.1),
        side: BorderSide(
          color: isDark 
              ? Colors.white24 
              : AppColors.primaryNavyBlue.withValues(alpha: 0.3),
        ),
        onPressed: () => _sendMessage(query),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: AppColors.primaryNavyBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primaryNavyBlue
                    : (isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textPrimary),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondaryCrimsonRed,
              child: Text(
                context.read<AppProvider>().currentUser?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: AppColors.primaryNavyBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryNavyBlue.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
