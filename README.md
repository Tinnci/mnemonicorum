# Mnemonicorum - Interactive Math Formula Learning App

A modern, interactive Flutter application designed to help students master mathematical formulas through engaging practice sessions and intelligent progress tracking.

## 🎯 Features

### Interactive Learning Experience
- **Three Exercise Types**: Recognition, Matching, and Completion exercises
- **Real-time Feedback**: Immediate visual feedback on correct/incorrect answers
- **Adaptive Difficulty**: Progressive learning based on performance
- **Formula Rendering**: Beautiful LaTeX formula display with mathematical notation

### Comprehensive Progress Tracking
- **Detailed Statistics**: Track accuracy, completion rates, and learning streaks
- **Achievement System**: Gamified learning with unlockable achievements
- **Category-based Learning**: Organized formula sets by mathematical topics
- **Progress Dashboard**: Visual representation of learning progress

### Modern UI/UX Design
- **Responsive Layout**: Adapts to different screen sizes and orientations
- **Material Design 3**: Modern, accessible interface design
- **Dark/Light Theme Support**: Automatic theme adaptation
- **Keyboard Navigation**: Full keyboard support for desktop users

### Mathematical Content
- **Calculus Formulas**: Taylor series, integration techniques, infinitesimal equivalents
- **Trigonometry**: Trigonometric identities and formulas
- **Extensible System**: Easy to add new formula categories and sets

## 🛠️ Technology Stack

- **Framework**: Flutter 3.9+
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: Go Router
- **Data Storage**: Hive (NoSQL database)
- **Math Rendering**: Flutter Math Fork (LaTeX support)
- **UI Components**: Material Design 3
- **Responsive Design**: Auto Size Text, Adaptive Layout

## 📱 Supported Platforms

- **Windows**: Desktop application with full keyboard support
- **Android**: Mobile app with touch interface
- **iOS**: Native iOS experience
- **Web**: Browser-based learning (planned)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.9.0 or higher
- Dart SDK 3.9.0 or higher
- Windows 10/11 (for Windows build)
- Android Studio / VS Code (recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tinnci/mnemonicorum.git
   cd mnemonicorum
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

### Building for Production

```bash
# Windows executable
flutter build windows

# Android APK
flutter build apk

# iOS (requires macOS)
flutter build ios
```

## 📖 Usage Guide

### Getting Started
1. **Launch the app** and complete the onboarding process
2. **Select a category** from the home screen (e.g., Calculus, Trigonometry)
3. **Choose a formula set** within the category
4. **Start practicing** with interactive exercises

### Exercise Types

#### Recognition Exercises
- **Goal**: Identify the name of a displayed formula
- **Interaction**: Select the correct formula name from multiple choices
- **Learning**: Reinforces formula recognition and terminology

#### Matching Exercises
- **Goal**: Complete mathematical equations by matching parts
- **Interaction**: Drag and drop or select the correct formula component
- **Learning**: Builds understanding of formula structure and relationships

#### Completion Exercises
- **Goal**: Fill in missing parts of mathematical expressions
- **Interaction**: Select the correct missing component from options
- **Learning**: Develops pattern recognition and formula completion skills

### Progress Tracking
- **Daily Streaks**: Maintain learning momentum with daily practice
- **Accuracy Metrics**: Track performance across different formula types
- **Achievement Unlocks**: Earn badges for consistent practice and improvement
- **Category Progress**: Monitor completion rates for each mathematical topic

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                 # Application entry point
├── app_router.dart          # Navigation configuration
├── hive_initializer.dart    # Database initialization
├── models/                  # Data models
├── repositories/            # Data access layer
├── services/               # Business logic
├── screens/                # UI screens
├── widgets/                # Reusable UI components
└── utils/                  # Utility functions
```

### Key Components
- **Formula Repository**: Manages formula data and categories
- **Progress Service**: Tracks user learning progress
- **Achievement System**: Handles gamification features
- **Exercise Generator**: Creates practice sessions
- **Adaptive Scaffold**: Responsive navigation structure

## 🎨 Design Principles

### Responsive Design
- **Adaptive Grid Layouts**: Automatically adjust column count based on screen width
- **Content Width Constraints**: Optimal reading width for wide screens
- **Flexible Typography**: Auto-sizing text for different screen sizes

### Accessibility
- **Keyboard Navigation**: Full keyboard support for desktop users
- **Screen Reader Support**: Semantic descriptions for mathematical content
- **High Contrast**: Clear visual hierarchy and color contrast

### Performance Optimization
- **Lazy Loading**: Load formula data on demand
- **Memory Management**: Optimize LaTeX rendering memory usage
- **Caching**: Cache frequently accessed data for better performance

## 🔧 Development

### Code Style
- Follows Dart/Flutter best practices
- Uses Provider for state management
- Implements error boundaries for robust error handling
- Comprehensive error logging and user feedback

### Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Acknowledgments

- **Flutter Team**: For the excellent cross-platform framework
- **Material Design**: For the comprehensive design system
- **LaTeX Community**: For mathematical notation standards
- **Open Source Contributors**: For various packages and tools used


---

**Mnemonicorum** - Making mathematical learning engaging, interactive, and effective.
