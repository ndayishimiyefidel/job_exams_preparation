# Job Exam Preparation Frontend

A beautiful Flutter application for job exam preparation, featuring a modern UI inspired by professional platforms like Vuba Vuba with Rwanda-inspired color scheme.

## 🎨 Features

### **Beautiful UI/UX**
- **Modern Design**: Inspired by Vuba Vuba website with Rwanda color scheme
- **Responsive Layout**: Works perfectly on web, mobile, and tablet
- **Professional Typography**: Google Fonts integration
- **Smooth Animations**: Engaging user interactions

### **Core Functionality**
- **Authentication System**: Login/Register with BLoC state management
- **Job Positions**: Browse available job categories
- **Practice Exams**: Free and paid exam system
- **Progress Tracking**: Monitor your performance
- **Study Resources**: Access learning materials

### **Technical Features**
- **Clean Architecture**: Well-organized code structure
- **State Management**: BLoC pattern for robust state handling
- **API Integration**: Ready to connect with PHP backend
- **Local Storage**: Offline support with Hive
- **Code Generation**: Automated boilerplate with build_runner

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Chrome browser (for web development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd job_exam_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

## 📱 Screenshots

### Home Page
- Hero section with compelling call-to-action
- Features showcase with beautiful cards
- How it works step-by-step guide
- Statistics and impact metrics
- Professional color scheme (Rwanda green/blue)

### Positions Screen
- Grid layout of job positions
- Color-coded categories
- Free/Paid exam indicators
- Exam count display

### Exams Screen
- Detailed exam listings
- Rating and review system
- Pass rate indicators
- Price and duration information

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── env_config.dart          # Environment configuration
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette (Rwanda theme)
│   │   ├── app_strings.dart         # Localized strings
│   │   └── app_themes.dart          # Material Design themes
│   └── services/
│       ├── api_service.dart         # REST API client
│       └── local_storage.dart       # Local data management
├── data/
│   └── models/
│       ├── user_model.dart          # User data model
│       ├── position_model.dart      # Job position model
│       ├── exam_model.dart          # Exam data model
│       └── resource_model.dart      # Study resource model
├── presentation/
│   ├── screens/
│   │   ├── splash/
│   │   │   └── splash_screen.dart   # Animated splash screen
│   │   ├── home/
│   │   │   └── home_screen.dart     # Beautiful landing page
│   │   ├── auth/
│   │   │   └── login_screen.dart    # Authentication screen
│   │   ├── positions/
│   │   │   └── positions_screen.dart # Job positions grid
│   │   └── exams/
│   │       └── exams_screen.dart    # Exam listings
│   ├── state/
│   │   ├── auth/
│   │   │   ├── auth_cubit.dart      # Authentication state
│   │   │   └── auth_state.dart      # Auth state definitions
│   │   └── user/
│   │       └── user_cubit.dart      # User profile state
│   ├── widgets/
│   │   ├── custom_button.dart       # Reusable button component
│   │   └── custom_input.dart        # Form input component
│   └── routes/
│       └── app_router.dart          # Navigation routing
└── main.dart                        # App entry point
```

## 🎨 Design System

### Color Palette (Rwanda-Inspired)
- **Primary Green**: `#00A651` (Rwanda flag green)
- **Secondary Blue**: `#1976D2` (Rwanda flag blue)
- **Success Green**: `#4CAF50`
- **Warning Orange**: `#FFC107`
- **Error Red**: `#F44336`
- **Info Cyan**: `#00BCD4`

### Typography
- **Font Family**: Poppins (via Google Fonts)
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)
- **Responsive sizing** for all screen sizes

### Components
- **Cards**: Elevated with rounded corners and shadows
- **Buttons**: Material Design 3 with custom styling
- **Inputs**: Consistent form field design
- **Navigation**: Clean and intuitive routing

## 🔧 Configuration

### Backend Integration
The app is configured to work with the PHP backend API:

```dart
// API Base URL (configurable)
static const String baseUrl = 'http://localhost/job_exam_backend';
static const String apiUrl = '$baseUrl/api';
```

### Demo Credentials
- **Email**: admin@jobexam.com
- **Password**: admin123

## 📦 Dependencies

### Core Dependencies
- `flutter_bloc`: State management
- `dio`: HTTP client
- `retrofit`: API client generation
- `hive`: Local storage
- `google_fonts`: Typography
- `go_router`: Navigation

### Development Dependencies
- `build_runner`: Code generation
- `json_serializable`: JSON serialization
- `retrofit_generator`: API client generation
- `hive_generator`: Local storage generation

## 🚀 Deployment

### Web Deployment
```bash
flutter build web
```

### Mobile Deployment
```bash
flutter build apk  # Android
flutter build ios  # iOS
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure code quality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Design Inspiration**: Vuba Vuba website
- **Color Scheme**: Rwanda flag colors
- **Icons**: Material Design Icons
- **Fonts**: Google Fonts (Poppins)

---

**Built with ❤️ using Flutter**
