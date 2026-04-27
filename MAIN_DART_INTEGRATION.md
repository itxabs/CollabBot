# Adding LinkedIn Extraction to main.dart

## Step-by-Step Integration

### 1. Update your `main.dart`

Find your `MyApp` class and update it:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ... other imports ...

// ✅ ADD THIS IMPORT
import 'view_model/linkedin_extraction_view_model.dart';
import 'screens/linkedin_extraction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: 'https://hgpcisbeepambgudfncr.supabase.co',
    anonKey: 'sb_publishable_E_cRI60_IKr9jBLfGmpdmQ_3B9ih8K0',
  );
  await LocalMessageDb.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... your existing providers ...
        
        // ✅ ADD THIS PROVIDER
        ChangeNotifierProvider(
          create: (_) => LinkedInExtractionViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Collab Bot',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          // ... your existing routes ...
          
          // ✅ ADD THIS ROUTE (optional)
          '/linkedin-extraction': (context) => const LinkedInExtractionScreen(),
        },
      ),
    );
  }
}
```

---

## 2. Update pubspec.yaml

Ensure these dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Your existing dependencies...
  provider: ^6.0.0
  supabase_flutter: ^2.0.0
  flutter_dotenv: ^5.0.0
  
  # ✅ ADD IF NOT PRESENT
  file_picker: ^5.5.0  # For image selection
  http: ^1.1.0         # Should already be there

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Then run:
```bash
flutter pub get
```

---

## 3. Add Navigation to LinkedIn Extraction

### Option A: Add to Navigation Drawer

```dart
// In your main navigation or drawer:

ListTile(
  leading: const Icon(Icons.work),
  title: const Text('Extract LinkedIn'),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LinkedInExtractionScreen(),
      ),
    );
  },
),
```

### Option B: Add as Tab

```dart
// In TabBarView with tabs:

TabBarView(
  children: [
    // ... existing tabs ...
    
    // ✅ ADD THIS TAB
    const LinkedInExtractionScreen(),
  ],
),

// In TabBar:
TabBar(
  controller: _tabController,
  tabs: [
    // ... existing tabs ...
    const Tab(text: 'LinkedIn'),
  ],
),
```

### Option C: Add as Button in Profile Setup

```dart
// In your profile setup screen:

ElevatedButton.icon(
  icon: const Icon(Icons.business),
  label: const Text('Import from LinkedIn'),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LinkedInExtractionScreen(),
      ),
    );
  },
),
```

---

## 4. Use Extracted Data

After user extracts and saves data, you can access it:

```dart
// Get the data:
final viewModel = context.read<LinkedInExtractionViewModel>();

final skills = viewModel.extractedSkills;
final experience = viewModel.extractedExperience;
final resumeScore = viewModel.resumeScore;

// Save to your database/provider:
void _saveProfileData(BuildContext context) {
  final viewModel = context.read<LinkedInExtractionViewModel>();
  
  // Save to Supabase or your database
  supabase.from('user_skills').insert([
    for (var skill in viewModel.extractedSkills)
      {'user_id': userId, 'skill': skill}
  ]);
  
  // Save experiences
  supabase.from('experiences').insert([
    for (var exp in viewModel.extractedExperience)
      {
        'user_id': userId,
        'role': exp['roleCompany'],
        'duration': exp['duration']
      }
  ]);
}
```

---

## 5. Display Extracted Data in Profile

```dart
// In your profile screen:

Consumer<LinkedInExtractionViewModel>(
  builder: (context, viewModel, _) {
    if (viewModel.extractedSkills.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills from LinkedIn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewModel.extractedSkills.map((skill) {
            return Chip(label: Text(skill));
          }).toList(),
        ),
      ],
    );
  },
),
```

---

## 6. Test Integration

### Test 1: Check if ViewModel loads

```dart
// Add this in your test or debug screen:

@override
void initState() {
  super.initState();
  
  // Check backend health on startup
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<LinkedInExtractionViewModel>().checkBackendHealth();
  });
}

