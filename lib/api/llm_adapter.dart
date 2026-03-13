import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// LLM 제공자 타입
enum LLMProviderType {
  openAI,
  anthropic,
  google,
  local,
}

/// 메시지 역할
enum ChatMessageRole {
  system,
  user,
  assistant,
}

/// 채팅 메시지
class ChatMessage {
  final ChatMessageRole role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
      };
}

/// LLM 응답
class LLMResponse {
  final String content;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  LLMResponse({
    required this.content,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
  });
}

/// LLM 어댑터 인터페이스
abstract class LLMAdapter {
  Future<LLMResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  });

  Future<void> streamChat({
    required List<ChatMessage> messages,
    required Function(String chunk) onChunk,
    required Function(LLMResponse) onComplete,
    String? model,
    int? maxTokens,
    double? temperature,
  });
}

/// OpenAI 어댑터
class OpenAIAdapter implements LLMAdapter {
  final String apiKey;
  final String baseUrl;

  OpenAIAdapter({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
  });

  @override
  Future<LLMResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model ?? 'gpt-3.5-turbo',
        'messages': messages.map((m) => m.toJson()).toList(),
        'max_tokens': maxTokens ?? 150,
        'temperature': temperature ?? 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choice = data['choices'][0];
      final usage = data['usage'];

      return LLMResponse(
        content: choice['message']['content'],
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
        totalTokens: usage['total_tokens'],
      );
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode}');
    }
  }

  @override
  Future<void> streamChat({
    required List<ChatMessage> messages,
    required Function(String chunk) onChunk,
    required Function(LLMResponse) onComplete,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    });
    request.body = jsonEncode({
      'model': model ?? 'gpt-3.5-turbo',
      'messages': messages.map((m) => m.toJson()).toList(),
      'max_tokens': maxTokens ?? 150,
      'temperature': temperature ?? 0.7,
      'stream': true,
    });

    final streamedResponse = await http.Client().send(request);
    final stream = streamedResponse.stream.transform(utf8.decoder);

    String fullContent = '';

    await for (final chunk in stream) {
      final lines = chunk.split('\n');

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);

          if (data == '[DONE]') {
            onComplete(LLMResponse(content: fullContent));
            return;
          }

          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];

            if (delta['content'] != null) {
              final content = delta['content'];
              fullContent += content;
              onChunk(content);
            }
          } catch (e) {
            // JSON 파싱 오류 무시
          }
        }
      }
    }
  }
}

/// Anthropic Claude 어댑터
class AnthropicAdapter implements LLMAdapter {
  final String apiKey;
  final String baseUrl;

  AnthropicAdapter({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1',
  });

  @override
  Future<LLMResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    final systemMessage = messages
        .where((m) => m.role == ChatMessageRole.system)
        .map((m) => m.content)
        .join('\n');

    final userMessages = messages
        .where((m) => m.role != ChatMessageRole.system)
        .map((m) => m.toJson())
        .toList();

    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model ?? 'claude-3-sonnet-20240229',
        'max_tokens': maxTokens ?? 150,
        'temperature': temperature ?? 0.7,
        'system': systemMessage,
        'messages': userMessages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return LLMResponse(
        content: data['content'][0]['text'],
        promptTokens: data['usage']['input_tokens'],
        completionTokens: data['usage']['output_tokens'],
        totalTokens: data['usage']['input_tokens'] + data['usage']['output_tokens'],
      );
    } else {
      throw Exception('Anthropic API Error: ${response.statusCode}');
    }
  }

  @override
  Future<void> streamChat({
    required List<ChatMessage> messages,
    required Function(String chunk) onChunk,
    required Function(LLMResponse) onComplete,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    // 스트리밍 구현 (생략)
    throw UnimplementedError('Streaming not yet implemented');
  }
}

/// Google Gemini 어댑터
class GoogleAdapter implements LLMAdapter {
  final String apiKey;
  final String baseUrl;

  GoogleAdapter({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  });

  @override
  Future<LLMResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/models/${model ?? "gemini-pro"}:generateContent?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': {
          'parts': messages
              .where((m) => m.role != ChatMessageRole.system)
              .map((m) => {'text': m.content})
              .toList(),
        },
        'generationConfig': {
          'temperature': temperature ?? 0.7,
          'maxOutputTokens': maxTokens ?? 150,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return LLMResponse(
        content: data['candidates'][0]['content']['parts'][0]['text'],
      );
    } else {
      throw Exception('Google API Error: ${response.statusCode}');
    }
  }

  @override
  Future<void> streamChat({
    required List<ChatMessage> messages,
    required Function(String chunk) onChunk,
    required Function(LLMResponse) onComplete,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    throw UnimplementedError('Streaming not yet implemented');
  }
}

/// LLM 팩토리
class LLMAdapterFactory {
  static LLMAdapter create({
    required LLMProviderType provider,
    required String apiKey,
    String? baseUrl,
  }) {
    switch (provider) {
      case LLMProviderType.openAI:
        return OpenAIAdapter(apiKey: apiKey, baseUrl: baseUrl);
      case LLMProviderType.anthropic:
        return AnthropicAdapter(apiKey: apiKey, baseUrl: baseUrl);
      case LLMProviderType.google:
        return GoogleAdapter(apiKey: apiKey);
      case LLMProviderType.local:
        throw UnimplementedError('Local LLM not yet implemented');
    }
  }
}

/// LLM 매니저
class LLMManager {
  static final LLMManager _instance = LLMManager._();
  static LLMManager get instance => _instance;

  LLMManager._();

  LLMAdapter? _adapter;
  LLMProviderType _provider = LLMProviderType.openAI;

  void configure({
    required LLMProviderType provider,
    required String apiKey,
    String? baseUrl,
  }) {
    _provider = provider;
    _adapter = LLMAdapterFactory.create(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
    );

    debugPrint('[LLM] Configured: $provider');
  }

  Future<LLMResponse> chat({
    required List<ChatMessage> messages,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    if (_adapter == null) {
      throw Exception('LLM not configured. Call configure() first.');
    }

    return _adapter!.chat(
      messages: messages,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  Future<void> streamChat({
    required List<ChatMessage> messages,
    required Function(String chunk) onChunk,
    required Function(LLMResponse) onComplete,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    if (_adapter == null) {
      throw Exception('LLM not configured. Call configure() first.');
    }

    await _adapter!.streamChat(
      messages: messages,
      onChunk: onChunk,
      onComplete: onComplete,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  bool get isConfigured => _adapter != null;
  LLMProviderType get provider => _provider;
}
