import 'package:image_picker/image_picker.dart';

enum MessageType { text, image }

class ChatMessage {
  final MessageType type;
  final String? text;
  final XFile? image;

  const ChatMessage.text(String this.text)
      : type = MessageType.text,
        image = null;

  const ChatMessage.image(XFile this.image)
      : type = MessageType.image,
        text = null;
}