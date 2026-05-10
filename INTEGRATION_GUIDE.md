# Frontend-Backend Integration Guide

## 🎯 Overview

The LinkedIn extraction service is now fully integrated with both backend (Python/FastAPI) and frontend (Flutter).

### Architecture

```
Flutter App
    ↓
LinkedInExtractionViewModel (State Management)
    ↓
LinkedInExtractionService (HTTP Client)
    ↓
FastAPI Backend (http://localhost:8000)
    ├── /linkedin/extract/html
    ├── /linkedin/extract/image
    ├── /analyze-resume
    └── /health
```

---

## 📦 Backend Status

### Services Running
✅ **Resume Analyzer** - PDF/DOCX text extraction + ATS scoring  
✅ **Matching Service** - User similarity calculations  
✅ **LinkedIn Extractor** - HTML/Image parsing + OCR  

### Start Backend

```bash
cd backend
python main.py
```

Server runs on: `http://localhost:8000`

Health check: `http://localhost:8000/health`

---

## 🚀 Frontend Integration

### 1. Update `main.dart`

Add LinkedInExtractionViewModel to providers:

```dart
import 'package:provider/provider.dart';
import 'view_model/linkedin_extraction_view_model.dart';

void main() {
  // ... existing code ...
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... existing providers ...
        ChangeNotifierProvider(
          create: (_) => LinkedInExtractionViewModel(),
        ),
      ],
      child: MaterialApp(
        // ... existing config ...
      ),
    );
  }
}
```

### 2. Add Screen to Navigation

Add to your routing/navigation:

```dart
// In your navigation/routing
LinkedInExtractionScreen() // Can be added to drawer or tab

// Or navigate to it:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const LinkedInExtractionScreen(),
  ),
);
```

### 3. Configuration

Update backend URL in `lib/core/services/linkedin_extraction_service.dart`:

```dart
// For local development
static const String baseUrl = 'http://localhost:8000';

// For production (update with your server IP/domain)
// static const String baseUrl = 'http://your-server.com:8000';
```

---

## 🔄 Service Endpoints

### Extract from HTML

**Request:**
```dart
final result = await LinkedInExtractionService.extractFromHtml(htmlContent);
```

**Response:**
```json
{
  "skills": ["Python", "Flutter", "React"],
  "experience": [
    {
      "role_company": "Engineer at Tech Corp",
      "duration": "Jan 2022 - Present"
    }
  ],
  "success": true,
  "extraction_method": "html"
}
```

### Extract from Image (OCR)

**Request:**
```dart
final result = await LinkedInExtractionService.extractFromImage(imagePath);
```

**Response:**
```json
{
  "skills": ["Python", "Flutter"],
  "experience": [...],
  "success": true,
  "extraction_method": "image_ocr"
}
```

### Analyze Resume

**Request:**
```dart
final result = await LinkedInExtractionService.analyzeResume(filePath, userId);
```

**Response:**
```json
{
  "score": 75,
  "recommendations": [
    "Add years to your experience",
    "Improve formatting with proper spacing"
  ],
  "success": true
}
```

### Health Check

**Request:**
```dart
final status = await LinkedInExtractionService.checkHealth();
```

**Response:**
```json
{
  "status": "operational",
  "services": {
    "resume_analyzer": {
      "status": "healthy",
      "test_score": 70
    },
    "linkedin_extractor": {
      "status": "healthy",
      "test_skills_found": 1
    },
    "matching_service": {
      "status": "healthy"
    }
  }
}
```

---

## 💡 Usage Examples

### Basic Usage in Screen

```dart
final viewModel = context.read<LinkedInExtractionViewModel>();

// Extract from HTML
await viewModel.extractFromHtml(htmlContent);
print('Skills: ${viewModel.extractedSkills}');
print('Experience: ${viewModel.extractedExperience}');

// Extract from Image
await viewModel.extractFromImage(imagePath);

// Analyze Resume
await viewModel.analyzeResume(resumePath, userId);
print('Resume Score: ${viewModel.resumeScore}');
```

### With Provider Consumer

```dart
Consumer<LinkedInExtractionViewModel>(
  builder: (context, viewModel, _) {
    if (viewModel.isLoadingHtml) {
      return const CircularProgressIndicator();
    }
    
    return ListView(
      children: viewModel.extractedSkills.map((skill) {
        return ListTile(title: Text(skill));
      }).toList(),
    );
  },
)
```

### Error Handling

```dart
final success = await viewModel.extractFromHtml(html);

if (!success) {
  print('Error: ${viewModel.errorMessage}');
  // Show error to user
  viewModel.clearError();
}
```

---

## 🧪 Testing

### Test Health Check on Startup

```dart
void main() async {
  // ... initialization ...
  
  // Check backend health
  final viewModel = LinkedInExtractionViewModel();
  final isHealthy = await viewModel.checkBackendHealth();
  
  if (!isHealthy) {
    print('⚠️ Backend is not available!');
  }
}
```

### Manual API Testing

