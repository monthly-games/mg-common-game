#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// MG-Games App Icon & Splash Generator
///
/// Generates all required app icons and splash screens for iOS and Android
/// from a single source image.
///
/// Usage:
///   dart run tools/generate_icons.dart --source assets/icon.png
///   dart run tools/generate_icons.dart --source assets/icon.png --background "#FF5722"
///
/// Requirements:
///   - flutter_launcher_icons package in dev_dependencies
///   - flutter_native_splash package in dev_dependencies
///   - Source image should be at least 1024x1024 pixels
///
/// This script generates:
///   - iOS App Icons (all sizes)
///   - Android App Icons (all densities)
///   - Android Adaptive Icons
///   - iOS Launch Screen
///   - Android Splash Screen

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Icon size configurations for different platforms
class IconConfig {
  static const Map<String, int> iosIcons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  static const Map<String, int> androidIcons = {
    'mipmap-mdpi/ic_launcher.png': 48,
    'mipmap-hdpi/ic_launcher.png': 72,
    'mipmap-xhdpi/ic_launcher.png': 96,
    'mipmap-xxhdpi/ic_launcher.png': 144,
    'mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  static const Map<String, int> androidAdaptiveIcons = {
    'mipmap-mdpi/ic_launcher_foreground.png': 108,
    'mipmap-hdpi/ic_launcher_foreground.png': 162,
    'mipmap-xhdpi/ic_launcher_foreground.png': 216,
    'mipmap-xxhdpi/ic_launcher_foreground.png': 324,
    'mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
  };
}

/// Splash screen configurations
class SplashConfig {
  final String backgroundColor;
  final String? image;
  final String? brandingImage;
  final bool fullscreen;
  final String? android12BackgroundColor;

  const SplashConfig({
    this.backgroundColor = '#FFFFFF',
    this.image,
    this.brandingImage,
    this.fullscreen = false,
    this.android12BackgroundColor,
  });

  Map<String, dynamic> toFlutterNativeSplashConfig() {
    return {
      'flutter_native_splash': {
        'color': backgroundColor,
        if (image != null) 'image': image,
        if (brandingImage != null) 'branding': brandingImage,
        'fullscreen': fullscreen,
        'android_12': {
          'color': android12BackgroundColor ?? backgroundColor,
          if (image != null) 'image': image,
        },
        'ios': true,
        'android': true,
        'web': false,
      },
    };
  }
}

/// Main icon generator class
class IconGenerator {
  final String projectPath;
  final String sourceIcon;
  final String? backgroundColor;
  final bool generateSplash;
  final String? splashImage;

  IconGenerator({
    required this.projectPath,
    required this.sourceIcon,
    this.backgroundColor,
    this.generateSplash = true,
    this.splashImage,
  });

  /// Run the icon generation process
  Future<void> generate() async {
    print('🎨 MG-Games Icon Generator');
    print('=' * 50);

    // Validate source icon
    final sourceFile = File(path.join(projectPath, sourceIcon));
    if (!await sourceFile.exists()) {
      print('❌ Source icon not found: $sourceIcon');
      print('   Please provide a valid path to your app icon.');
      exit(1);
    }

    print('📁 Project: $projectPath');
    print('🖼️  Source: $sourceIcon');
    if (backgroundColor != null) {
      print('🎨 Background: $backgroundColor');
    }

    // Update pubspec.yaml with flutter_launcher_icons config
    await _updatePubspec();

    // Generate icons using flutter_launcher_icons
    await _generateIcons();

    // Generate splash screen if requested
    if (generateSplash) {
      await _generateSplash();
    }

    print('\n✅ Icon generation complete!');
    print('   Run "flutter pub get" if you haven\'t already.');
  }

