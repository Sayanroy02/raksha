// ─────────────────────────────────────────────
//  chat_controller.dart
//  Manages the Safety Assistant AI chat.
//  Sends messages to backend /incidents/chat
//  and displays smart safety tips in response.
// ─────────────────────────────────────────────
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

/// A single chat message — either from the user or the AI
class ChatMessage {
  final String  text;
  final bool    isUser;      // true = right bubble, false = left bubble (AI)
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
  }) : time = DateTime.now();
}

class ChatController extends GetxController {
  final ApiService _api;
  ChatController(this._api);

  // ── State ────────────────────────────────────
  final RxList<ChatMessage> messages   = <ChatMessage>[].obs;
  final RxBool              isSending  = false.obs;
  final RxString            inputText  = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial greeting from the AI
    messages.add(ChatMessage(
      text: "Hi! 👋 I'm your AI safety assistant.\n"
          "You can ask me anything related to your safety, "
          "get safety tips, or report suspicious activity.",
      isUser: false,
    ));
  }

  // ── Send message ─────────────────────────────

  Future<void> sendMessage() async {
    final text = inputText.value.trim();
    if (text.isEmpty) return;

    // Add user message immediately
    messages.add(ChatMessage(text: text, isUser: true));
    inputText.value = '';
    isSending.value = true;

    try {
      final resp = await _api.dio.post(
        '/incidents/chat',
        data: {'message': text},
      );
      final reply = (resp.data as Map<String, dynamic>?)?['reply'] as String?
          ?? _fallbackReply(text);
      messages.add(ChatMessage(text: reply, isUser: false));
    } on DioException catch (_) {
      // If the backend is unreachable, give a helpful offline response
      messages.add(ChatMessage(text: _fallbackReply(text), isUser: false));
    } finally {
      isSending.value = false;
    }
  }

  // ── Fallback responses (offline / error) ────

  String _fallbackReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('follow') || lower.contains('stalking')) {
      return "If you feel someone is following you:\n\n"
          "1. Move to a crowded place immediately.\n"
          "2. Keep your phone ready.\n"
          "3. Share your live location.\n"
          "4. If in danger, press the SOS button.\n\n"
          "I'm here for you. Stay safe. 💙";
    }
    if (lower.contains('safe') || lower.contains('tip')) {
      return "Here are some quick safety tips:\n"
          "• Always share your route with trusted contacts.\n"
          "• Avoid poorly lit areas at night.\n"
          "• Keep your phone charged.\n"
          "• Trust your instincts — if something feels off, act.";
    }
    return "I'm here to help you stay safe. "
        "If you're in immediate danger, please press the SOS button. "
        "You can also ask me for safety tips or guidance.";
  }
}