```bash
# Test HTML extraction
curl -X POST http://localhost:8000/linkedin/extract/html \
  -H "Content-Type: application/json" \
  -d '{"html": "<html>...</html>"}'

# Test Image extraction
curl -X POST http://localhost:8000/linkedin/extract/image \
  -F "file=@screenshot.png"

# Test Resume analysis
curl -X POST http://localhost:8000/analyze-resume \
  -F "file=@resume.pdf" \
  -F "user_id=user123"

# Check health
curl http://localhost:8000/health
```

---

## 📋 File Structure

### Backend Files
```
backend/
├── main.py                          # FastAPI app with all endpoints
├── linkedin_extractor.py            # Core extraction logic
├── linkedin_routes.py               # LinkedIn API routes
├── resume_analyzer.py               # Resume analysis
├── matching_service.py              # User matching
└── requirements.txt                 # Dependencies
```

### Frontend Files
```
lib/
├── core/services/
│   └── linkedin_extraction_service.dart    # HTTP client
├── view_model/
│   └── linkedin_extraction_view_model.dart # State management
└── screens/
    └── linkedin_extraction_screen.dart     # UI
```

---

## 🔧 Configuration Options

### Backend

Update in `backend/linkedin_extractor.py`:

```python
# Limit extracted items
return {
    "skills": skills[:20],           # Change to limit
    "experience": experience[:10]     # Change to limit
}

# Modify skill patterns
skill_patterns = [
    "skill",
    "expertise",
    "proficiency",
    # Add more patterns
]
```

### Frontend

Update in `lib/core/services/linkedin_extraction_service.dart`:

```dart
// Change timeout
const Duration(seconds: 30)

// Change endpoints
static const String htmlExtractEndpoint = '/linkedin/extract/html';
```

---

## 🚨 Troubleshooting

### Backend won't start

```bash
# Kill existing process
taskkill /F /IM python.exe

# Check port 8000
netstat -ano | findstr :8000

# Try different port in main.py
uvicorn.run(app, host="0.0.0.0", port=8001)
```

### Connection refused

- Ensure backend is running: `python main.py`
- Check baseUrl in `linkedin_extraction_service.dart`
- Use correct IP/port (localhost:8000 for local development)

### CORS errors

CORS is enabled in main.py:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    ...
)
```

If issues persist, update with specific Flutter app URL.

### OCR not working

1. Install Tesseract:
   ```bash
   choco install tesseract  # Windows
   brew install tesseract    # Mac
   sudo apt install tesseract-ocr  # Linux
   ```

2. Configure in Python:
   ```python
   import pytesseract
   pytesseract.pytesseract.pytesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
   ```

### No skills extracted

- LinkedIn HTML structure may have changed
- Try uploading a screenshot instead (OCR fallback)
- Check browser console for actual HTML structure

---

## 📊 Data Flow

### HTML Extraction Flow
```
User pastes HTML
    ↓
LinkedInExtractionScreen (UI)
    ↓
LinkedInExtractionViewModel.extractFromHtml()
    ↓
LinkedInExtractionService.extractFromHtml(html)
    ↓
POST /linkedin/extract/html
    ↓
Python: extract_from_html()
    ↓
BeautifulSoup parses HTML
    ↓
Return skills & experience
    ↓
ViewModel updates state
    ↓
UI displays results
```

### Image Extraction Flow
```
User picks image
    ↓
LinkedInExtractionScreen (UI)
    ↓
LinkedInExtractionViewModel.extractFromImage()
    ↓
LinkedInExtractionService.extractFromImage(path)
    ↓
POST /linkedin/extract/image (multipart)
    ↓
Python: extract_from_image()
    ↓
Tesseract OCR extracts text
    ↓
extract_from_html() parses text
    ↓
Return skills & experience
    ↓
ViewModel updates state
    ↓
UI displays results
```

---

## ✅ Verification Checklist

- [ ] Backend running: `python main.py` (port 8000)
- [ ] All services starting successfully
- [ ] `/health` endpoint returns operational status
- [ ] Flutter app has LinkedInExtractionViewModel
- [ ] LinkedInExtractionScreen is integrated
- [ ] Backend URL is correct in service
- [ ] Dependencies installed: `pip install -r requirements.txt`
- [ ] Can extract from sample HTML
- [ ] Can upload and process image
- [ ] Can analyze resume file

---

## 🎓 Integration Steps

1. **✅ Backend Ready**
   - LinkedIn extractor service created
   - FastAPI endpoints configured
   - Health check endpoint added

2. **✅ Frontend Service Created**
   - Dart HTTP client implemented
   - ViewModel for state management
   - UI screen with all features

3. **📍 Next: Integrate into Your App**
   - Add ViewModel to providers
   - Add LinkedInExtractionScreen to navigation
   - Update backend URL if needed
   - Test with sample data

4. **🔗 Connect to User Profile**
   - Save extracted skills to user profile
   - Save experiences to database
   - Update profile when user confirms

---

## 📞 Support

For issues or questions:

1. Check health endpoint: `GET /health`
2. Check backend logs for errors
3. Verify file paths are correct
4. Check Flutter console for network errors
5. Try with sample data from README

---

**Last Updated**: April 2026  
**Status**: ✅ Production Ready  
**Tested With**: Flutter, FastAPI, Python 3.10+