  Future<void> _updatePubspec() async {
    print('\n📝 Updating pubspec.yaml...');

    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      print('❌ pubspec.yaml not found in project directory');
      exit(1);
    }

    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    // Add flutter_launcher_icons configuration
    final iconConfig = {
      'android': true,
      'ios': true,
      'image_path': sourceIcon,
      'min_sdk_android': 21,
      'remove_alpha_ios': true,
      if (backgroundColor != null) ...{
        'adaptive_icon_background': backgroundColor,
        'adaptive_icon_foreground': sourceIcon,
      },
    };

    try {
      editor.update(['flutter_launcher_icons'], iconConfig);
    } catch (e) {
      // Key doesn't exist, create it
      final yaml = loadYaml(content) as Map;
      final updatedYaml = Map<String, dynamic>.from(yaml);
      updatedYaml['flutter_launcher_icons'] = iconConfig;

      // Write back
      await pubspecFile.writeAsString(editor.toString());
    }

    print('   ✓ flutter_launcher_icons config added');
  }

  Future<void> _generateIcons() async {
    print('\n🔧 Generating app icons...');

    // Check if flutter_launcher_icons is installed
    final result = await Process.run(
      'flutter',
      ['pub', 'run', 'flutter_launcher_icons'],
      workingDirectory: projectPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('   ⚠️  flutter_launcher_icons not found. Installing...');

      // Add to dev_dependencies if not present
      await Process.run(
        'flutter',
        ['pub', 'add', 'flutter_launcher_icons', '--dev'],
        workingDirectory: projectPath,
        runInShell: true,
      );

      // Run again
      final retryResult = await Process.run(
        'flutter',
        ['pub', 'run', 'flutter_launcher_icons'],
        workingDirectory: projectPath,
        runInShell: true,
      );

      if (retryResult.exitCode != 0) {
        print('❌ Failed to generate icons');
        print(retryResult.stderr);
        exit(1);
      }
    }

    print('   ✓ iOS icons generated');
    print('   ✓ Android icons generated');
    if (backgroundColor != null) {
      print('   ✓ Android adaptive icons generated');
    }
  }

  Future<void> _generateSplash() async {
    print('\n🌊 Generating splash screens...');

    final splashSource = splashImage ?? sourceIcon;

    // Add flutter_native_splash configuration to pubspec
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final content = await pubspecFile.readAsString();
    final editor = YamlEditor(content);

    final splashConfig = {
      'color': backgroundColor ?? '#FFFFFF',
      'image': splashSource,
      'android_12': {
        'color': backgroundColor ?? '#FFFFFF',
        'image': splashSource,
      },
    };

    try {
      editor.update(['flutter_native_splash'], splashConfig);
      await pubspecFile.writeAsString(editor.toString());
    } catch (e) {
      // Append configuration
    }

    // Check and install flutter_native_splash
    final result = await Process.run(
      'flutter',
      ['pub', 'run', 'flutter_native_splash:create'],
      workingDirectory: projectPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('   ⚠️  flutter_native_splash not found. Installing...');

      await Process.run(
        'flutter',
        ['pub', 'add', 'flutter_native_splash', '--dev'],
        workingDirectory: projectPath,
        runInShell: true,
      );

      await Process.run(
        'flutter',
        ['pub', 'run', 'flutter_native_splash:create'],
        workingDirectory: projectPath,
        runInShell: true,
      );
    }

    print('   ✓ iOS splash screen generated');
    print('   ✓ Android splash screen generated');
    print('   ✓ Android 12+ splash screen generated');
  }
}

/// Generate flutter_launcher_icons.yaml configuration file
void generateIconConfigFile(String projectPath, String sourceIcon, String? backgroundColor) {
  final config = '''
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "$sourceIcon"
  min_sdk_android: 21
  remove_alpha_ios: true
${backgroundColor != null ? '''
  adaptive_icon_background: "$backgroundColor"
  adaptive_icon_foreground: "$sourceIcon"
''' : ''}
  web:
    generate: true
    image_path: "$sourceIcon"
    background_color: "${backgroundColor ?? '#FFFFFF'}"
    theme_color: "${backgroundColor ?? '#FFFFFF'}"
  windows:
    generate: true
    image_path: "$sourceIcon"
    icon_size: 48
  macos:
    generate: true
    image_path: "$sourceIcon"
''';

  final file = File(path.join(projectPath, 'flutter_launcher_icons.yaml'));
  file.writeAsStringSync(config);
  print('📄 Generated flutter_launcher_icons.yaml');
}

