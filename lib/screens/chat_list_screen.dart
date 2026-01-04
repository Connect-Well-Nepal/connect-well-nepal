import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/models/chat_model.dart';
import 'package:connect_well_nepal/services/chat_service.dart';
import 'package:connect_well_nepal/services/database_service.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/screens/chat_screen.dart';
import 'package:connect_well_nepal/utils/colors.dart';
import 'package:connect_well_nepal/models/user_model.dart';

/// ChatListScreen - Shows all conversations for the current user
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.watch<AppProvider>().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login to view messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _chatService.getConversations(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text('Error loading conversations'),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser.role == UserRole.patient
                        ? 'Book an appointment with a doctor to start chatting'
                        : 'Wait for patients to book appointments with you',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (currentUser.role == UserRole.patient)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Find Doctors'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(conversation, currentUser.id, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(currentUser),
        backgroundColor: AppColors.primaryNavyBlue,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationTile(
    ConversationModel conversation,
    String currentUserId,
    bool isDark,
  ) {
    final otherName = conversation.getOtherParticipantName(currentUserId);
    final otherImage = conversation.getOtherParticipantImage(currentUserId);
    final isPatient = conversation.isPatient(currentUserId);

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text('Are you sure you want to delete this conversation? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _chatService.deleteConversation(conversation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
          backgroundImage: otherImage != null ? NetworkImage(otherImage) : null,
          child: otherImage == null
              ? Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppColors.primaryNavyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherName,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            if (conversation.lastMessageTime != null)
              Text(
                _formatTime(conversation.lastMessageTime!),
                style: TextStyle(
                  fontSize: 12,
                  color: conversation.unreadCount > 0
                      ? AppColors.primaryNavyBlue
                      : (isDark ? Colors.white38 : AppColors.textSecondary),
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPatient && conversation.doctorSpecialty != null)
                    Text(
                      conversation.doctorSpecialty!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryNavyBlue,
                      ),
                    ),
                  Text(
                    conversation.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount > 99 
                      ? '99+' 
                      : conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversation: conversation),
            ),
          );
        },
      ),
    );
  }

  void _showNewChatDialog(UserModel currentUser) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> contacts = [];
    
    try {
      if (currentUser.role == UserRole.patient) {
        // Get all verified doctors from database
        final doctors = await _databaseService.getVerifiedDoctors();
        contacts = doctors.map((doctor) => {
          'id': doctor.id,
          'name': doctor.name,
          'specialty': doctor.specialty ?? 'General Physician',
          'image': doctor.profileImageUrl,
        }).toList();
        
        // If no doctors found, use sample data as fallback
        if (contacts.isEmpty) {
          contacts = [
            {'id': 'doc_1', 'name': 'Dr. Rajesh Sharma', 'specialty': 'General Physician'},
            {'id': 'doc_2', 'name': 'Dr. Anjali Thapa', 'specialty': 'Cardiologist'},
            {'id': 'doc_3', 'name': 'Dr. Prakash Paudel', 'specialty': 'Pediatrician'},
            {'id': 'doc_4', 'name': 'Dr. Sunita Gurung', 'specialty': 'Dermatologist'},
          ];
        }
      } else {
        // For doctors: Get patients who have appointments with this doctor
        final appointments = await _databaseService.getUserAppointments(
          currentUser.id,
          isDoctor: true,
        );
        
        // Extract unique patient IDs
        final patientIds = appointments
            .map((apt) => apt['patientId'] as String?)
            .whereType<String>()
            .toSet()
            .toList();
        
        // Get patient details
        for (final patientId in patientIds) {
          try {
            final patientDoc = await _databaseService.getUser(patientId);
            if (patientDoc != null) {
              contacts.add({
                'id': patientDoc.id,
                'name': patientDoc.name,
                'info': 'Patient',
                'image': patientDoc.profileImageUrl,
              });
            }
          } catch (e) {
            debugPrint('Error fetching patient $patientId: $e');
          }
        }
        
        // If no patients found, use sample data as fallback
        if (contacts.isEmpty) {
          contacts = [
            {'id': 'pat_1', 'name': 'Ramesh Adhikari', 'info': 'Patient'},
            {'id': 'pat_2', 'name': 'Sita Sharma', 'info': 'Patient'},
            {'id': 'pat_3', 'name': 'Krishna Tamang', 'info': 'Patient'},
          ];
        }
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      // Use sample data as fallback
      contacts = currentUser.role == UserRole.patient
          ? [
              {'id': 'doc_1', 'name': 'Dr. Rajesh Sharma', 'specialty': 'General Physician'},
              {'id': 'doc_2', 'name': 'Dr. Anjali Thapa', 'specialty': 'Cardiologist'},
              {'id': 'doc_3', 'name': 'Dr. Prakash Paudel', 'specialty': 'Pediatrician'},
              {'id': 'doc_4', 'name': 'Dr. Sunita Gurung', 'specialty': 'Dermatologist'},
            ]
          : [
              {'id': 'pat_1', 'name': 'Ramesh Adhikari', 'info': 'Patient'},
              {'id': 'pat_2', 'name': 'Sita Sharma', 'info': 'Patient'},
              {'id': 'pat_3', 'name': 'Krishna Tamang', 'info': 'Patient'},
            ];
    } finally {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentUser.role == UserRole.patient
                            ? 'Select a Doctor'
                            : 'Select a Patient',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: contacts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: isDark ? Colors.white24 : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No contacts available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentUser.role == UserRole.patient
                                      ? 'No verified doctors found'
                                      : 'No patients with appointments found',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryNavyBlue.withValues(alpha: 0.1),
                          backgroundImage: contact['image'] != null 
                              ? NetworkImage(contact['image']!) 
                              : null,
                          child: contact['image'] == null
                              ? Text(
                                  contact['name']![0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.primaryNavyBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          contact['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          contact['specialty'] ?? contact['info'] ?? '',
                          style: TextStyle(
                            color: AppColors.primaryNavyBlue,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primaryNavyBlue,
                        ),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          
                          if (!mounted) return;
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          
                          try {
                            ConversationModel conversation;
                            
                            if (currentUser.role == UserRole.patient) {
                              conversation = await _chatService.getOrCreateConversation(
                                patientId: currentUser.id,
                                patientName: currentUser.name,
                                patientImage: currentUser.profileImageUrl,
                                doctorId: contact['id']!,
                                doctorName: contact['name']!,
                                doctorSpecialty: contact['specialty'] ?? contact['info'],
                              );
                            } else {
                              conversation = await _chatService.getOrCreateConversation(
                                patientId: contact['id']!,
                                patientName: contact['name']!,
                                patientImage: contact['image'],
                                doctorId: currentUser.id,
                                doctorName: currentUser.name,
                                doctorImage: currentUser.profileImageUrl,
                                doctorSpecialty: currentUser.specialty,
                              );
                            }
                            
                            if (!mounted) return;
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(conversation: conversation),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error starting chat: $e')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (diff.inDays > 0) {
      return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
