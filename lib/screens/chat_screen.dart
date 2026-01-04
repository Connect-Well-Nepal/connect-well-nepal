import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connect_well_nepal/models/chat_model.dart';
import 'package:connect_well_nepal/services/chat_service.dart';
import 'package:connect_well_nepal/services/database_service.dart';
import 'package:connect_well_nepal/providers/app_provider.dart';
import 'package:connect_well_nepal/utils/colors.dart';

/// ChatScreen - Individual chat conversation between doctor and patient
class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  void _markAsRead() {
    final userId = context.read<AppProvider>().currentUser?.id;
    if (userId != null) {
      _chatService.markMessagesAsRead(widget.conversation.id, userId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: user.id,
        senderName: user.name,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.watch<AppProvider>().currentUser;
    final otherName = widget.conversation.getOtherParticipantName(currentUser?.id ?? '');
    final otherImage = widget.conversation.getOtherParticipantImage(currentUser?.id ?? '');
    final isPatient = widget.conversation.isPatient(currentUser?.id ?? '');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryNavyBlue,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: otherImage != null ? NetworkImage(otherImage) : null,
              child: otherImage == null
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isPatient 
                        ? (widget.conversation.doctorSpecialty ?? 'Doctor')
                        : 'Patient',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'appointment') {
                _showAppointmentDialog();
              } else if (value == 'prescription' && !isPatient) {
                _showPrescriptionDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'appointment',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 12),
                    Text('Schedule Appointment'),
                  ],
                ),
              ),
              if (!isPatient)
                const PopupMenuItem(
                  value: 'prescription',
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 20),
                      SizedBox(width: 12),
                      Text('Send Prescription'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.conversation.id),
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
                        Text('Error loading messages'),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.id;
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(message.timestamp, messages[index + 1].timestamp);

                    return Column(
                      children: [
                        if (showDate) _buildDateHeader(message.timestamp),
                        _buildMessageBubble(message, isMe, isDark),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File attachment coming soon!')),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavyBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primaryNavyBlue
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Special message types
            if (message.type == MessageType.prescription) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: isMe ? Colors.white70 : AppColors.primaryNavyBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Prescription',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white70 : AppColors.primaryNavyBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ] else if (message.type == MessageType.appointment) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isMe ? Colors.white70 : AppColors.primaryNavyBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Appointment',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white70 : AppColors.primaryNavyBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            // Message content
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            
            // Timestamp
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white60 : Colors.grey[500],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.lightBlueAccent : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String appointmentType = 'Video Consultation';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Appointment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date picker
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) {
                          setModalState(() => selectedDate = date);
                        }
                      },
                    ),
                    
                    // Time picker
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setModalState(() => selectedTime = time);
                        }
                      },
                    ),
                    
                    // Type selector
                    ListTile(
                      leading: const Icon(Icons.medical_services),
                      title: const Text('Type'),
                      subtitle: DropdownButton<String>(
                        value: appointmentType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ['Video Consultation', 'Voice Call', 'In-Person Visit']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => appointmentType = value);
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final user = context.read<AppProvider>().currentUser;
                          if (user == null) return;
                          
                          final appointmentDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          
                          // Determine appointment type
                          String appointmentTypeCode = 'chat';
                          if (appointmentType.toLowerCase().contains('video')) {
                            appointmentTypeCode = 'video';
                          } else if (appointmentType.toLowerCase().contains('voice') || 
                                     appointmentType.toLowerCase().contains('call')) {
                            appointmentTypeCode = 'voice';
                          }
                          
                          // Send appointment message in chat
                          await _chatService.sendAppointmentMessage(
                            conversationId: widget.conversation.id,
                            senderId: user.id,
                            senderName: user.name,
                            appointmentTime: appointmentDateTime,
                            appointmentType: appointmentType,
                          );
                          
                          // Also create actual appointment in database
                          try {
                            final appointmentData = {
                              'patientId': widget.conversation.patientId,
                              'patientName': widget.conversation.patientName,
                              'doctorId': widget.conversation.doctorId,
                              'doctorName': widget.conversation.doctorName,
                              'doctorPhotoUrl': widget.conversation.doctorImage,
                              'doctorSpecialty': widget.conversation.doctorSpecialty ?? 'General Physician',
                              'dateTime': appointmentDateTime.toIso8601String(),
                              'appointmentTime': appointmentDateTime.toIso8601String(),
                              'type': appointmentTypeCode,
                              'status': 'pending',
                              'symptoms': 'Appointment requested via chat',
                              'consultationFee': 500.0, // Default fee
                            };
                            
                            final databaseService = DatabaseService();
                            await databaseService.createAppointment(appointmentData);
                          } catch (e) {
                            debugPrint('Error creating appointment from chat: $e');
                            // Don't show error to user, message was sent successfully
                          }
                          
                          if (!mounted) return;
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Appointment request sent!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Send Request'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrescriptionDialog() {
    final prescriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Prescription',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prescriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter prescription details...\n\nMedicine name, dosage, duration, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (prescriptionController.text.trim().isEmpty) return;
                      
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final user = context.read<AppProvider>().currentUser;
                      if (user == null) return;
                      
                      await _chatService.sendPrescription(
                        conversationId: widget.conversation.id,
                        doctorId: user.id,
                        doctorName: user.name,
                        prescriptionDetails: prescriptionController.text.trim(),
                      );
                      
                      if (!mounted) return;
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Prescription sent!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Send Prescription'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
