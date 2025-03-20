import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gemini_ai.dart'; // Ensure this matches your original import

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isLoading = false;
  double _fontSize = 18.0;
  double _speechRate = 0.8; // Add this
  double _volume = 1.0; // Add this

  String _currentLanguage = 'en';
  final Map<String, Map<String, String>> _languageData = {
    'en': {
      'name': 'English',
      'code': 'en-US',
      'welcome': "Hello! I'm your AI helper. How can I assist you today?",
      'thinking': 'Thinking...',
      'settings': 'Settings',
      'textSize': 'Text Size',
      'speechRate': 'Speech Rate',
      'volume': 'Volume',
      'cancel': 'Cancel',
      'save': 'Save',
      'tapToHear': '(Tap to hear this read aloud)',
      'askAnything': 'Ask me anything...',
    },
    'hi': {
      'name': 'हिंदी',
      'code': 'hi-IN',
      'welcome': "नमस्ते! मैं आपका AI सहायक हूं। मैं आपकी कैसे मदद कर सकता हूं?",
      'thinking': 'सोच रहा हूं...',
      'settings': 'सेटिंग्स',
      'textSize': 'टेक्स्ट का आकार',
      'speechRate': 'बोलने की गति',
      'volume': 'आवाज़',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'tapToHear': '(सुनने के लिए टैप करें)',
      'askAnything': 'कुछ भी पूछें...',
    },
    'ta': {
      'name': 'தமிழ்',
      'code': 'ta-IN',
      'welcome': "வணக்கம்! நான் உங்கள் AI உதவியாளர். நான் உங்களுக்கு எப்படி உதவ முடியும்?",
      'thinking': 'யோசிக்கிறேன்...',
      'settings': 'அமைப்புகள்',
      'textSize': 'எழுத்து அளவு',
      'speechRate': 'பேச்சு வேகம்',
      'volume': 'ஒலி அளவு',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'tapToHear': '(கேட்க தட்டவும்)',
      'askAnything': 'எதையும் கேளுங்கள்...',
    },
    'te': {
      'name': 'తెలుగు',
      'code': 'te-IN',
      'welcome': "నమస్కారం! నేను మీ AI సహాయకుడిని. నేను మీకు ఎలా సహాయం చేయగలను?",
      'thinking': 'ఆలోచిస్తున్నాను...',
      'settings': 'సెట్టింగ్‌లు',
      'textSize': 'టెక్స్ట్ పరిమాణం',
      'speechRate': 'మాట్లాడే వేగం',
      'volume': 'వాల్యూమ్',
      'cancel': 'రద్దు చేయి',
      'save': 'సేవ్ చేయి',
      'tapToHear': '(వినడానికి నొక్కండి)',
      'askAnything': 'ఏదైనా అడగండి...',
    },
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadSettings();
    _addWelcomeMessage();
  }

  // Add a welcome message
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(Message(
        content: _languageData[_currentLanguage]!['welcome']!,
        isUser: false,
      ));
    });
  }

  // Update welcome message
  void _updateWelcomeMessage() {
    if (_messages.isNotEmpty) {
      setState(() {
        _messages[0] = Message(
          content: _languageData[_currentLanguage]!['welcome']!,
          isUser: false,
        );
      });
    }
  }

  // Initialize speech recognition
  void _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (error) => print('onError: $error'),
      );
      if (!available) {
        print('The user has denied the use of speech recognition.');
      }
    } catch (e) {
      debugPrint('Speech recognition initialization error: $e');
      // Continue even if speech recognition fails
    }
  }

  // Initialize text-to-speech
  void _initTts() async {
    try {
      await _flutterTts.setLanguage(_languageData[_currentLanguage]!['code']!);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(1.0);
      
      var languages = await _flutterTts.getLanguages;
      debugPrint('Available languages: $languages');
    } catch (e) {
      debugPrint('Text-to-speech initialization error: $e');
      // Continue even if TTS fails
    }
  }

  // Load user settings (font size)
  void _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _fontSize = prefs.getDouble('fontSize') ?? 18.0;
        _speechRate = prefs.getDouble('speechRate') ?? 0.8;
        _volume = prefs.getDouble('volume') ?? 1.0;
        _currentLanguage = prefs.getString('language') ?? 'en';
      });
      _initTts();
    } catch (e) {
      debugPrint('Settings loading error: $e');
    }
  }

  // Save user settings (font size, speech rate, volume)
  void _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontSize', _fontSize);
      await prefs.setDouble('speechRate', _speechRate); // Save speech rate
      await prefs.setDouble('volume', _volume); // Save volume
      await prefs.setString('language', _currentLanguage);
    } catch (e) {
      debugPrint('Settings saving error: $e');
    }
  }

  // Handle speech recognition
  void _listen() async {
    if (!_isListening) {
      bool available = false;
      try {
        available = await _speechToText.initialize();
      } catch (e) {
        debugPrint('Speech recognition error: $e');
      }

      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 5),
          partialResults: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  // Speak text aloud
  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Text-to-speech error: $e');
    }
  }

  // Send message to Gemini and get response using your existing service
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(Message(content: text, isUser: true));
      _isLoading = true;
    });

    try {
      // Modify the elderlySupportPrompt in _handleSubmitted
      final elderlySupportPrompt = '''
Please respond to this message from an elderly person who may have limited technical knowledge.
Respond in ${_languageData[_currentLanguage]!['name']} language only.
- Use simple, clear language without jargon
- Be patient and respectful
- Give concise but complete answers
- Use short paragraphs with simple sentences
- Be extra helpful with technology questions

The person asks: "$text"
''';

      // Use your existing Gemini service
      String? responseText;
      try {
        responseText = await generateResponse(elderlySupportPrompt);
      } catch (e) {
        debugPrint('Gemini API error: $e');
        throw e; // Re-throw to be caught by outer catch
      }

      if (responseText == null || responseText.isEmpty) {
        throw Exception("Empty response from Gemini");
      }

      // Extract just the response part, not the prompt instructions
      String cleanResponse = responseText;

      // Remove common patterns that might be in the response due to prompt echoing
      final patterns = [
        RegExp(r'The person asks: ".*"'),
        RegExp(r'The elderly person asks: ".*"'),
        text,
      ];

      for (var pattern in patterns) {
        cleanResponse = cleanResponse.replaceAll(pattern, '');
      }

      // Clean up any remaining artifacts
      cleanResponse = cleanResponse.trim();

      // If the response became too clean (empty), use original
      if (cleanResponse.isEmpty) {
        cleanResponse = responseText;
      }

      setState(() {
        _messages.add(Message(content: cleanResponse, isUser: false));
        _isLoading = false;
      });

      // Auto-read the response aloud
      _speak(cleanResponse);
    } catch (e) {
      setState(() {
        _messages.add(Message(
          content:
              "I'm sorry, I encountered a problem generating a response. Please try again or ask something different.",
          isUser: false,
        ));
        _isLoading = false;
      });
      debugPrint('Error in handleSubmitted: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your AI Helper',
          style: TextStyle(fontSize: _fontSize + 4),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            iconSize: 28,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  fontSize: _fontSize,
                  onTap: () => _speak(message.content),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(
                    _languageData[_currentLanguage]!['thinking']!,
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ],
              ),
            ),
          Divider(height: 1.0),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                  iconSize: 28,
                  color: _isListening ? Colors.red : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: _languageData[_currentLanguage]!['askAnything'],
                      hintStyle: TextStyle(fontSize: _fontSize),
                      contentPadding: EdgeInsets.all(16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text),
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempFontSize = _fontSize;
        double tempSpeechRate = _speechRate;
        double tempVolume = _volume; // Temporary variable to hold the volume

        return AlertDialog(
          title: Text(
            _languageData[_currentLanguage]!['settings']!,
            style: TextStyle(fontSize: _fontSize + 4),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Language / भाषा / மொழி / భాష', 
                      style: TextStyle(fontSize: _fontSize)),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: DropdownButton<String>(
                      value: _currentLanguage,
                      isExpanded: true,
                      items: _languageData.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value['name']!,
                            style: TextStyle(fontSize: _fontSize),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _currentLanguage = newValue;
                          });
                          _initTts(); // Reinitialize TTS with new language
                          _updateWelcomeMessage(); // Update welcome message
                          _saveSettings(); // Save language preference
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Text('Text Size', style: TextStyle(fontSize: _fontSize)),
                  Slider(
                    value: tempFontSize,
                    min: 16.0,
                    max: 32.0,
                    divisions: 8,
                    label: tempFontSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempFontSize = value;
                      });
                    },
                  ),
                  Text(
                    'Sample Text',
                    style: TextStyle(fontSize: tempFontSize),
                  ),
                  SizedBox(height: 16),
                  Text('Speech Rate', style: TextStyle(fontSize: _fontSize)),
                  Slider(
                    value: tempSpeechRate,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    label: tempSpeechRate.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        tempSpeechRate = value;
                      });
                    },
                  ),
                  Text(
                    'Speech Rate: ${tempSpeechRate.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                  SizedBox(height: 16),
                  Text('Volume', style: TextStyle(fontSize: _fontSize)),
                  Slider(
                    value: tempVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: tempVolume.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() {
                        tempVolume = value;
                      });
                    },
                  ),
                  Text(
                    'Volume: ${tempVolume.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(fontSize: _fontSize)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(fontSize: _fontSize)),
              onPressed: () {
                setState(() {
                  _fontSize =
                      tempFontSize; // Update the main state with the new font size
                  _speechRate = tempSpeechRate; // Update the speech rate
                  _volume = tempVolume; // Update the volume
                  _flutterTts
                      .setSpeechRate(_speechRate); // Apply the new speech rate
                  _flutterTts.setVolume(_volume); // Apply the new volume
                });
                _saveSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class Message {
  final String content;
  final bool isUser;

  Message({required this.content, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final double fontSize;
  final VoidCallback onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              child: Icon(Icons.assistant),
              backgroundColor: Colors.blue[100],
            ),
          if (!message.isUser) SizedBox(width: 8),
          Flexible(
            child: InkWell(
              onTap: onTap, // Tap to hear the message read aloud
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: message.isUser ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(fontSize: fontSize),
                    ),
                    if (!message.isUser)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '(Tap to hear this read aloud)',
                          style: TextStyle(
                            fontSize: fontSize - 4,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              child: Icon(Icons.person),
              backgroundColor: Colors.blue[300],
            ),
        ],
      ),
    );
  }
}