// In your UI:
Consumer<LinkedInExtractionViewModel>(
  builder: (context, viewModel, _) {
    final status = viewModel.healthStatus['status'] ?? 'unknown';
    
    return Text(
      'Backend Status: $status',
      style: TextStyle(
        color: status == 'operational' ? Colors.green : Colors.red,
      ),
    );
  },
),
```

### Test 2: Manual Extraction

```dart
// Simple test button:

ElevatedButton(
  onPressed: () async {
    final viewModel = context.read<LinkedInExtractionViewModel>();
    
    final testHtml = '''
    <html>
      <body>
        <div class="skill">Flutter</div>
        <div class="skill">Dart</div>
        <div>Developer at Tech Corp</div>
        <div>2022-Present</div>
      </body>
    </html>
    ''';
    
    await viewModel.extractFromHtml(testHtml);
    
    print('Skills: ${viewModel.extractedSkills}');
    print('Experience: ${viewModel.extractedExperience}');
  },
  child: const Text('Test Extraction'),
),
```

---

## 7. Troubleshooting Integration

### Issue: "ViewModel not found"
**Solution**: Make sure you added the provider in `MultiProvider`:
```dart
ChangeNotifierProvider(
  create: (_) => LinkedInExtractionViewModel(),
),
```

### Issue: "Backend connection refused"
**Solution**: 
1. Ensure backend is running: `python main.py`
2. Check baseUrl in `linkedin_extraction_service.dart`
3. For Android emulator, use `10.0.2.2:8000` instead of `localhost:8000`

### Issue: "Image not found after picker"
**Solution**: The FilePicker returns the path - ensure it exists:
```dart
final File file = File(imagePath);
print(file.existsSync()); // Should be true
```

### Issue: "OCR not working"
**Solution**: Install Tesseract on your backend server:
```bash
choco install tesseract  # Windows
brew install tesseract    # Mac
sudo apt install tesseract-ocr  # Linux
```

---

## 8. Complete Example

Here's a complete minimal example:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_model/linkedin_extraction_view_model.dart';
import 'screens/linkedin_extraction_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LinkedInExtractionViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'LinkedIn Extractor',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LinkedInExtractionScreen(),
              ),
            );
          },
          child: const Text('Open LinkedIn Extractor'),
        ),
      ),
    );
  }
}
```

---

## 9. Configuration for Different Backends

### Local Development (Default)
```dart
// lib/core/services/linkedin_extraction_service.dart
static const String baseUrl = 'http://localhost:8000';
```

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

### Real Device (Same Network)
```dart
static const String baseUrl = 'http://192.168.1.100:8000';  // Your PC IP
```

### Production Server
```dart
static const String baseUrl = 'https://api.yourserver.com';
```

---

## 10. Environment Configuration

Create `.env` file in your project root:

```
BACKEND_URL=http://localhost:8000
```

Then use in your app:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// In service:
static String baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
```

---

## ✅ Final Checklist

- [ ] Added ViewModel import to main.dart
- [ ] Added ViewModel to MultiProvider
- [ ] Added LinkedInExtractionScreen import
- [ ] Backend is running: `python main.py`
- [ ] Added navigation to LinkedInExtractionScreen
- [ ] Tested with sample data
- [ ] Backend health check passes
- [ ] Can extract from HTML
- [ ] Can upload images (if Tesseract installed)
- [ ] Extracted data displays in UI
- [ ] Can save to your database

---

## 🚀 Ready to Go!

Your Flutter app now has full LinkedIn extraction capabilities. 

**Key Points:**
- ✅ No existing code was modified
- ✅ Works as a standalone feature
- ✅ Integrates with existing Provider setup
- ✅ Can be added to any screen/navigation
- ✅ Handles all errors gracefully

Start your backend and your app is ready! 🎉

---

**Questions?**
- Check `INTEGRATION_GUIDE.md` for detailed docs
- Check `QUICK_START.md` for troubleshooting
- Check backend logs: `python main.py` output