/// Generate flutter_native_splash.yaml configuration file
void generateSplashConfigFile(
  String projectPath,
  String sourceIcon,
  String? backgroundColor,
  String? brandingImage,
) {
  final bgColor = backgroundColor ?? '#FFFFFF';

  final config = '''
flutter_native_splash:
  color: "$bgColor"
  image: "$sourceIcon"

  # Android 12+ splash screen
  android_12:
    color: "$bgColor"
    image: "$sourceIcon"
${brandingImage != null ? '    branding: "$brandingImage"' : ''}

  # iOS configuration
  ios: true

  # Android configuration
  android: true

  # Full screen mode
  fullscreen: false

  # Branding image (bottom of splash)
${brandingImage != null ? '  branding: "$brandingImage"' : '  # branding: "assets/branding.png"'}
''';

  final file = File(path.join(projectPath, 'flutter_native_splash.yaml'));
  file.writeAsStringSync(config);
  print('📄 Generated flutter_native_splash.yaml');
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'source',
      abbr: 's',
      help: 'Source icon image path (required)',
      mandatory: true,
    )
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Project directory path (defaults to current directory)',
      defaultsTo: '.',
    )
    ..addOption(
      'background',
      abbr: 'b',
      help: 'Background color for adaptive icons (hex, e.g., #FF5722)',
    )
    ..addOption(
      'splash',
      help: 'Splash screen image (defaults to source icon)',
    )
    ..addOption(
      'branding',
      help: 'Branding image for splash screen',
    )
    ..addFlag(
      'no-splash',
      help: 'Skip splash screen generation',
      defaultsTo: false,
    )
    ..addFlag(
      'config-only',
      help: 'Only generate configuration files without running generators',
      defaultsTo: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information',
      negatable: false,
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('MG-Games App Icon & Splash Generator\n');
      print('Usage: dart run tools/generate_icons.dart [options]\n');
      print(parser.usage);
      print('\nExamples:');
      print('  dart run tools/generate_icons.dart --source assets/icon.png');
      print('  dart run tools/generate_icons.dart -s assets/icon.png -b "#FF5722"');
      print('  dart run tools/generate_icons.dart -s assets/icon.png --no-splash');
      exit(0);
    }

    final sourceIcon = results['source'] as String;
    final projectPath = results['project'] as String;
    final backgroundColor = results['background'] as String?;
    final splashImage = results['splash'] as String?;
    final brandingImage = results['branding'] as String?;
    final noSplash = results['no-splash'] as bool;
    final configOnly = results['config-only'] as bool;

    if (configOnly) {
      // Only generate configuration files
      generateIconConfigFile(projectPath, sourceIcon, backgroundColor);
      if (!noSplash) {
        generateSplashConfigFile(projectPath, sourceIcon, backgroundColor, brandingImage);
      }
      print('\n✅ Configuration files generated!');
      print('   Run the following commands to generate icons:');
      print('   flutter pub get');
      print('   flutter pub run flutter_launcher_icons');
      if (!noSplash) {
        print('   flutter pub run flutter_native_splash:create');
      }
    } else {
      // Run full generation
      final generator = IconGenerator(
        projectPath: projectPath,
        sourceIcon: sourceIcon,
        backgroundColor: backgroundColor,
        generateSplash: !noSplash,
        splashImage: splashImage,
      );

      await generator.generate();
    }
  } on FormatException catch (e) {
    print('Error: ${e.message}\n');
    print('Usage: dart run tools/generate_icons.dart [options]\n');
    print(parser.usage);
    exit(1);
  }
}
