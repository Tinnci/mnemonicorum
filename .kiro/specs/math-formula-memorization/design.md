# Design Document

## Overview

The math formula memorization app will be built as a Flutter application that provides an interactive, gamified learning experience for mathematical formulas. The app will use `flutter_math_fork` for LaTeX rendering to ensure optimal performance, offline capability, and smooth interactions. The architecture follows a clean, modular design with clear separation between data, business logic, and presentation layers.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │   Business      │    │   Data          │
│   Layer         │◄──►│   Logic Layer   │◄──►│   Layer         │
│                 │    │                 │    │                 │
│ - Screens       │    │ - Services      │    │ - Models        │
│ - Widgets       │    │ - Controllers   │    │ - Repositories  │
│ - State Mgmt    │    │ - Use Cases     │    │ - Local Storage │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack

- **Framework**: Flutter 3.x
- **LaTeX Rendering**: `flutter_math_fork` (pure Dart, offline, high performance)
- **State Management**: Provider or Riverpod
- **Local Storage**: Hive or SQLite for progress tracking
- **Navigation**: GoRouter for declarative routing
- **Testing**: Flutter test framework with widget and unit tests

## Components and Interfaces

### Core Components

#### 1. Formula Renderer Component
```dart
class FormulaRenderer extends StatelessWidget {
  final String latexExpression;
  final double fontSize;
  final Color textColor;
  
  // Uses flutter_math_fork's Math.tex() widget
  Widget build(BuildContext context) {
    return Math.tex(
      latexExpression,
      textStyle: TextStyle(fontSize: fontSize, color: textColor),
    );
  }
}
```

#### 2. Exercise Components

**Matching Exercise Widget**
- Displays formula component on left
- Shows multiple choice options on right
- Handles user selection and feedback
- Uses `GestureDetector` with `FormulaRenderer` for clickable options

**Completion Exercise Widget**
- Shows partial formula with blanks
- Provides draggable/selectable options to fill blanks
- Validates completion accuracy

**Recognition Exercise Widget**
- Displays complete formula
- Asks user to identify formula name/type
- Multiple choice format with formula names

#### 3. Progress Tracking Components

**Progress Dashboard**
- Category-wise mastery overview
- Individual formula progress bars
- Achievement badges and streaks

**Formula Mastery Indicator**
- Visual representation of mastery level
- Color-coded status (learning, practicing, mastered)

### Screen Architecture

#### 1. Home Screen
- Category selection grid
- Progress overview
- Daily practice streak
- Quick practice button

#### 2. Category Screen
- Formula set listings within category
- Progress indicators per set
- Difficulty levels

#### 3. Practice Session Screen
- Exercise display area
- Answer options
- Progress indicator
- Feedback overlay

#### 4. Results Screen
- Session summary
- Accuracy statistics
- Recommendations for improvement

## Data Models

### Formula Model
```dart
class Formula {
  final String id;
  final String name;
  final String latexExpression;
  final String category;
  final String subcategory;
  final DifficultyLevel difficulty;
  final List<String> tags;
  final String description;
  final List<FormulaComponent> components;
}

class FormulaComponent {
  final String id;
  final String latexPart;
  final ComponentType type; // leftSide, rightSide, variable, constant
  final String description;
}
```

### Exercise Model
```dart
class Exercise {
  final String id;
  final Formula formula;
  final ExerciseType type;
  final String question;
  final List<ExerciseOption> options;
  final String correctAnswerId;
  final String explanation;
}

class ExerciseOption {
  final String id;
  final String latexExpression;
  final String textLabel;
  final bool isCorrect;
}
```

### Progress Model
```dart
class FormulaProgress {
  final String formulaId;
  final int correctAnswers;
  final int totalAttempts;
  final DateTime lastPracticed;
  final MasteryLevel masteryLevel;
  final List<ExerciseAttempt> attempts;
}

enum MasteryLevel { learning, practicing, mastered }
```

### Category Model
```dart
class FormulaCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<FormulaSet> formulaSets;
}

class FormulaSet {
  final String id;
  final String name;
  final List<Formula> formulas;
  final DifficultyLevel difficulty;
}
```

## Error Handling

### LaTeX Rendering Errors
- Fallback to plain text if LaTeX parsing fails
- Error logging for malformed expressions
- Graceful degradation with user notification

### Data Loading Errors
- Retry mechanisms for failed data loads
- Offline-first approach with cached data
- User-friendly error messages

### Performance Optimization
- Preload mathematical fonts using `preloadMathematicsFonts()`
- Lazy loading of formula sets
- Image caching for rendered formulas
- Memory management for large formula lists

## Testing Strategy

### Unit Tests
- Formula parsing and validation
- Exercise generation logic
- Progress calculation algorithms
- Data model serialization/deserialization

### Widget Tests
- Formula rendering with various LaTeX expressions
- Exercise interaction flows
- Progress display components
- Navigation between screens

### Integration Tests
- Complete practice session flows
- Data persistence and retrieval
- Category and formula set navigation
- Progress tracking accuracy

### Performance Tests
- LaTeX rendering performance with complex formulas
- Memory usage during extended practice sessions
- App startup time optimization
- Smooth scrolling in formula lists

## Formula Content Strategy

### Initial Formula Sets

**Calculus Category**
- Taylor Series: `e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!}`
- Integration by Parts: `\int u \, dv = uv - \int v \, du`
- Fundamental Theorem: `\int_a^b f'(x) \, dx = f(b) - f(a)`

**Trigonometry Category**
- Pythagorean Identity: `\sin^2 x + \cos^2 x = 1`
- Addition Formulas: `\sin(a + b) = \sin a \cos b + \cos a \sin b`
- Double Angle: `\cos 2x = \cos^2 x - \sin^2 x`

**Algebra Category**
- Quadratic Formula: `x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}`
- Binomial Theorem: `(a + b)^n = \sum_{k=0}^{n} \binom{n}{k} a^{n-k} b^k`

### Content Management
- JSON-based formula definitions
- Modular category organization
- Easy addition of new formula sets
- Localization support for multiple languages

## User Experience Design

### Interaction Patterns
- Tap to select answers (mobile-optimized)
- Drag and drop for completion exercises
- Swipe gestures for navigation
- Haptic feedback for correct/incorrect answers

### Visual Design
- Clean, minimalist interface
- High contrast for formula readability
- Color-coded feedback (green for correct, red for incorrect)
- Consistent spacing and typography

### Accessibility
- Screen reader support for formula descriptions
- High contrast mode compatibility
- Adjustable font sizes
- Voice-over friendly navigation

## Performance Considerations

### LaTeX Rendering Optimization
- Use `flutter_math_fork` for pure Dart rendering (no WebView overhead)
- Preload fonts during app initialization
- Cache rendered formula widgets
- Optimize for 60fps interactions

### Memory Management
- Dispose of unused formula widgets
- Implement pagination for large formula sets
- Use efficient data structures for progress tracking
- Monitor memory usage during practice sessions

### Offline Performance
- All formulas stored locally
- No network dependencies for core functionality
- Fast app startup with local data
- Efficient local storage queries